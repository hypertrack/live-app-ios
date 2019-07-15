//
//  HTButton.swift
//  LiveApp
//
//  Created by Dmytro Shapovalov on 6/28/19.
//  Copyright © 2019 Dmytro Shapovalov. All rights reserved.
//

import UIKit

enum ButtonState {
    case on
    case off
}

class HTButton: UIButton {

    private var backgroundImageONForStateHighlighted: UIImage?
    private var backgroundImageONForStateNormal: UIImage?
    private var backgroundImageONForStateDisable: UIImage?
    
    private var backgroundImageOFFForStateHighlighted: UIImage?
    private var backgroundImageOFFForStateNormal: UIImage?
    private var backgroundImageOFFForStateDisable: UIImage?
    
    var currentState: ButtonState = .off {
        didSet {
            changeBackgroundImage()
        }
    }
    
    func setOnStateImage(normalImage: UIImage?,
                         highlightedImage: UIImage?,
                         disableImage: UIImage?) {
        backgroundImageONForStateHighlighted = highlightedImage
        backgroundImageONForStateNormal = normalImage
        backgroundImageONForStateDisable = disableImage
    }
    
    func setOffStateImage(normalImage: UIImage?,
                          highlightedImage: UIImage?,
                          disableImage: UIImage?) {
        backgroundImageOFFForStateHighlighted = highlightedImage
        backgroundImageOFFForStateNormal = normalImage
        backgroundImageOFFForStateDisable = disableImage
    }
    
    private func changeBackgroundImage() {
        switch currentState {
        case .on:
            self.setBackgroundImage(
                backgroundImageONForStateNormal,
                for: .normal)
            self.setBackgroundImage(
                backgroundImageONForStateHighlighted,
                for: .highlighted)
            self.setBackgroundImage(
                backgroundImageONForStateDisable,
                for: .disabled)
        case .off:
            self.setBackgroundImage(
                backgroundImageOFFForStateNormal,
                for: .normal)
            self.setBackgroundImage(
                backgroundImageOFFForStateHighlighted,
                for: .highlighted)
            self.setBackgroundImage(
                backgroundImageOFFForStateDisable,
                for: .disabled)
        }
    }
    
    override func draw(_ rect: CGRect) {
        drawShadow()
    }
    
    func drawShadow() {
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 5)
        self.layer.shadowOpacity = 0.2
        self.layer.shadowRadius = 3
        self.layer.masksToBounds = false
    }
    
    func hide(_ animated: Bool) {
        self.tag = 0
        if animated {
            createAnimation(true)
        } else {
            self.alpha = 0
        }
    }
    
    func show(_ animated: Bool) {
        self.tag = 1
        if animated {
            createAnimation(false)
        } else {
            self.alpha = 1
        }
    }
    
    private func createAnimation(_ isHidde: Bool) {
        UIView.animate(withDuration: 0.3) {
            self.alpha = isHidde ? 0 : 1
        }
    }
}
