//
//  ValidateCodeVC.swift
//  htlive-ios
//
//  Created by Arjun Attam on 17/07/17.
//  Copyright © 2017 PZRT. All rights reserved.
//

import Foundation
import HyperTrack
import MBProgressHUD

class ValidateCodeVC: UIViewController {
    
    let requestService = RequestService.shared
    var onboardingViewDelegate:OnboardingViewDelegate? = nil
    var resendCounter = 30
    var resendTimer: Timer? = nil
    
    @IBOutlet weak var verificationCode: UITextField!
    @IBOutlet weak var resendButton: UIButton!
    
    @IBAction func verifyCode(_ sender: Any) {
        
        if let code = verificationCode.text {
            showActivityIndicator()

            requestService.validateHyperTrackCode(code: code, completionHandler: { (error) in
                self.hideActivityIndicator()
                
                if (error != nil) {
                    // Handle error in sending verification code
                    // The verification code was incorrect, and the
                    // user will need to input the correct verification
                    // code.
                    self.alertError(msg: error!)
                } else {
                    // Verification code was validated.
                    // Move to the home/placeline screen
                    self.onboardingViewDelegate?.didValidateCode(currentController: self)
                }
            })
        } else {
            // User did not input any verification code
            
        }
    }
    
    @IBAction func resendCode(_ sender: Any) {
        requestService.sendHyperTrackCode { (error) in
            if (error != nil) {
                // Handle error in sending verification code
                self.alertError(msg: error!)
            } else {
                // Verification code was sent successfully
                // Wait for user to input the code.
                self.disableResend()
            }
        }
    }
    
    func alertError(msg: String) {
        let alert = UIAlertController(title: "Error", message: msg, preferredStyle: .alert)
        let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(defaultAction)
        self.present(alert, animated: true, completion: nil)
    }

    func enableResend() {
        self.resendButton.isEnabled = true
        self.resendButton.alpha = 1.0
        self.resendButton.setTitle("Resend text", for: .normal)
    }
    
    func disableResend() {
        self.resendButton.setTitle("Resend text in 0:\(resendCounter)", for: .normal)
        self.resendButton.isEnabled = false
        self.resendButton.alpha = 0.7
        resendTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateResendLabel), userInfo: nil, repeats: true)
    }
    
    func updateResendLabel() {
        if (resendCounter <= 1) {
            // Invalidate the timer
            if let timer = resendTimer {
                timer.invalidate()
            }
            
            enableResend()
            resendCounter = 30
            return
        }
        
        resendCounter -= 1

        UIView.performWithoutAnimation {
            var title = "Resend text in 0:\(resendCounter)"
            
            if (resendCounter < 10) {
                title = "Resend text in 0:0\(resendCounter)"
            }
            
            self.resendButton.setTitle(title, for: .normal)
            self.resendButton.layoutIfNeeded()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        verificationCode.becomeFirstResponder()
        verificationCode.keyboardType = .numberPad
        // Do any additional setup after loading the view.
        disableResend()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func showActivityIndicator(animated: Bool = true) {
        MBProgressHUD.showAdded(to: self.view, animated: animated)
    }
    
    func hideActivityIndicator(animate animated: Bool = true) {
        MBProgressHUD.hide(for: self.view, animated: animated)
    }
}
