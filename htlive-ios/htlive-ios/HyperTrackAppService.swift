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
        flowInteractor.presentFlowsIfNeeded()
        return true
    }
    
    func applicationDidBecomeActive() {

    }
    
    func applicationWillTerminate() {
   
        
    }
    
    func applicationContinue (userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
     // handle deeplink here and ask flow interactor to start flows which are needed
        
        
        return true
    }
    
    func setUpSDKs(){
        setupHyperTrack()
        setupBuddyBuild()
    }

    func setupHyperTrack() {
        HyperTrack.initialize("pk_test_efc7e2b08075118cd097599c7dcd05e33eb65afe")
    }
    
    func setupBuddyBuild() {
        BuddyBuildSDK.setup()
    }
}
