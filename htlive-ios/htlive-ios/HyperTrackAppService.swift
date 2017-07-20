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

    func applicationDidFinishLaunchingWithOptions(launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        setUpSDKs()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.flowInteractor.presentFlowsIfNeeded()
        }
        return true
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
        setupBuddyBuild()
    }

    func setupHyperTrack() {
        HyperTrack.initialize("pk_e956d4c123e8b726c10b553fe62bbaa9c1ac9451")
        if(HyperTrack.getUserId() != nil){
            HyperTrack.startTracking()
        }
    }
    
    func setupBuddyBuild() {
        BuddyBuildSDK.setup()
    }
}



extension HyperTrackAppService {
    fileprivate func setupBranchDeeplink(launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) {
        let branch: Branch = Branch.getInstance()
        branch.initSession(launchOptions: launchOptions) { (params, error) in
            if (error == nil), (params != nil), (params!["+clicked_branch_link"] as! Bool == true) {
                // Branch deeplink was clicked, process the params to proceed further
                print("Branch deeplink params: %@", params?.description as Any)
//                DeepLinkService.deeplinkService.branchDeeplink(userId: params!["user_id"] as! String, accountId: params!["account_id"] as! String, accountName: params!["account_name"] as! String)
            }
        }
    }
}
