//
//  LiveLocationAlertView.swift
//  htlive-ios
//
//  Created by Ravi Jain on 8/3/17.
//  Copyright © 2017 PZRT. All rights reserved.
//

import UIKit

class LiveLocationAlertView: UIView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    @IBOutlet weak var actionButton: UIButton!
    
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var mainLabel: UILabel!
    
    @IBAction func onActionPressed(_ sender: Any) {
    
    }
    
    @IBAction func close(_ sender: Any) {
        self.removeFromSuperview()
    }
    
    override func awakeFromNib() {
        self.actionButton?.layer.cornerRadius =  (self.actionButton?.frame.height)! / (2.0)
        self.actionButton?.layer.masksToBounds = true
    }

}
