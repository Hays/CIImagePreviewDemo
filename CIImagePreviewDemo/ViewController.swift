//
//  ViewController.swift
//  CIImagePreviewDemo
//
//  Created by 黄文希 on 2018/7/12.
//  Copyright © 2018 Hays. All rights reserved.
//

import Cocoa
import AVFoundation

class ViewController: NSViewController {
    
    let session = AVCaptureSession()
    var render: NSGLVideoView?


    override func viewDidLoad() {
        super.viewDidLoad()
        render = NSGLVideoView(frame: view.bounds)
        view.addSubview(render!)
        if let videoDevice = AVCaptureDevice.default(for: AVMediaType.video) {
            session.beginConfiguration()
            let videoInput = try? AVCaptureDeviceInput.init(device: videoDevice)
            if videoDevice.supportsSessionPreset(session.sessionPreset) {
                session.sessionPreset = AVCaptureSession.Preset.high
            }
            session.addInput(videoInput!)
            session.commitConfiguration()
        }
        
        let captureOutput = AVCaptureVideoDataOutput()
        let key = kCVPixelBufferPixelFormatTypeKey as String
        let setting = [key: NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
        captureOutput.videoSettings = setting
        if session.canAddOutput(captureOutput) {
            session.addOutput(captureOutput)
        }
        
        captureOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global())
        
        session.startRunning()
    }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if let videoFrame = CMSampleBufferGetImageBuffer(sampleBuffer) {
            let image = CIImage(cvImageBuffer: videoFrame)
            render?.image = image
        }
    }
}

