//
//  CameraController.swift
//  CustomCamera
//
//  Created by Roy, Bidhan (623) on 18/08/20.
//  Copyright © 2020 Roy, Bidhan (623). All rights reserved.
//

import Foundation
import AVFoundation
import CoreImage

class CameraController: NSObject {
    
    var session : AVCaptureSession?
    
    var onComplete: ((_ result: Data)->())?
    var onScreenRender:((_ screen: CIImage) -> ())?
    
    var flashMode: Int?
    
    var cameraPosition: Int = 1 {
        didSet {
            switchCamera()
        }
    }
    
    var currentCIImage : CIImage?
    
    override init() {
        super.init()
        self.session = AVCaptureSession()
        session?.startRunning()
        session?.sessionPreset = .photo
        
        AVCaptureDevice.requestAccess(for: .video) { (authorized) in
            if !authorized {
                print("No camera permission provided")
                return
            }
        }
        addInput()
    }
    
    private func addInput() {
        do {
            guard let device = captureDevice else {
                print("No camera found")
                return
            }
            let input = try AVCaptureDeviceInput(device: device)
            session?.addInput(input)
            addStremOutput()
            setupFilter()
        } catch {
            print("Error creating input")
        }
    }
    
    func setupFilter() -> CIFilter {
        let sepiaFilter = CIFilter(name: "CISepiaTone")
        sepiaFilter?.setValue(NSNumber(value: 1), forKeyPath: "inputIntensity")
        return sepiaFilter!
    }
    
    func applyFilters(inputImage image: CIImage, withFilter: CIFilter) -> CIImage? {
        var filteredImage : CIImage?
        //apply filters
        withFilter.setValue(image, forKeyPath: kCIInputImageKey)
        filteredImage = withFilter.outputImage
        return filteredImage
    }
    
    private func addStremOutput() {
        if let videoOutput = videoOutput {
            let videoQueue = DispatchQueue(label: "videoQueue", qos: .userInteractive)
            videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            videoOutput.setSampleBufferDelegate(self, queue: videoQueue)

            if session?.canAddOutput(videoOutput) == true {
                session?.addOutput(videoOutput)
            }
            videoOutput.connections.first?.videoOrientation = .portrait

        }
    }
    
    private func switchCamera() {
        
        if let input = session?.inputs.first {
            session?.removeInput(input)
        }
        addInput()
        session?.commitConfiguration()
        
    }
    
    private func setupOutput() {
        
        if let output = output {
            if session?.canAddOutput(output) == true {
                session?.addOutput(output)
            }
            output.capturePhoto(with: setupCaptureSettings(), delegate: self)
        }
    }
    
    func capturePhoto() {
        setupOutput()
    }
    
    var captureDevice: AVCaptureDevice? {
        AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualCamera, .builtInMicrophone, .builtInTelephotoCamera, .builtInWideAngleCamera, .builtInUltraWideCamera], mediaType: .video, position: AVCaptureDevice.Position(rawValue: cameraPosition)!).devices.first
    }
    
    lazy var output: AVCapturePhotoOutput? =  {
        return AVCapturePhotoOutput()
    }()
    
    lazy var videoOutput: AVCaptureVideoDataOutput? = {
        return AVCaptureVideoDataOutput()
    }()
    
    private func setupCaptureSettings() -> AVCapturePhotoSettings {
        let settings = AVCapturePhotoSettings()
        settings.flashMode = AVCaptureDevice.FlashMode(rawValue: flashMode ?? 2) ?? .auto
        return settings
    }
    
}

extension CameraController: AVCapturePhotoCaptureDelegate {
    

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingRawPhoto rawSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        print("Preview photo")
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let photoData = photo.fileDataRepresentation() else {
            return
        }
        onComplete?(photoData)
    }
    
}

extension CameraController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let cvBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        var ciImage = CIImage(cvImageBuffer: cvBuffer)
        ciImage = applyFilters(inputImage: ciImage, withFilter: setupFilter())!
        self.currentCIImage = ciImage
        onScreenRender?(self.currentCIImage!)
        print("capturing")
        
    }
    
}
