//
//  InviteFlowController.swift
//  htlive-ios
//
//  Created by Ravi Jain on 7/14/17.
//  Copyright © 2017 PZRT. All rights reserved.
//

import UIKit
import HyperTrack
protocol HyperTrackInviteDelegate {
    func didAcceptInvite(currentController : UIViewController)
    func didSkipInvite(currentController : UIViewController)
}

class InviteFlowController: BaseFlowController {
    
    var acccountId : String?
    var autoAccept = false

    var hasCompletedFlow  = false

    override func isFlowCompleted() -> Bool {
        if(hasCompletedFlow){
            return true
        }
        
        if( acccountId != nil){
            return false
        }
        return true
    }
    
    override func isFlowMandatory() -> Bool {
        return false
    }
    
    override func startFlow(force : Bool, presentingController:UIViewController?){
        
        if (autoAccept == true){
            RequestService.shared.acceptHyperTrackInvite(accountId: self.acccountId!, completionHandler: { (error) in
            })
            self.hasCompletedFlow = true
            self.interactorDelegate?.haveFinishedFlow(sender: self)

        }
        else{
            hasCompletedFlow = true
            self.interactorDelegate?.haveFinishedFlow(sender: self)
        }
    }
    
    override func getFlowPriority() -> Int {
        return -1
    }
}

extension InviteFlowController: HyperTrackInviteDelegate {
    func didSkipInvite(currentController: UIViewController) {
        hasCompletedFlow = true
        self.interactorDelegate?.haveFinishedFlow(sender: self)
    }

    func didAcceptInvite(currentController: UIViewController) {
        hasCompletedFlow = true
        self.interactorDelegate?.haveFinishedFlow(sender: self)
    }
}
