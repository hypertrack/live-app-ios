//
//  ActivityIndicatorView.swift
//  LiveApp
//
//  Created by Dmytro Shapovalov on 7/4/19.
//  Copyright © 2019 Dmytro Shapovalov. All rights reserved.
//

import UIKit
import Lottie

class HTActivityIndicatorView: UIView {
    enum ViewTag : Int {
        case activityIndicatorTag = 33
    }
    
    let activityIndicator = AnimationView(name: "loading")
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupDefaultStyle()
        tag = ViewTag.activityIndicatorTag.rawValue
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        isHidden = true
        tag = ViewTag.activityIndicatorTag.rawValue
        setupDefaultStyle()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupDefaultStyle()
        tag = ViewTag.activityIndicatorTag.rawValue
    }
    
    func setupDefaultStyle() {
        self.translatesAutoresizingMaskIntoConstraints = false
        setupDarkBackgrdoun()
        setupActivityIndicator()
        setActivityIndicatorPositionOnView()
    }
    
    func setupDarkBackgrdoun() {
        backgroundColor = UIColor("#000000", 0.4)
    }
    
    func setupActivityIndicator() {
        activityIndicator.loopMode = .loop
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
    }
    
    func setActivityIndicatorPositionOnView() {
        layoutIfNeeded()
        activityIndicator.center = center
        addSubview(activityIndicator)
    }
    
    class func startAnimatingOnView() {
        let window = UIApplication.shared.keyWindow!
        window.endEditing(true)
        let activityIndicatorView = HTActivityIndicatorView.init(frame: window.frame)
        window.addSubview(activityIndicatorView)
        activityIndicatorView.startAnimating()
    }
    
    class func stopAnimationOnView() {
        
        let window = UIApplication.shared.keyWindow!
        
        if window.viewWithTag(ViewTag.activityIndicatorTag.rawValue) is HTActivityIndicatorView {
            let aiView = window.viewWithTag(ViewTag.activityIndicatorTag.rawValue) as! HTActivityIndicatorView
            aiView.stopAnimating()
        }
    }
    
    func startAnimating() {

        self.alpha = 0;
        self.isHidden = false

        UIView.animate(withDuration: 0.25, animations: {
            self.alpha = 1
        }) { (finished) in
            self.activityIndicator.play()
        }
    }

    func stopAnimating() {
        activityIndicator.stop()

        UIView.animate(withDuration: 0.25, animations: {
            self.alpha = 0
        }) { (finished) in
            if self.tag == 33 {
                self.removeFromSuperview()
            } else {
                self.isHidden = true
            }
        }
    }
}
