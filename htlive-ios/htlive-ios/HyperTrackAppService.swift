//
//  HyperTrackAppService.swift
//  htlive-ios
//
//  Created by Ravi Jain on 7/14/17.
//  Copyright © 2017 PZRT. All rights reserved.
//

import UIKit
import HyperTrack
import Branch

class HyperTrackAppService: NSObject {
    
    let flowInteractor = HyperTrackFlowInteractor()
    static let sharedInstance = HyperTrackAppService()
    var currentAction : HyperTrackAction? = nil
    
    func setupHyperTrack() {
        HyperTrack.initialize(YOUR_PUBLISHABLE_KEY)
        HyperTrack.setEventsDelegate(eventDelegate: self)
        
        
        if(HyperTrack.getUserId() != nil){
            HyperTrack.startTracking()
            if(self.getCurrentLookUPId() != nil){
                HyperTrack.trackActionFor(lookUpId: self.getCurrentLookUPId()!, completionHandler: { (actions, error) in
                    if let _ = error {
                        return
                    }
                    self.currentAction = actions?.last
                })
            }
        }
    }

    func getCurrentLookUPId () -> String? {
       return UserDefaults.standard.string(forKey: "currentLookUpID")
    }
    
    func setCurrentLookUpId(lookUpID : String){
        UserDefaults.standard.set(lookUpID, forKey: "currentLookUpID")
    }
    
    func deleteCurrentLookUpId(){
        UserDefaults.standard.removeObject(forKey: "currentLookUpID")
    }
    
    func completeAction(){
        if let currentAction  = self.currentAction{
            // check for current user
            HyperTrack.completeAction(currentAction.id!)
            HyperTrackAppService.sharedInstance.deleteCurrentLookUpId()
        }
    }

    func applicationDidFinishLaunchingWithOptions(launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        setUpSDKs()

        DispatchQueue.main.async( execute:{
            self.flowInteractor.presentFlowsIfNeeded()
            self.setupBranchDeeplink()
            
        })
        
        
        return true
    }
    
    func startTrackingIfPartOfExistingTrip(){
        if(getCurrentLookUPId() != nil){
            HyperTrack.trackActionFor(lookUpId: HyperTrackAppService.sharedInstance.getCurrentLookUPId()!, completionHandler: { (actions, error) in
                if(actions != nil){
                    if let action = actions?.last {
                        if(action.isCompleted()){
                            self.deleteCurrentLookUpId()
                        }
                    }
                    
                }
            })
        }
    }
    
    func applicationDidBecomeActive() {

    }
    
    func applicationWillTerminate() {
   
        
    }
    
    func applicationContinue (userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        
        if (Branch.getInstance().continue(userActivity)) {
            // do nothing
                        
            return true
        }

        // handle deeplink here and ask flow interactor to start flows which are needed
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb {
            let url =  userActivity.webpageURL as NSURL?
            if let lastPathComponent = url?.lastPathComponent{
                flowInteractor.presentLiveLocationFlow(shortCode: lastPathComponent)
            }
        }
    
        return true
    }
    
    func setUpSDKs(){
        setupHyperTrack()
    }

    
    
}

extension HyperTrackAppService : HTEventsDelegate {
 
    func didEnterMonitoredDestinationRegionForAction(forAction : HyperTrackAction){
        HyperTrack.completeAction(forAction.id!)
    }
    
    func didShowSummary(forAction : HyperTrackAction){
        if (forAction.lookupId == self.getCurrentLookUPId()){
            self.deleteCurrentLookUpId()
        }
    }
}

extension HyperTrackAppService {
    fileprivate func setupBranchDeeplink(launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) {
        let branch: Branch = Branch.getInstance()
        branch.initSession(launchOptions: launchOptions) { (params, error) in
            if (error == nil), (params != nil), (params!["+clicked_branch_link"] as? Bool == true) {
                // Branch deeplink was clicked, process the params to proceed further
                print("Branch deeplink params: %@", params?.description as Any)
                
                if (params!["auto_accept"] as? Bool == true){
                    self.flowInteractor.acceptInvitation(params!["user_id"] as! String, params!["account_id"] as! String, params!["account_name"] as! String)
                }else{
                    self.flowInteractor.addAcceptInviteFlow(params!["user_id"] as! String, params!["account_id"] as! String, params!["account_name"] as! String)

                }
            }
        }
    }
}
