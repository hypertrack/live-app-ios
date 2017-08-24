//
//  TrackLiveLocationVC.swift
//  LiveLocationSharingStarter
//
//  Created by Ravi Jain on 8/24/17.
//  Copyright © 2017 Ravi Jain. All rights reserved.
//

import UIKit
import HyperTrack

class TrackLiveLocationVC: UIViewController {
    @IBOutlet weak var lookupIdTextField: UITextField!
    @IBOutlet weak var shareLiveLocation: UIButton!

    @IBOutlet weak var hypertrackView: UIView!
    var hyperTrackMap : HTMap? = nil
    var expectedPlace : HyperTrackPlace? = nil
    @IBOutlet weak var trackButton: UIButton!
   
    override func viewDidLoad() {
        super.viewDidLoad()
        shareLiveLocation.isHidden = true
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func onTrackClick(_ sender: Any) {
        // add a check for lookupid
        if (lookupIdTextField.text == ""){
            
            return
        }
        
        self.lookupIdTextField.isHidden = true
        self.trackButton.isHidden = true
        self.lookupIdTextField.resignFirstResponder()
        self.shareLiveLocation.isHidden = false
        
        // Step 8. User clicked on track button. Start a tracking session for the lookup id entered by user.
        
    }
    
    
    @IBAction func shareLocationClicked(_ sender: Any) {
   
        self.shareLiveLocation.isHidden = true
        
        if let expectedPlace = self.expectedPlace{
           
            // Step 9. User want to join an ongoing trip. Create and assign an action for the same place and lookup id of the ongoing trip

        
        
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

extension TrackLiveLocationVC:HTViewInteractionDelegate {
    
    func didTapBackButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    
    func didTapStopLiveLocationSharing(actionId : String){
        HyperTrack.completeAction(actionId)
    }
}
