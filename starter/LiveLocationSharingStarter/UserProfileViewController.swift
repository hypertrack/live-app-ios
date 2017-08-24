//
//  UserProfileViewController.swift
//  LiveLocationSharingStarter
//
//  Created by Ravi Jain on 8/23/17.
//  Copyright © 2017 Ravi Jain. All rights reserved.
//

import UIKit
import HyperTrack

class UserProfileViewController: UIViewController {

    @IBOutlet weak var userNameLabel: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.userNameLabel.becomeFirstResponder()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onLoginClicked(_ sender: Any) {
        let userName = userNameLabel.text
        if (userNameLabel.text == ""){
            showAlert(title: "Enter your name", message: "Please enter your name and then press login.")
        }else{
            
            // Basic Setup - Step 4 : Create a HyperTrack User

            HyperTrack.createUser(userName!) { (user, error) in
                if (error != nil) {
                    // Handle error on get or create user
                    print("recieved error while creating user. error : " + (error?.errorMessage)!)
                    return
                }
                
                if (user != nil) {
                    // User successfully created
                    print("User created:", user!.id ?? "")
                    HyperTrack.startTracking()
                    self.showAlert(title:"Step 4  completed", message: "Yay Hypertrack User is Created",buttonTitle: "OK, What's Next ?" ){(action) in
                        self.dismiss(animated:true, completion: nil)
                    }
                }
            }
        }
    }
    
    
    fileprivate func showAlert(title: String?, message: String?, buttonTitle : String = "OK",handler: ((UIAlertAction) -> Swift.Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let ok : UIAlertAction = UIAlertAction.init(title: buttonTitle, style: .cancel) { (action) in
            if (handler != nil){
                handler!(action)
            }
        }
        alert.addAction(ok)
        self.present(alert, animated: true, completion: nil)
    }

}
