//
//  NSGLVideoView.swift
//  CIImagePreviewDemo
//
//  Created by 黄文希 on 2018/7/12.
//  Copyright © 2018 Hays. All rights reserved.
//

import Cocoa
import OpenGL.GL3
import OpenGL.GL

class NSGLVideoView: NSOpenGLView {
    var displayLink: CVDisplayLink?
    var needReshape = true
    var image: CIImage?
    var ciContext: CIContext?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    override init?(frame frameRect: NSRect, pixelFormat format: NSOpenGLPixelFormat?) {
        super.init(frame: frameRect, pixelFormat: format)
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }
    
    deinit {
        teardownDisplayLink()
    }
    
    func setup() {
        
        self.wantsLayer = true
        self.wantsBestResolutionOpenGLSurface = true
        let attrs: [NSOpenGLPixelFormatAttribute] = [
            UInt32(NSOpenGLPFAAccelerated),
            UInt32(NSOpenGLPFANoRecovery),
            UInt32(NSOpenGLPFAAllowOfflineRenderers),
            UInt32(NSOpenGLPFAColorSize), 32,
            UInt32(NSOpenGLPFADoubleBuffer),    // 可选地，可以使用双缓冲
            0
        ]
        
        let pf  = NSOpenGLPixelFormat(attributes: attrs)
        let context = NSOpenGLContext(format: pf!, share: nil)
        pixelFormat = pf
        openGLContext = context
        
        
    }
    
    override func reshape() {
        super.reshape()
        needReshape = true
    }
    
    override func draw(_ dirtyRect: NSRect) {
        drawFrame()
    }
    
    override func prepareOpenGL() {
        super.prepareOpenGL()
        openGLContext?.makeCurrentContext()
        glDisable(GLenum(GL_ALPHA_TEST))
        glDisable(GLenum(GL_DEPTH_TEST))
        glDisable(GLenum(GL_SCISSOR_TEST))
        glDisable(GLenum(GL_BLEND))
        glDisable(GLenum(GL_CULL_FACE))
        glColorMask(GLboolean(GL_TRUE), GLboolean(GL_TRUE), GLboolean(GL_TRUE), GLboolean(GL_TRUE))
        glDepthMask(GLboolean(GL_FALSE))
        glStencilMask(0)
        glClearColor(0.0, 0.0, 0.0, 0.0)
        glHint(GLenum(GL_TRANSFORM_HINT_APPLE), GLenum(GL_FASTEST))
        
        glDisable(GLenum(GL_DITHER))
        ciContext = CIContext(cglContext: CGLGetCurrentContext()!, pixelFormat: pixelFormat?.cglPixelFormatObj, colorSpace: nil, options: nil)
        setupDisplayLink()
    }
    
    func setupDisplayLink() {
        guard displayLink == nil else { return }
        
        var swapInt:GLint = 1
        openGLContext?.setValues(&swapInt, for: NSOpenGLContext.Parameter.swapInterval)
        
        let displayLinkOutputCallback: CVDisplayLinkOutputCallback = {(displayLink: CVDisplayLink, inNow: UnsafePointer<CVTimeStamp>, inOutputTime: UnsafePointer<CVTimeStamp>, flagsIn: CVOptionFlags, flagsOut: UnsafeMutablePointer<CVOptionFlags>, displayLinkContext: UnsafeMutableRawPointer?) -> CVReturn in
            
            let view = unsafeBitCast(displayLinkContext, to: NSGLVideoView.self)
            view.drawFrame()
            
            return kCVReturnSuccess
        }
        
        CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)
        let ret = CVDisplayLinkSetOutputCallback(displayLink!, displayLinkOutputCallback, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))
        print("ret = \(ret)")
        CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(displayLink!, (openGLContext?.cglContextObj)!, (pixelFormat?.cglPixelFormatObj)!)
        CVDisplayLinkStart(displayLink!)
    }
    
    func teardownDisplayLink() {
        if let link = displayLink {
            CVDisplayLinkStop(link)
            displayLink = nil
        }
    }
    
    func updateMatrices() {
        let mappedVisiableRect = NSIntegralRect(convert(visibleRect, to: enclosingScrollView))
        openGLContext?.update()
        
        glViewport(0, 0, GLsizei(mappedVisiableRect.size.width), GLsizei(mappedVisiableRect.size.height));
        glMatrixMode(GLenum(GL_PROJECTION))
        glLoadIdentity()
        glOrtho(GLdouble(visibleRect.origin.x),
                GLdouble(visibleRect.origin.x + visibleRect.size.width),
                GLdouble(visibleRect.origin.y),
                GLdouble(visibleRect.origin.y + visibleRect.size.height),
                -1, 1)
        
        glMatrixMode(GLenum(GL_MODELVIEW));
        glLoadIdentity();
        needReshape = false
    }
    
    func drawFrame() {
        let frame = bounds
        openGLContext?.makeCurrentContext()
        openGLContext?.lock()
        if needReshape {
            updateMatrices()
            glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
        }
        
        if let img = image {
            let imageRect = img.extent
            let destRect = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
            ciContext?.draw(img, in: destRect, from: imageRect)
            openGLContext?.flushBuffer()
        }
        
        openGLContext?.unlock()
    }
}
