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

class UserProfileVC: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var nameTextField: CustomTextField!
    @IBOutlet weak var phoneNumberTextField: CustomPhoneTextField!
    
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!

    @IBAction func saveProfile(_ sender: Any) {
        // TODO: check for empty name and validate phone
        // before creating the user. Phone number must have
        // country code.
        getOrCreateHyperTrackUser()
    }

    @IBAction func skipProfile(_ sender: Any) {
        self.performSegue(withIdentifier: "showPlaceline", sender: self)
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
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
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
                let phoneNumberKit = PhoneNumberKit()
                let countryCode = phoneNumberKit.countryCode(for: country) as! UInt64
                phoneNumberTextField.text = "+\(countryCode) "
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getOrCreateHyperTrackUser() {
        let name = nameTextField.text ?? ""
        let phone = phoneNumberTextField.text ?? ""

        HyperTrack.getOrCreateUser(name, _phone: phone, phone) { (user, error) in
            if (error != nil) {
                // Handle error on get or create user
                let alert = UIAlertController(title: "Error", message: error?.type.rawValue, preferredStyle: .alert)
                self.present(alert, animated: true, completion: nil)
                return
            }
            
            if (user != nil) {
                // User successfully created
                
                if (phone != "") {
                    // If phone was given, send verification code
                    self.sendVerificationCode()
                }
            }
        }
    }
    
    func sendVerificationCode() {
        let requestService = RequestService.shared
        requestService.resendHyperTrackCode(completionHandler: { (error) in
            if (error != nil) {
                // Handle error
            } else {
                // This means the verification text was sent successfully
                // Move to the verification code view.
            }
        })
    }
}

