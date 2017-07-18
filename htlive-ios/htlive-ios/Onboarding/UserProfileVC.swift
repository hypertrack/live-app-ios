//
//  UserProfileVC.swift
//  htlive-ios
//
//  Created by Piyush on 17/07/17.
//  Copyright © 2017 PZRT. All rights reserved.
//

import Foundation
import HyperTrack
import PhoneNumberKit
import MBProgressHUD

class UserProfileVC: UIViewController, UITextFieldDelegate {
    
    var onboardingViewDelegate:OnboardingViewDelegate? = nil
    let phoneNumberKit = PhoneNumberKit()
    
    @IBOutlet weak var nameTextField: CustomTextField!
    @IBOutlet weak var phoneNumberTextField: CustomPhoneTextField!
    
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!

    @IBAction func saveProfile(_ sender: Any) {
        getOrCreateHyperTrackUser()
    }

    @IBAction func skipProfile(_ sender: Any) {
        // TODO: On skip profile, a user is created with empty
        // name and phone number. Should we use the device id
        // in this case?
        getOrCreateHyperTrackUser()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        phoneNumberTextField.delegate = self
        nameTextField.delegate = self
        // Do any additional setup after loading the view.
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow(notification:)),
                                               name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide(notification:)),
                                               name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self,
                                                                 action: #selector(UserProfileVC.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    func dismissKeyboard() {
        // Dismiss the key when the tap gesture is used on the view
        view.endEditing(true)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            bottomConstraint.constant = keyboardSize.height + 10
            
            UIView.animate(withDuration: 0.5) {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        bottomConstraint.constant = 20
        
        UIView.animate(withDuration: 0.5) {
            self.view.layoutIfNeeded()
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // Phone number field did begin editing.
        // Set the text to be the default country code
        
        if (textField.tag == 1) {
            // The phone number text field has a tag of 1 in the storyboard
            if let country = (Locale.current as NSLocale).object(forKey: .countryCode) as? String {
                let countryCode = phoneNumberKit.countryCode(for: country)!
                phoneNumberTextField.text = "+\(countryCode) "
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func alertError(msg: String) {
        let alert = UIAlertController(title: "Error", message: msg, preferredStyle: .alert)
        let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(defaultAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    func getOrCreateHyperTrackUser() {
        let name = nameTextField.text ?? ""
        var phone = phoneNumberTextField.text ?? ""
        
        if (phone != "") {
            do {
                let parsedPhone = try phoneNumberKit.parse(phone)
                phone = phoneNumberKit.format(parsedPhone, toType: .e164) // Sends phone as +15103094946
            }
            catch {
                alertError(msg: "Please enter a valid phone number")
                return
            }
        }
        
        // Phone number is used as the user lookup id
        self.showActivityIndicator()
        HyperTrack.getOrCreateUser(name, _phone: phone, phone) { (user, error) in
            self.hideActivityIndicator()
            
            if (error != nil) {
                // Handle error on get or create user
                self.alertError(msg: (error?.type.rawValue)!)
                return
            }
            
            if (user != nil) {
                // User successfully created
                
                if (phone != "") {
                    // If phone was given, send verification code
                    self.sendVerificationCode()
                } else {
                    // So user was created but since there was no phone
                    // number, just go to the placeline screen
                    self.onboardingViewDelegate?.didSkipProfile()
                }
            }
        }
    }
    
    func sendVerificationCode() {
        let requestService = RequestService.shared
        requestService.sendHyperTrackCode(completionHandler: { (error) in
            if (error != nil) {
                // Handle error
                // TODO: better handling required
                self.alertError(msg: "Verification code could not be sent")
            } else {
                // This means the verification text was sent successfully
                // Move to the verification code view.
                let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
                let verifyController = storyboard.instantiateViewController(withIdentifier: "ValidateCodeVC") as! ValidateCodeVC
                verifyController.onboardingViewDelegate = self.onboardingViewDelegate
                self.present(verifyController, animated: true, completion: nil)
            }
        })
    }
    
    func showActivityIndicator(animated: Bool = true) {
        MBProgressHUD.showAdded(to: self.view, animated: animated)
    }
    
    func hideActivityIndicator(animate animated: Bool = true) {
        MBProgressHUD.hide(for: self.view, animated: animated)
    }
}

