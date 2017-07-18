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
    
    static fileprivate let prefix = "www."

    
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
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb {
            let url =  userActivity.webpageURL as NSURL?
            if let lastPathComponent = url?.lastPathComponent{
                flowInteractor.presentLiveLocationFlow(shortCode: lastPathComponent)
            }
        }
        return true
    }
    
    func setUpSDKs(){
        BuddyBuildSDK.setup()
        setUpHyperTrack()
    }
    
    func setUpHyperTrack(){
        HyperTrack.initialize("pk_e956d4c123e8b726c10b553fe62bbaa9c1ac9451")
        HyperTrack.setUserId("27515522-2541-4deb-ae27-9b8f4587310e")
        HyperTrack.requestAlwaysAuthorization()
        HyperTrack.requestMotionAuthorization()
    }
    
}
