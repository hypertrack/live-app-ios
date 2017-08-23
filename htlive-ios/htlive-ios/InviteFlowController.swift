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
    
    
    var userId : String?
    var acccountId : String?
    var accountName : String?
    var autoAccept = false

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
        
        if (autoAccept == true){
            let oldUserId = HyperTrack.getUserId()
            HyperTrack.setUserId(userId!)
            
            if(oldUserId != userId){
                HyperTrack.stopTracking()
                HyperTrack.startTracking()
            }
            RequestService.shared.acceptHyperTrackInvite(accountId: self.acccountId!, oldUserId: oldUserId
            , completionHandler: { (error) in

            })
            
            self.interactorDelegate?.haveFinishedFlow(sender: self)

        }
        else{
            let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            let acceptInviteController = storyboard.instantiateViewController(withIdentifier: "AcceptInviteVC") as! AcceptInviteVC
            acceptInviteController.inviteDelegate = self
            acceptInviteController.accountName = accountName
            acceptInviteController.accountId = acccountId
            acceptInviteController.userId = userId
            presentingController.present(acceptInviteController, animated: true, completion: nil)

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
