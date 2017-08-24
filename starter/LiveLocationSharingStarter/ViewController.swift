//
//  ViewController.swift
//  LiveLocationSharingStarter
//
//  Created by Ravi Jain on 8/21/17.
//  Copyright © 2017 Ravi Jain. All rights reserved.
//

import UIKit
import HyperTrack

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        
    }
    
    func isSDKInitialized() -> Bool{
        if (HyperTrack.getPublishableKey() == nil){
            showAlert(title:"Step 3 is not completed", message: "Please initialize the Hypertrack SDK.")
            return false
        }
        
        
        if(HyperTrack.getPublishableKey() == "YOUR_PUBLISHABLE_KEY"){
            showAlert(title:"Step 3 is not completed", message: "The API key is not correct.If you have the key add it properyly, if you don't get the API Key as described on the repo.")
            return false
        }
        
        if(HyperTrack.getUserId() == nil || HyperTrack.getUserId() == ""){
            showAlert(title:"Step 4 is not completed", message: "Yay the SDK is set up , but the user is not created",buttonTitle: "Create User" ){(action) in
                self.presentUserProfileVc()
            }
        }
        
        return true
    }

    override func viewDidAppear(_ animated: Bool) {
      
        isSDKInitialized()

    }
    
    @IBAction func startLiveLocationSharing(_ sender: Any) {
        if (isSDKInitialized()){
            presentLiveLocationVc()
        }
    }
    
    
    
    func presentUserProfileVc(){
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let userProfileVC = storyboard.instantiateViewController(withIdentifier: "UserProfileViewController") as! UserProfileViewController
        self.present(userProfileVC, animated: true, completion: nil)
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
    
    @IBAction func trackLiveLocationTrip(_ sender: Any) {
        if (isSDKInitialized()){
            presentTrackLiveLocationVc()

        }
    }
    
    func presentLiveLocationVc(){
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let userProfileVC = storyboard.instantiateViewController(withIdentifier: "ShareLiveLocationVC") as! ShareLiveLocationVC
        self.present(userProfileVC, animated: true, completion: nil)
    }
    
    func presentTrackLiveLocationVc(){
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let userProfileVC = storyboard.instantiateViewController(withIdentifier: "TrackLiveLocationVC") as! TrackLiveLocationVC
        self.present(userProfileVC, animated: true, completion: nil)
    }

}

