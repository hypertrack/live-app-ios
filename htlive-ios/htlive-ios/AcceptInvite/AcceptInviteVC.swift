//
//  AcceptInviteVC.swift
//  htlive-ios
//
//  Created by Piyush on 17/07/17.
//  Copyright © 2017 PZRT. All rights reserved.
//

import Foundation

class AcceptInviteVC : UIViewController {
    
    public var accountName:String?
    @IBOutlet weak var accountNameLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didTapAcceptInviteButton(_ sender: Any) {
    }
    
    
    @IBAction func didTapSkipInviteButton(_ sender: Any) {
    }
}
