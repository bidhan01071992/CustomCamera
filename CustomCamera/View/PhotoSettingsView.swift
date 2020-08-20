//
//  PhotoSettingsView.swift
//  CustomCamera
//
//  Created by Roy, Bidhan (623) on 18/08/20.
//  Copyright © 2020 Roy, Bidhan (623). All rights reserved.
//

import UIKit

protocol FlashProtocol {
    func flashSelection(with option: Int)
}

class PhotoSettingsView: UIView {

    @IBOutlet weak var onButton: UIButton!
    @IBOutlet weak var offButton: UIButton!
    @IBOutlet weak var autoButton: UIButton!
    var delegate: FlashProtocol?

    @IBAction func flashSelectionOption(_ sender: Any) {
        if let button = sender as? UIButton {
            delegate?.flashSelection(with: button.tag)
            self.removeFromSuperview()
        }
    }
    
}
