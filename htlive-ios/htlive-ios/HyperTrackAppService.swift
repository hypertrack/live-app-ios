//
//  HyperTrackAppService.swift
//  htlive-ios
//
//  Created by Ravi Jain on 7/14/17.
//  Copyright © 2017 PZRT. All rights reserved.
//

import UIKit
import HyperTrack

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
    }
    
    func setupBuddyBuild() {
        BuddyBuildSDK.setup()
    }
}
