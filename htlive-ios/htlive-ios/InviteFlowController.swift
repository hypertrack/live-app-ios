//
//  InviteFlowController.swift
//  htlive-ios
//
//  Created by Ravi Jain on 7/14/17.
//  Copyright © 2017 PZRT. All rights reserved.
//

import UIKit

protocol HyperTrackInviteDelegate {
    func didAcceptInvite(currentController : UIViewController)
    func didSkipInvite(currentController : UIViewController)
}

class InviteFlowController: BaseFlowController {
    
    
    var userId : String?
    var acccountId : String?
    var accountName : String?

    var hasCompletedFlow  = false

    override func isFlowCompleted() -> Bool {
        if(hasCompletedFlow){
            return true
        }
        
        if(userId != nil && accountName != nil && acccountId != nil){
            return false
        }
        return true
    }
    
    override func isFlowMandatory() -> Bool {
        return false
    }
    
    override func startFlow(force : Bool, presentingController:UIViewController){
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let acceptInviteController = storyboard.instantiateViewController(withIdentifier: "AcceptInviteVC") as! AcceptInviteVC
        acceptInviteController.inviteDelegate = self
        acceptInviteController.accountName = accountName
        acceptInviteController.accountId = acccountId
        acceptInviteController.userId = userId
        presentingController.present(acceptInviteController, animated: true, completion: nil)
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
