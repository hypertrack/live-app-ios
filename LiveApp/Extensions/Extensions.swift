//
//  Extensions.swift
//  LiveApp
//
//  Created by Dmytro Shapovalov on 6/26/19.
//  Copyright © 2019 Dmytro Shapovalov. All rights reserved.
//

import UIKit

extension String {
    public static func localize(key: String) -> String {
        return NSLocalizedString(key, comment: "")
    }
}

extension UIColor {
    convenience init(_ hexString: String, _ alpha: CGFloat = 1.0) {
        var cString:String = hexString.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        var rgbValue:UInt32 = 10066329 //color #999999 if string has wrong format
        
        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }
        
        if ((cString.count) == 6) {
            Scanner(string: cString).scanHexInt32(&rgbValue)
        }
        
        self.init(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: alpha
        )
    }
}

extension UIButton {
    static var baseGreen: UIButton {
        let button = UIButton(type:.custom)
        button.clipsToBounds = true
        button.layer.cornerRadius = 5
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setBackgroundColor(
            UIColor("#00CE5B"),
            for: .normal)
        button.setBackgroundColor(
            UIColor("#00CE5B"),
            for: .highlighted)
        button.setBackgroundColor(
            UIColor("#C9C9C9"),
            for: .disabled)
        return button
    }
    
    func setBackgroundColor(_ color: UIColor, for controlState: UIControl.State) {
        let colorImage = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1)).image { _ in
            color.setFill()
            UIBezierPath(rect: CGRect(x: 0, y: 0, width: 1, height: 1)).fill()
        }
        setBackgroundImage(colorImage, for: controlState)
    }
}

extension UITextView {
    static var baseTextView: UITextView {
        let textView = UITextView()
        textView.font = UIFont.systemFont(
            ofSize: 14,
            weight: UIFont.Weight.medium)
        textView.layer.cornerRadius = 5
        textView.backgroundColor = UIColor("#F5F5F5")
        textView.tintColor = .black
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.enablesReturnKeyAutomatically = true
        textView.autocorrectionType = .no
        textView.keyboardType = UIKeyboardType.emailAddress
        textView.returnKeyType = UIReturnKeyType.continue
        return textView
    }
}

extension UILabel {
    static var baseLabel: UILabel {
        let label = UILabel()
        label.font = UIFont.systemFont(
            ofSize: 14,
            weight: UIFont.Weight.medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
    static var titleLabel: UILabel {
        let label = UILabel.baseLabel
        label.numberOfLines = 2
        label.textAlignment = .center
        label.font = UIFont.systemFont(
            ofSize: 22,
            weight: UIFont.Weight.bold)
        return label
    }
    static var subTitleLabel: UILabel {
        let label = UILabel.baseLabel
        label.font = UIFont.systemFont(
            ofSize: 12,
            weight: UIFont.Weight.medium)
        label.textColor = UIColor("#AEAEAE")
        label.numberOfLines = 2
        return label
    }
    static var tipsLabel: UILabel {
        let label = UILabel.baseLabel
        label.textColor = UIColor("#00CE5B")
        label.numberOfLines = 0
        return label
    }
}

extension UIImageView {
    static var baseImageView: UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
        
    }
}

extension UIView {
    
    func takeScreenshot() -> UIImage {
        
        // Begin context
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, UIScreen.main.scale)
        
        // Draw view in that context
        drawHierarchy(in: self.bounds, afterScreenUpdates: true)
        
        // And finally, get image
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if (image != nil)
        {
            return image!
        }
        return UIImage()
    }
}
