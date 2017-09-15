//
//  UIViewExtension.swift
//  HyperTrack
//
//  Created by Vibes on 5/19/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import Foundation
import UIKit

let htBlack = UIColor(red:0.40, green:0.39, blue:0.49, alpha:1.0)
let pink = UIColor(red:1.00, green:0.51, blue:0.87, alpha:1.0)
let grey = UIColor(red:0.96, green:0.96, blue:0.96, alpha:1.0)
let htblack = UIColor(red:0.40, green:0.39, blue:0.49, alpha:1.0)
let purple = UIColor(red:136.0/255.0, green:90.0/255.0, blue:231.0/255.0, alpha:1.0)

extension UIView {
  
  @IBInspectable var cornerRadius: CGFloat {
    get {
      return layer.cornerRadius
    }
    set {
      layer.cornerRadius = newValue
      layer.masksToBounds = newValue > 0
    }
  }
  
  @IBInspectable var borderWidth: CGFloat {
    get {
      return layer.borderWidth
    }
    set {
      layer.borderWidth = newValue
    }
  }
  
  @IBInspectable var htBorderColor: UIColor? {
    get {
      return UIColor(cgColor: layer.borderColor!)
    }
    set {
      layer.borderColor = newValue?.cgColor
    }
  }
  
  @IBInspectable var shadowColor: UIColor? {
    get {
      return UIColor(cgColor: layer.shadowColor!)
    }
    set {
      layer.shadowColor = newValue?.cgColor
    }
  }
  
  func shadow() {
    
    self.layer.masksToBounds = false
    self.layer.shadowColor = UIColor.black.cgColor
    self.layer.shadowOpacity = 0.2
    self.layer.shadowOffset = CGSize(width: 0, height: 0)
    self.layer.shadowRadius = 0.02 * frame.width
    
    
    self.layer.shadowPath = UIBezierPath(rect: self.bounds).cgPath
    self.layer.shouldRasterize = false
  
  }

}
