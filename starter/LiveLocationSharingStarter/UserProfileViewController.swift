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
            
            // Step 4 : Create a HyperTrack User

        
        
        
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
