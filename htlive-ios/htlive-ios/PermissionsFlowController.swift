//
//  PermissionsFlowController.swift
//  htlive-ios
//
//  Created by Ravi Jain on 7/14/17.
//  Copyright © 2017 PZRT. All rights reserved.
//

import UIKit
import HyperTrack

protocol PermissionsDelegate {
    func didDeniedLocationPermissions(currentController : UIViewController)
    func didAcceptedLocationPermissions(currentController : UIViewController)
    func didFinishedAskingPermissions(currentController : UIViewController)
}

class PermissionsFlowController: BaseFlowController {
    
    var hasAskedPermissions  = false

    override func isFlowCompleted() -> Bool {
        
        if(hasAskedPermissions){
            return true
        }
        
        if (HyperTrack.locationServicesEnabled() && HyperTrack.locationAuthorizationStatus() == .authorizedAlways) {
            return true
        }
        return false
    }
    
    override func isFlowMandatory() -> Bool {
        return false
    }
    
    override func startFlow(force : Bool, presentingController:UIViewController){
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let requestPermissionsController = storyboard.instantiateViewController(withIdentifier: "RequestPermissionsVC") as! RequestPermissionsVC
        requestPermissionsController.permissionDelegate = self
        presentingController.present(requestPermissionsController, animated: true, completion: nil)
    }
    
    override func getFlowPriority() -> Int {
        return -1
    }
}


extension PermissionsFlowController:PermissionsDelegate {
    
    func didDeniedLocationPermissions(currentController : UIViewController){
        
    }
    
    func didAcceptedLocationPermissions(currentController : UIViewController){
        
    }
   
    func didFinishedAskingPermissions(currentController : UIViewController){
        hasAskedPermissions = true
        self.interactorDelegate?.haveFinishedFlow(sender: self)
        
    }

}
