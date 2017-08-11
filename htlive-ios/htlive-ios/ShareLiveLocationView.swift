//
//  ShareLiveLocationView.swift
//  htlive-ios
//
//  Created by Ravi Jain on 8/2/17.
//  Copyright © 2017 PZRT. All rights reserved.
//

import UIKit
 protocol ShareLiveLocationDelegate : class {
    func didClickOnShareLiveLocation(view : ShareLiveLocationView)
}

class ShareLiveLocationView: UIView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    @IBOutlet weak var cloaseButton: UIButton!
   
    weak var shareDelegate : ShareLiveLocationDelegate? = nil
 
    @IBOutlet weak var etaLabel: UILabel!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBAction func onClose(_ sender: Any) {
        self.removeFromSuperview()
        
    }
    override func awakeFromNib() {
        self.shareLocationButton?.layer.cornerRadius =  (self.shareLocationButton?.frame.height)! / (4.0)
        self.shareLocationButton?.layer.masksToBounds = true
    }

    @IBOutlet weak var shareLocationButton: UIButton!
    
    @IBAction func onShareLocationClicked(_ sender: Any) {
        if let shareDelegate = self.shareDelegate{
            shareDelegate.didClickOnShareLiveLocation(view: self)
        }
    }
}
