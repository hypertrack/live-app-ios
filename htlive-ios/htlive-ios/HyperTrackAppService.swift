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
    var defaultRootViewController : UIViewController? = nil
    var completedActions = [String]()
    
    func applicationDidFinishLaunchingWithOptions(launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        setUpSDKs()
        self.defaultRootViewController = UIApplication.shared.windows.first?.rootViewController
        self.flowInteractor.presentFlowsIfNeeded()
        self.setupBranchDeeplink()
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
    
    func setupHyperTrack() {
        // staging pk : pk_03e3176a9831360e162093292049757b130c75cf
        // production pk : pk_e956d4c123e8b726c10b553fe62bbaa9c1ac9451
        HyperTrack.initialize("sk_35b9d87cba7ca206bcb7a06d5c94b24a58cdaac3")
//        HyperTrack.initialize("pk_e956d4c123e8b726c10b553fe62bbaa9c1ac9451")

        // staging
//        HyperTrack.initialize("pk_03e3176a9831360e162093292049757b130c75cf")

        if(HyperTrack.getUserId() != nil){
//            HyperTrack.startTracking()
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

    func deleteLocationSelectionType(){
        UserDefaults.standard.removeObject(forKey: "locationSelectionType")
        UserDefaults.standard.synchronize()
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
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: HTLiveConstants.trackUsingUrl), object: shortCode)
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
}

extension HyperTrackAppService: UNUserNotificationCenterDelegate{
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler(UNNotificationPresentationOptions.sound)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        
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
