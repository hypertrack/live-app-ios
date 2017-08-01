//
//  ShareVC.swift
//  htlive-ios
//
//  Created by Vibes on 7/4/17.
//  Copyright © 2017 PZRT. All rights reserved.
//

import UIKit
import HyperTrack
import MapKit
import CoreGraphics
import Contacts
import MessageUI

class ShareVC: UIViewController  {
    
    @IBOutlet fileprivate weak var hyperTrackView: UIView!
    let locationManager = CLLocationManager()
    var shortCode : String?
    var hyperTrackMap : HTMap? = nil
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // check if shortcode is provided
        
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        self.view.showActivityIndicator()
        locationManager.requestAlwaysAuthorization()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        self.view.hideActivityIndicator()
        
        if(hyperTrackMap == nil){
          
            hyperTrackMap = HyperTrack.map()
            hyperTrackMap?.enableLiveLocationSharingView = true
            
            hyperTrackMap?.setHTViewCustomizationDelegate(customizationDelegate: self)
            hyperTrackMap?.setHTViewInteractionDelegate(interactionDelegate: self)
            
            if (self.hyperTrackView != nil) {
                hyperTrackMap?.embedIn(self.hyperTrackView)
            }
        }
        
      
        
        //        if(shortCode != nil){
        //            trackActionForShortCode(shortCode: shortCode!)
        //            return
        //        }
        //
        //        var currentTrackingLookUpId = getCurrentlyTrackedLookUpId()
        //
        //        if(currentTrackingLookUpId != nil){
        //            trackHypertrackAction(lookUpId: currentTrackingLookUpId)
        //        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func trackActionForShortCode(shortCode : String){
        if (self.shortCode != nil) {
            self.view.showActivityIndicator(animated: true)
            HyperTrack.getActionsFromShortCode(shortCode, completionHandler: { (actions, error) in
                
                
                if (error !=  nil) {
                    self.view.hideActivityIndicator(animate: true)
                    self.showAlert(title: "Error", message: error?.type.rawValue)
                    return
                }
                
                if let actions = actions {
                    if (actions.count > 0) {
                        HyperTrack.trackActionFor(lookUpId: (actions.last?.lookupId)!, completionHandler: { (actions, error) in
                            self.view.hideActivityIndicator(animate: true)
                            
                            if (error != nil) {
                                self.showAlert(title: "Error", message: error?.type.rawValue)
                                return
                            }
                            
                        })
                    } else {
                        self.showAlert(title: "Error", message: "Unable to fetch details for this link. Please try again.")
                        self.view.hideActivityIndicator(animate: true)
                    }
                    
                } else{
                    
                    self.view.hideActivityIndicator(animate: true)
                    
                    HyperTrack.trackActionFor(shortCode:shortCode, completionHandler: { (action, error) in
                        self.view.hideActivityIndicator(animate: true)
                        
                        if (error != nil) {
                            self.showAlert(title: "Error", message: error?.type.rawValue)
                            return
                        }
                    })
                }
            })
        }
        
    }
    
    fileprivate var error: NSError {
        get {
            return NSError(domain: "io.hypertrack.meta", code: 400, userInfo: nil)
        }
    }
    
    fileprivate func showAlert(title: String?, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let ok: UIAlertAction = UIAlertAction.init(title: "OK", style: .cancel, handler: nil)
        alert.addAction(ok)
        
        self.present(alert, animated: true, completion: nil)
    }
}

extension ShareVC:HTViewCustomizationDelegate{
    
    func showInfoViewForActionID(map: HTMap, actionID: String) -> Bool{
        return true
    }
}


extension ShareVC:HTViewInteractionDelegate {
    
    func didTapBackButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    func didTapJoinLiveLocationSharing(action : HyperTrackAction? ){
        self.view.showActivityIndicator()
        startLiveLocationSharingAction(lookUpId: action?.lookupId, place: action?.expectedPlace) { (lookUpId, error) in
            self.view.hideActivityIndicator()
            if let _ = error {
                self.showAlert(title: "Error", message: error?.localizedDescription)
                return
            }else{
                self.saveLookUpId(lookUpId: lookUpId!)
            }
        }
    }
    
    
    func didTapStartLiveLocationSharing(place : HyperTrackPlace) {
        
        startLiveLocationSharingAction(lookUpId: nil, place: place) { (lookUpId, error) in
            if let _ = error {
                self.showAlert(title: "Error", message: error?.localizedDescription)
                return
            }
            else{
                
                self.saveLookUpId(lookUpId: lookUpId!)
            }
            
        }
    }
    
    func didTapStopLiveLocationSharing(actionId : String){
//        self.view.showActivityIndicator()
        
        let alert = UIAlertController(title: "End Tracking", message: "Are you sure ?", preferredStyle: .alert)
        
        let no: UIAlertAction = UIAlertAction.init(title: "No", style: .cancel, handler: {(alert: UIAlertAction!) in
        })
        
        let yes :UIAlertAction = UIAlertAction.init(title: "Yes", style: .default, handler: {(alert: UIAlertAction!) in
             HyperTrack.completeAction(actionId)
        })

        alert.addAction(no)
        alert.addAction(yes)

        self.present(alert, animated: true, completion: nil)

    }
    
    func didTapShareLiveLocationLink(action : HyperTrackAction){
        self.shareLink(action: action)
    }
    
    func startLiveLocationSharingAction(lookUpId : String?, place : HyperTrackPlace?, completion: @escaping ((_ lookUpId:String?,Error?) -> Void)) {
        
        guard let place = place else {
            completion(nil,self.error)
            return
        }
        let htActionParams = HyperTrackActionParams()
        htActionParams.expectedPlace = place
        htActionParams.type = "visit"
        if(lookUpId == nil){
            htActionParams.lookupId = UUID().uuidString
        }else{
            htActionParams.lookupId = lookUpId!
        }
        
        HyperTrack.createAndAssignAction(htActionParams, { (action, error) in
            if let error = error {
                completion(nil,NSError(domain: error.type.rawValue, code: 0, userInfo: nil) as Error)
                return
            }
            if let action = action {
                HyperTrack.trackActionFor(lookUpId: action.lookupId!, completionHandler: { (actions, error) in
                    if (error != nil) {
                        completion(nil,NSError(domain: (error?.type.rawValue)!, code: 0, userInfo: nil) as Error)
                        return
                    }
                })
                
                
                self.shareLink(action: action)
                completion(action.lookupId,nil)
                return
            }
        })
    }
    
    func trackHypertrackAction(lookUpId:String?) {
        
        //        self.view.showActivityIndicator()
        
        HyperTrack.trackActionFor(lookUpId: lookUpId!) { (actions, error) in
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { // in half a second...
                self.view.hideActivityIndicator(animate: true)
            }
            
            if (error != nil) {
                self.showAlert(title: "Error", message: error?.type.rawValue)
                return
            }
        }
    }
    
    func shareLink(action : HyperTrackAction) {
        
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        
        let shareView: CustomShareView = Bundle.main.loadNibNamed("CustomShareView", owner: self, options: nil)?.first as! CustomShareView
        
        shareView.shareDelegate = self
        
        if(action.eta != nil){
            
            let dateString = formatter.string(from: action.eta!)
            
            var etaMinutes = 0.0
            
            let actionDisplay = action.display
            if (actionDisplay != nil) {
                if let duration = actionDisplay!.durationRemaining {
                    let timeRemaining = duration
                    etaMinutes = Double(timeRemaining / 60)
                    shareView.etaLabel.text = "You're " + etaMinutes.description + " min away!"
                }
            }
            // text to share
            let text = "I'm on my way. Will be there by " + dateString +  ". Track me live " + action.trackingUrl!
            shareView.linkText = text
        }
        else{
            shareView.etaLabel.text = ""
            let text = "I'm on my way. Track me live " + action.trackingUrl!
            shareView.linkText = text
        }
        
        
        self.view.addSubview(shareView)
        
        shareView.linkLabel.text = action.trackingUrl!
        
        shareView.frame = CGRect(x:0,y:(self.view.frame.height + (shareView.frame.size.height)),width : self.view.frame.size.width,height:shareView.frame.size.height)
        UIView.animate(withDuration: 0.5, animations: {
            shareView.frame = CGRect(x:0,y:(self.view.frame.height-(shareView.frame.size.height)),width : self.view.frame.size.width,height:shareView.frame.size.height)
            
        })
    }
    
    func saveLookUpId(lookUpId : String?){
        UserDefaults.standard.set(lookUpId, forKey: HTLiveConstants.currentTrackedLookUpId)
        UserDefaults.standard.synchronize()
    }
    
    func getCurrentlyTrackedLookUpId() -> String?{
        return UserDefaults.standard.string(forKey: HTLiveConstants.currentTrackedLookUpId)
    }
    
    func deleteTrackedLookUpId(){
        return UserDefaults.standard.removeObject(forKey: HTLiveConstants.currentTrackedLookUpId)
    }
    
}

extension ShareVC : CustomShareViewDelegate,MFMessageComposeViewControllerDelegate{
    
    func didClickOnShare(view : CustomShareView){
        //set up activity view controller
        let textToShare = [view.linkText]
        let activityViewController = UIActivityViewController(activityItems: textToShare, applicationActivities: nil)
        
        // exclude some activity types from the list (optional)
        activityViewController.excludedActivityTypes = [ UIActivityType.airDrop ]
        
        // present the view controller
        self.present(activityViewController, animated: true, completion: nil)
        
    }
    func didClickOnMessenger(view : CustomShareView){
        let urlStr = "fb-messenger://share?link=" + view.linkLabel.text!
        if let url = URL.init(string: urlStr) {
            NSLog(urlStr)
            if(UIApplication.shared.canOpenURL(url)){
                UIApplication.shared.open(url, options: [:], completionHandler: { (shared) in
                })
            }
        }
    }
    func didClickOnWhatsapp(view : CustomShareView){
        let urlStr = "whatsapp://send?text=" +  view.linkLabel.text!
        if let url = URL.init(string: urlStr) {
            if(UIApplication.shared.canOpenURL(url)){
                UIApplication.shared.open(url, options: [:], completionHandler: { (shared) in
                })
            }
        }
    }
   
    func didClickOnMessages(view : CustomShareView){
        
        if MFMessageComposeViewController.canSendText() == true {
            let messageController = MFMessageComposeViewController()
            messageController.messageComposeDelegate  = self
            messageController.body = view.linkText
            self.present(messageController, animated: true, completion: nil)
        } else {
            //handle text messaging not available
        }
    }
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult){
        controller.dismiss(animated: true, completion: nil)
    }

}


