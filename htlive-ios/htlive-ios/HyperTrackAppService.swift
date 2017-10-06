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
import UserNotifications

class HyperTrackAppService: NSObject {
    
    let flowInteractor = HyperTrackFlowInteractor()
    static let sharedInstance = HyperTrackAppService()
    var currentAction : HyperTrackAction? = nil
    var currentTrackedAction : HyperTrackAction? = nil
    var defaultRootViewController : UIViewController? = nil

    func applicationDidFinishLaunchingWithOptions(launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        setUpSDKs()
        self.defaultRootViewController = UIApplication.shared.windows.first?.rootViewController
        self.flowInteractor.presentFlowsIfNeeded()
        self.setupBranchDeeplink()
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
       
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
    
    
    func getDefaultRootViewController()-> UIViewController{
        if self.defaultRootViewController != nil {
            return self.defaultRootViewController!
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let viewController = storyboard.instantiateViewController(withIdentifier: "PlaceLineVC") as! ViewController
        return viewController
    }
    
    func getCurrentRootViewController()->UIViewController?{
        return UIApplication.shared.windows.first?.rootViewController
    }
    
    func getCurrentCollectionId() -> String? {
        return UserDefaults.standard.string(forKey: "currentLookUpID")
    }
    
    func setCurrentCollectionId(collectionId : String){
        UserDefaults.standard.set(collectionId, forKey: "currentLookUpID")
        UserDefaults.standard.synchronize()
    }
    
    func deleteCurrentCollectionId(){
        UserDefaults.standard.removeObject(forKey: "currentLookUpID")
        UserDefaults.standard.synchronize()
    }
    
    func getCurrentTrackedAction () -> HyperTrackAction? {
        
        if self.currentTrackedAction != nil{
            return self.currentTrackedAction
        }
        
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
        self.currentTrackedAction = action
        let jsonStr = action.toJson()
        UserDefaults.standard.set(jsonStr, forKey: "currentTrackedAction")
        UserDefaults.standard.synchronize()
    }
    
    func deleteCurrentTrackedAction(){
        self.currentTrackedAction = nil
        UserDefaults.standard.removeObject(forKey: "currentTrackedAction")
        UserDefaults.standard.synchronize()
    }
    
    func completeAction(){
        if let currentAction  = self.getCurrentTrackedAction(){
            // check for current user
            HyperTrack.completeAction(currentAction.id!)
            if let collectionId = self.getCurrentCollectionId(){
                HyperTrack.removeActionForCollectionId(collectionId: collectionId)
                
            }
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
                            if let collectionId =  htActions.last?.collectionId{
                                self.flowInteractor.presentLiveLocationFlow(collectionId: collectionId,shortCode:shortCode)
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
        if(region.identifier == self.getCurrentCollectionId()){
            
            if let currentAction  = self.getCurrentTrackedAction(){
                // check for current user
                HyperTrack.completeAction(currentAction.id!)
            }
            self.sendLocalNotification(title: "Trip Finished.", body: "You have reached your destination.")
        }
    }
    
    func didShowSummary(forAction : HyperTrackAction){
        if (forAction.collectionId == self.getCurrentCollectionId()){
            HyperTrackAppService.sharedInstance.deleteCurrentCollectionId()
            HyperTrackAppService.sharedInstance.deleteCurrentTrackedAction()
        }
    }
    
    func didRefreshData(forAction: HyperTrackAction){
        
        
        
    }

    
    
}

extension HyperTrackAppService: UNUserNotificationCenterDelegate{
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Update the app interface directly.
        
        // Play a sound.
        completionHandler(UNNotificationPresentationOptions.sound)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
//        if response.notification.request.identifier == "ReviewPlaceline" {
//            flowInteractor.presentReviewPlaceLineView()
//        }
        
        // Else handle actions for other notification types. . .
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
                    self.flowInteractor.acceptInvitation(params!["account_id"] as! String)
                }else{
//                    self.flowInteractor.addAcceptInviteFlow(params!["user_id"] as! String, params!["account_id"] as! String, params!["account_name"] as! String)
                    
                }
            }
        }
    }
}
