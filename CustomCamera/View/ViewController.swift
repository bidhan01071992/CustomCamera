//
//  ViewController.swift
//  CustomCamera
//
//  Created by Roy, Bidhan (623) on 17/08/20.
//  Copyright © 2020 Roy, Bidhan (623). All rights reserved.
//

import UIKit
import CoreGraphics
import MetalKit

class ViewController: UIViewController {

    @IBOutlet weak var photoSettingsContainerView: UIView!
    
    @IBOutlet weak var buttonContainer: UIView!
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var pickContainerView: UIView!
    var cameraModePicker: UIPickerView!
    @IBOutlet weak var cameraContainerView: UIView!
    @IBOutlet weak var flashButton: UIButton!
    
    var controller: CameraController?
    var cameraView: CameraView!
    var rotationAngle: CGFloat!
    
    let captureModesList: [String] = ["time-lapse","slo-mo","video","photo", "portrait","square","pano"]
    var currentScreen: CIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        rotationAngle =  -90  * (.pi/180)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setupUI()
        setupHorizontalPicker()
        DispatchQueue.global(qos: .default).async {
            self.controller = CameraController()
            
            self.controller?.onComplete = { result in
                let photoImage = UIImage(data: result)
                print(photoImage as Any)
            }
            
            DispatchQueue.main.async { [weak self] in
                guard let cameraBounds = self?.cameraContainerView?.bounds, let session = self?.controller?.session else {
                    return
                }
                let cameraPreview = CameraView(frame: cameraBounds, session: session)
                cameraPreview.delegate = self
                self?.cameraView = cameraPreview
                self!.cameraContainerView.addSubview(self!.cameraView)
                self?.controller?.onScreenRender = { screen in
                    self?.currentScreen = screen
                    cameraPreview.draw()
                }
            }
        }
    }
    
    private func setupHorizontalPicker() {
        cameraModePicker = UIPickerView()
        cameraModePicker.dataSource = self
        cameraModePicker.delegate = self
        
        cameraModePicker.transform = CGAffineTransform(rotationAngle: rotationAngle)
        cameraModePicker.frame = CGRect(x: -150, y: pickContainerView.frame.origin.y, width: self.view.frame.width + 300, height: pickContainerView.frame.size.height)
        
        self.view.addSubview(cameraModePicker)
    }
    
    private func setupUI() {
        captureButton.layer.cornerRadius = captureButton.frame.width / 2.0
        buttonContainer.center = captureButton.center
        buttonContainer.layer.borderWidth = 5.0
        buttonContainer.layer.borderColor = UIColor.white.cgColor
        buttonContainer.layer.cornerRadius = buttonContainer.frame.width / 2.0
        
        self.view.bringSubviewToFront(captureButton)
    }
    
    @IBAction func switchCameraAction(_ sender: Any) {
        cameraView.flip(animationOptions: .transitionFlipFromLeft)
        self.cameraView.addBlur()
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
            self.controller?.cameraPosition = self.controller?.cameraPosition == 2 ? 1 : 2
            self.cameraView.removeBlur()
        }
    }
    
    @IBAction func flashToggleAction(_ sender: UIButton) {
        
        if let photoSettingsView = Bundle.main.loadNibNamed("PhotoSettingsView", owner: self, options: nil)?.first as? PhotoSettingsView {
            photoSettingsView.delegate = self
            photoSettingsContainerView.isHidden = false
            
            let containerFrame = photoSettingsContainerView.bounds
            
            self.photoSettingsContainerView.addSubview(photoSettingsView)
            self.flashButton.isHidden = true
            photoSettingsView.frame = CGRect(x: containerFrame.width, y: 0, width: containerFrame.width, height: containerFrame.height)
            
            UIView.animate(withDuration: 0.5) {
                photoSettingsView.frame = CGRect(x: 0, y: 0, width: containerFrame.width, height: containerFrame.height)
            }
        }
        
    }
    
    @IBAction func capturePhotoAction(_ sender: Any) {
        controller?.capturePhoto()
    }
    
    @IBAction func filterAction(_ sender: Any) {
        
    }
    
}

extension ViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return captureModesList.count
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let modeView = UIView()
        modeView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        //modeView.backgroundColor = .green
        
        let modeLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        modeLabel.textColor = .yellow
        modeLabel.text = captureModesList[row]
        modeLabel.textAlignment = .center
        modeView.addSubview(modeLabel)
        modeView.transform = CGAffineTransform(rotationAngle: 90 * (.pi/180))
        
        return modeView
        
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 100
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        print(captureModesList[row])
    }
    
}

extension ViewController: FlashProtocol {
    
    func flashSelection(with option: Int) {
        controller?.flashMode = option
        photoSettingsContainerView.isHidden = true
        flashButton.isHidden = false
    }
}

extension ViewController: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
        guard let commandBuffer = cameraView.metalCommandQueue.makeCommandBuffer() else { return }
        //make sure we actually have a ciImage to work with
        guard let ciImage = currentScreen else { return }
        //make sure the current drawable object for this metal view is available (it's not in use by the previous draw cycle)
        guard let currentDrawable = view.currentDrawable else { return }
        let heightOfciImage = ciImage.extent.height
        let heightOfDrawable = view.drawableSize.height
        let yOffsetFromBottom = (heightOfDrawable - heightOfciImage)/2
        
        //render into the metal texture
        cameraView.ciContext.render(ciImage,
                              to: currentDrawable.texture,
                   commandBuffer: commandBuffer,
                          bounds: CGRect(origin: CGPoint(x: 0, y: -yOffsetFromBottom), size: view.drawableSize),
                      colorSpace: CGColorSpaceCreateDeviceRGB())
        
        //register where to draw the instructions in the command buffer once it executes
        commandBuffer.present(currentDrawable)
        //commit the command to the queue so it executes
        commandBuffer.commit()
    }
    
    
}

extension UIView {
    func flip(animationOptions: AnimationOptions) {
        UIView.transition(with: self, duration: 0.8, options: animationOptions, animations: nil, completion: nil)
    }

    func addBlur() {
        let blurEffect = UIBlurEffect(style: .light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = self.bounds
        blurEffectView.alpha = 1.0
        self.addSubview(blurEffectView)
    }
    
    func removeBlur() {
        for subview in self.subviews {
            if subview is UIVisualEffectView {
                subview.removeFromSuperview()
            }
        }
    }
}






