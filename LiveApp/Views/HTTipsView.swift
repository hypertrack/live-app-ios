//
//  HTTipsView.swift
//  LiveApp
//
//  Created by Dmytro Shapovalov on 7/8/19.
//  Copyright © 2019 Dmytro Shapovalov. All rights reserved.
//

import UIKit

class HTTipsView: UIView {

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(
            ofSize: 14,
            weight: UIFont.Weight.medium)
        label.textColor = .white
        label.text = String.localize(key: "TIPS_MESSAGE")
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpNotificationView()
        self.layer.cornerRadius = 5
        self.backgroundColor = .clear
        self.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setUpNotificationView() {
        self.addSubview(titleLabel)
        
        titleLabel.topAnchor.constraint(
            equalTo:self.topAnchor,
            constant: 11).isActive = true
        titleLabel.leftAnchor.constraint(
            equalTo:self.leftAnchor,
            constant: 8).isActive = true
        titleLabel.rightAnchor.constraint(
            equalTo:self.rightAnchor,
            constant: -17).isActive = true
        titleLabel.bottomAnchor.constraint(
            equalTo:self.bottomAnchor,
            constant: -11).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        //// Color Declarations
        let fillColor = UIColor(red: 0.200, green: 0.569, blue: 1.000, alpha: 1.000)
        let rectanglePath = UIBezierPath()
        rectanglePath.move(to: CGPoint(x: 5.34, y: 0))
        rectanglePath.addLine(to: CGPoint(x: 155.84, y: 0))
        rectanglePath.addCurve(to: CGPoint(x: 161.18, y: 4.88), controlPoint1: CGPoint(x: 158.79, y: -0), controlPoint2: CGPoint(x: 161.18, y: 2.18))
        rectanglePath.addLine(to: CGPoint(x: 161.18, y: 12.54))
        rectanglePath.addCurve(to: CGPoint(x: 162.23, y: 14.22), controlPoint1: CGPoint(x: 161.18, y: 13.23), controlPoint2: CGPoint(x: 161.58, y: 13.87))
        rectanglePath.addLine(to: CGPoint(x: 172, y: 19.5))
        rectanglePath.addLine(to: CGPoint(x: 162.23, y: 24.78))
        rectanglePath.addCurve(to: CGPoint(x: 161.18, y: 26.46), controlPoint1: CGPoint(x: 161.58, y: 25.13), controlPoint2: CGPoint(x: 161.18, y: 25.77))
        rectanglePath.addLine(to: CGPoint(x: 161.18, y: 34.12))
        rectanglePath.addCurve(to: CGPoint(x: 155.84, y: 39), controlPoint1: CGPoint(x: 161.18, y: 36.82), controlPoint2: CGPoint(x: 158.79, y: 39))
        rectanglePath.addLine(to: CGPoint(x: 5.34, y: 39))
        rectanglePath.addCurve(to: CGPoint(x: -0, y: 34.12), controlPoint1: CGPoint(x: 2.39, y: 39), controlPoint2: CGPoint(x: -0, y: 36.82))
        rectanglePath.addLine(to: CGPoint(x: -0, y: 4.88))
        rectanglePath.addCurve(to: CGPoint(x: 5.34, y: 0), controlPoint1: CGPoint(x: -0, y: 2.18), controlPoint2: CGPoint(x: 2.39, y: 0))
        rectanglePath.close()
        rectanglePath.usesEvenOddFillRule = true
        fillColor.setFill()
        rectanglePath.fill()
    }
    
    func showTipsView() {
        
        self.alpha = 0;
        self.isHidden = false
        
        UIView.animate(withDuration: 0.25, animations: {
            self.alpha = 1
        }) { (finished) in
        }
    }
    
    func hideTipsView() {
        
        UIView.animate(withDuration: 0.25, animations: {
            self.alpha = 0
        }) { (finished) in
            self.isHidden = true
        }
    }
}
