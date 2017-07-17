//
//  ValidateCodeVC.swift
//  htlive-ios
//
//  Created by Arjun Attam on 17/07/17.
//  Copyright © 2017 PZRT. All rights reserved.
//

import Foundation

class ValidateCodeVC: UIViewController {
    
    @IBOutlet weak var verificationCode: UITextField!
    
    @IBAction func verifyCode(_ sender: Any) {
    }
    
    @IBAction func resendCode(_ sender: Any) {
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
