//
//  UserProfileVC.swift
//  htlive-ios
//
//  Created by Piyush on 17/07/17.
//  Copyright © 2017 PZRT. All rights reserved.
//

import Foundation
import HyperTrack

class UserProfileVC: UIViewController {
    
    @IBOutlet weak var nameTextField: CustomTextField!
    @IBOutlet weak var phoneNumberTextField: CustomTextField!
    
    @IBAction func proceed(_ sender: Any) {
        self.performSegue(withIdentifier: "showPlaceline", sender: self)
    }
    
    @IBAction func saveProfile(_ sender: Any) {
        // TODO: check for empty name or valid phone
        // before creating the user
        getOrCreateHyperTrackUser()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        nameTextField.becomeFirstResponder()
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getOrCreateHyperTrackUser() {
        let name = nameTextField.text!
        let phone = phoneNumberTextField.text!

        HyperTrack.getOrCreateUser(name, _phone: phone, phone) { (user, error) in
            if (error != nil) {
                // Handle error on get or create user
                let alert = UIAlertController(title: "Error", message: error?.type.rawValue, preferredStyle: .alert)
                self.present(alert, animated: true, completion: nil)
                return
            }
            
            if (user != nil) {
                // User successfully created
            }
        }
    }
}
