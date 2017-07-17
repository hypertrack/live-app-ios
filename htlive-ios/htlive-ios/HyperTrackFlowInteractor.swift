//
//  HyperTrackFlowInteractor.swift
//  htlive-ios
//
//  Created by Ravi Jain on 7/14/17.
//  Copyright © 2017 PZRT. All rights reserved.
//

import UIKit

class HyperTrackFlowInteractor: NSObject {
    
    let onboardingFlowController = OnboardingFlowController()
    let permissionFlowController = PermissionsFlowController()
    let inviteFlowController = InviteFlowController()
    
    var flows = [BaseFlowController]()

    override init() {
        super.init()
        initializeFlows()
    }
   
    
    func initializeFlows(){
        flows.append(onboardingFlowController)
        flows.append(permissionFlowController)
        flows.append(inviteFlowController)
    }
    
    
    func presentFlowsIfNeeded(){
        for flowController in flows{
            if(!flowController.isFlowCompleted()){
                flowController.startFlow(force: false, presentingController: topViewController()!)
            }
        }
    }
    
    
    
    func topViewController() -> UIViewController? {
        var top = UIApplication.shared.keyWindow?.rootViewController
        while true {
            if let presented = top?.presentedViewController {
                top = presented
            } else if let nav = top as? UINavigationController {
                top = nav.visibleViewController
            } else if let tab = top as? UITabBarController {
                top = tab.selectedViewController
            } else {
                break
            }
        }
        return top
    }
    
    
    func showAcceptInviteFlow(){
        
        
    }
    
    
    func presentDeeplinkFlow(){
        
    }

}
