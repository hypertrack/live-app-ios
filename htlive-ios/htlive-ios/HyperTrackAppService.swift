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
import CoreLocation
import Fabric
import Crashlytics

class HyperTrackAppService: NSObject {
    
    let flowInteractor = HyperTrackFlowInteractor()
    static let sharedInstance = HyperTrackAppService()
    var currentAction : HyperTrackAction? = nil
    var currentTrackedAction : HyperTrackAction? = nil
    
    func setupHyperTrack() {
        HyperTrack.initialize("pk_e956d4c123e8b726c10b553fe62bbaa9c1ac9451")
        HyperTrack.setEventsDelegate(eventDelegate: self)
        if(HyperTrack.getUserId() != nil){
            HyperTrack.startTracking()
        }
    }
    
    
    func setupFabric(){
         Fabric.with([Crashlytics.self])
    }
    
    
    func getCurrentLookUPId () -> String? {
        return UserDefaults.standard.string(forKey: "currentLookUpID")
    }
    
    func setCurrentLookUpId(lookUpID : String){
        UserDefaults.standard.set(lookUpID, forKey: "currentLookUpID")
        UserDefaults.standard.synchronize()
    }
    
    func deleteCurrentLookUpId(){
        UserDefaults.standard.removeObject(forKey: "currentLookUpID")
        UserDefaults.standard.synchronize()
    }
    
    func getCurrentTrackedAction () -> HyperTrackAction? {
        if let jsonStr =  UserDefaults.standard.string(forKey: "currentTrackedAction"){
            if let data = jsonStr.data(using: String.Encoding.utf8){
                if let action  = HyperTrackAction.fromJson(data: data){
                    return action
                }
            }
        }
        
        if let action = self.currentAction {
            if self.currentAction?.user?.id == HyperTrack.getUserId(){
                return action
            }
        }
        

        return nil
    }
    
    func setCurrentTrackedAction(action : HyperTrackAction){
        let jsonStr = action.toJson()
        UserDefaults.standard.set(jsonStr, forKey: "currentTrackedAction")
        UserDefaults.standard.synchronize()
    }
    
    func deleteCurrentTrackedAction(){
        UserDefaults.standard.removeObject(forKey: "currentTrackedAction")
        UserDefaults.standard.synchronize()
    }
    
    func completeAction(){
        if let currentAction  = self.getCurrentTrackedAction(){
            // check for current user
            HyperTrack.completeAction(currentAction.id!)
            if let lookupId = self.getCurrentLookUPId(){
                HyperTrack.removeActionFor(lookUpId: lookupId)
                
            }
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // handle deeplink here and ask flow interactor to start flows which are needed
            if userActivity.activityType == NSUserActivityTypeBrowsingWeb {
                let url =  userActivity.webpageURL as NSURL?
                if let shortCode = url?.lastPathComponent{
                    if (HyperTrackFlowInteractor.topViewController()?.isKind(of: ShareVC.self))!{
                        if let controller =  HyperTrackFlowInteractor.topViewController() as? ShareVC{
                            if (controller.shortCode ==  shortCode){
                                return
                            }
                        }
                    }
                    
                    HyperTrackFlowInteractor.topViewController()?.view.showActivityIndicator()
                    HyperTrack.getActionsFromShortCode(shortCode, completionHandler: { (actions, error) in
                        HyperTrackFlowInteractor.topViewController()?.view.hideActivityIndicator()
                        if let _ = error {
                            self.showAlert(title: "Error", message: error?.errorMessage)
                            return
                        }
                        
                        if let htActions = actions {
                            if let lookupId =  htActions.last?.lookupId{
                                self.flowInteractor.presentLiveLocationFlow(lookUpId: lookupId,shortCode:shortCode)
                            }else{
                                self.showAlert(title: "Error", message: "Something went wrong, no look up id in the action")
                            }
                            
                        }else {
                            self.showAlert(title: "Error", message: "Something went wrong, no actions for this lookup id")
                            
                        }
                    })
                }
            }
        }
       return true
    }
    
    fileprivate func showAlert(title: String?, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let ok : UIAlertAction = UIAlertAction.init(title: "OK", style: .cancel) { (action) in
        }
        alert.addAction(ok)
        HyperTrackFlowInteractor.topViewController()?.present(alert, animated: true, completion: nil)
    }
    
    func setUpSDKs(){
        setupHyperTrack()
        setupFabric()
    }
    
    @objc func sendLocalNotification(title: String, body: String) {
        let notification = UILocalNotification()
        notification.alertTitle = title
        notification.alertBody = body
        notification.alertAction = "Open"
        
        notification.fireDate = Date.init(timeInterval: 3, since: Date())
        UIApplication.shared.scheduleLocalNotification(notification)
    }

    
}

extension HyperTrackAppService : HTEventsDelegate {
    
    func didEnterMonitoredRegion(region:CLRegion){
        if(region.identifier == self.getCurrentLookUPId()){
            self.completeAction()
            self.sendLocalNotification(title: "Trip Finished.", body: "You have reached your destination.")
            
        } 
    }
    
    func didShowSummary(forAction : HyperTrackAction){
        if (forAction.lookupId == self.getCurrentLookUPId()){
            HyperTrackAppService.sharedInstance.deleteCurrentLookUpId()
            HyperTrackAppService.sharedInstance.deleteCurrentTrackedAction()
        }
    }
    
    func didRefreshData(forAction: HyperTrackAction){
        
        
        
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
