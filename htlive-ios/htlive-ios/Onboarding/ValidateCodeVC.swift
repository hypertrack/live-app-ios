//
//  ValidateCodeVC.swift
//  htlive-ios
//
//  Created by Arjun Attam on 17/07/17.
//  Copyright © 2017 PZRT. All rights reserved.
//

import Foundation
import HyperTrack

class ValidateCodeVC: UIViewController {
    
    let requestService = RequestService.shared
    var onboardingViewDelegate:OnboardingViewDelegate? = nil
    
    @IBOutlet weak var verificationCode: UITextField!
    
    @IBAction func verifyCode(_ sender: Any) {
        
        if let code = verificationCode.text {
            requestService.validateHyperTrackCode(code: code, completionHandler: { (error) in
                if (error != nil) {
                    // Handle error in sending verification code
                    // The verification code was incorrect, and the
                    // user will need to input the correct verification
                    // code.
                } else {
                    // Verification code was validated.
                    // Move to the home/placeline screen
                    self.onboardingViewDelegate?.didValidateCode()
                }
            })
        } else {
            // User did not input any verification code
            
        }
    }
    
    @IBAction func resendCode(_ sender: Any) {
        // TODO: wait for some time before this can be enabled?

        requestService.resendHyperTrackCode { (error) in
            if (error != nil) {
                // Handle error in sending verification code
            } else {
                // Verification code was sent successfully
                // Wait for user to input the code.
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        verificationCode.becomeFirstResponder()
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
