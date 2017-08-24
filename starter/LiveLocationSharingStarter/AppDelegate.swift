//
//  AppDelegate.swift
//  LiveLocationSharingStarter
//
//  Created by Ravi Jain on 8/21/17.
//  Copyright © 2017 Ravi Jain. All rights reserved.
//

import UIKit
import HyperTrack

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        //Basic Setup - Step 3: initialize hypertrack sdk and request for permissions here
        
        HyperTrack.initialize("pk_e956d4c123e8b726c10b553fe62bbaa9c1ac9451")
        HyperTrack.requestAlwaysAuthorization()
        HyperTrack.requestMotionAuthorization()

        
        return true
    }

    
   
    func applicationDidEnterBackground(_ application: UIApplication) {
        
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
           }

    func applicationDidBecomeActive(_ application: UIApplication) {
    }

    func applicationWillTerminate(_ application: UIApplication) {
    }


}

