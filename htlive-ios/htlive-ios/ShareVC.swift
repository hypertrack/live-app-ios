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

class ShareVC: UIViewController  {
    
    @IBOutlet fileprivate weak var hyperTrackView: UIView!
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var currentTrackingLookUpId = getCurrentlyTrackedLookUpId()
        if(currentTrackingLookUpId != nil){
            trackHypertrackAction(lookUpId: currentTrackingLookUpId)
        }
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let hyperTrackMap = HyperTrack.map()
        
        hyperTrackMap.setHTViewCustomizationDelegate(customizationDelegate: self)
        hyperTrackMap.setHTViewInteractionDelegate(interactionDelegate: self)
        
        if (self.hyperTrackView != nil) {
            hyperTrackMap.embedIn(self.hyperTrackView)
        }
        
        locationManager.requestAlwaysAuthorization()
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
    
    func enableLiveLocationSharingView(map: HTMap) -> Bool {
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
        self.view.showActivityIndicator()
        startLiveLocationSharingAction(lookUpId: nil, place: place) { (lookUpId, error) in
            self.view.hideActivityIndicator()
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
        self.view.showActivityIndicator()
        HyperTrack.completeAction(actionId)
        deleteTrackedLookUpId()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { // in half a second...
            self.view.hideActivityIndicator(animate: true)
        }
        
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
        
        // text to share
        let text = "I'm on my way." + "Track me live " + action.trackingUrl!
        
        // set up activity view controller
        let textToShare = [ text ]
        let activityViewController = UIActivityViewController(activityItems: textToShare, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
        
        // exclude some activity types from the list (optional)
        activityViewController.excludedActivityTypes = [ UIActivityType.airDrop, UIActivityType.postToFacebook ]
        
        // present the view controller
        self.present(activityViewController, animated: true, completion: nil)
        
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
