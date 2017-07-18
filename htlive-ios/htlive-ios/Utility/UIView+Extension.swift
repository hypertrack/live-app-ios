//
//  UIView+Extension.swift
//  Meta-iPhone
//
//  Created by Ulhas Mandrawadkar on 14/11/15.
//  Copyright © 2015 HyperTrack, Inc. All rights reserved.
//

import Foundation
import UIKit
import MBProgressHUD

extension UIView {
    
    func showActivityIndicator(animated: Bool = true) {
        MBProgressHUD.showAdded(to: self, animated: animated)
    }
    
    func hideActivityIndicator(animate animated: Bool = true) {
        MBProgressHUD.hide(for: self, animated: animated)
    }
}

extension UIView {
    
    func mt_transformCircular(borderColor: UIColor?, borderWidth: CGFloat = 0.1) {
        
        self.layer.cornerRadius = (self.bounds.size.width / 2)
        
        if let borderColor = borderColor {
            self.layer.borderWidth = borderWidth
            self.layer.borderColor = borderColor.cgColor
        }
    }
    
    var imageFromView: UIImage {
        
        UIGraphicsBeginImageContext(frame.size)
        
        layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return image!
    }
}

extension UIView {
    
    func applyBorderTheme() {
        self.layer.borderColor = UIColor.darkBackgroundColor.cgColor
        self.layer.borderWidth = 0.1
        self.layer.cornerRadius = 5
    }
}

extension UIImage {
    
    var data: NSData? {
        return UIImageJPEGRepresentation(self, 0.3) as NSData?
    }
}

extension UITextField {
    func applyPadding() {
        let paddingViewLeft = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: 50))
        self.leftView = paddingViewLeft
        self.leftViewMode = .always
    }
}
