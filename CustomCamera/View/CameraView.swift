//
//  CameraView.swift
//  CustomCamera
//
//  Created by Roy, Bidhan (623) on 18/08/20.
//  Copyright © 2020 Roy, Bidhan (623). All rights reserved.
//

import UIKit
import AVFoundation
import MetalKit

class CameraView: MTKView {
    
    var metalDevice: MTLDevice!
    var metalCommandQueue : MTLCommandQueue!
    var ciContext : CIContext!
    
    init(frame: CGRect, session: AVCaptureSession) {
               metalDevice = MTLCreateSystemDefaultDevice()
               super.init(frame: frame, device: metalDevice)
               self.backgroundColor = .red
               self.translatesAutoresizingMaskIntoConstraints = false
               self.device = metalDevice
               self.isPaused = true
               self.enableSetNeedsDisplay = false
               self.framebufferOnly = false
               ciContext = CIContext(mtlDevice: metalDevice)
               metalCommandQueue = metalDevice.makeCommandQueue()
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
    }
    
}
