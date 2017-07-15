//
//  HyperTrackAppService.swift
//  htlive-ios
//
//  Created by Ravi Jain on 7/14/17.
//  Copyright © 2017 PZRT. All rights reserved.
//

import UIKit

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
        BuddyBuildSDK.setup()

    }


}
