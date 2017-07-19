//
//  HyperTrackFlowInteractor.swift
//  htlive-ios
//
//  Created by Ravi Jain on 7/14/17.
//  Copyright © 2017 PZRT. All rights reserved.
//

import UIKit

protocol HyperTrackFlowInteractorDelegate {
    func haveStartedFlow(sender: BaseFlowController)
    
    func haveFinishedFlow(sender: BaseFlowController)
}

class HyperTrackFlowInteractor: NSObject, HyperTrackFlowInteractorDelegate {
    
    let onboardingFlowController = OnboardingFlowController()
    let permissionFlowController = PermissionsFlowController()
    let inviteFlowController = InviteFlowController()
    
    var flows = [BaseFlowController]()

    override init() {
        super.init()
        initializeFlows()
    }
    
    func initializeFlows(){
        appendController(permissionFlowController)
        appendController(onboardingFlowController)
        appendController(inviteFlowController)
    }
    
    func appendController(_ controller: BaseFlowController) {
        controller.interactorDelegate = self
        flows.append(controller)
    }
    
    func presentFlowsIfNeeded(){
            for flowController in self.flows{
                if(!flowController.isFlowCompleted()){
                    flowController.startFlow(force: false, presentingController: HyperTrackFlowInteractor.topViewController()!)
                    break
                }
            }
    }
    
     static func topViewController() -> UIViewController? {
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
    
   func presentLiveLocationFlow(shortCode : String){
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let liveLocationController = storyboard.instantiateViewController(withIdentifier: "ShareVC") as! ShareVC
        liveLocationController.shortCode = shortCode
        HyperTrackFlowInteractor.topViewController()?.present(liveLocationController, animated:true, completion: nil)
    }
    
    func haveStartedFlow(sender: BaseFlowController) {
        //
    }

    func haveFinishedFlow(sender: BaseFlowController) {
        //
        presentFlowsIfNeeded()
    }
}
