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

    override func isFlowCompleted() -> Bool {
        return false
    }
    
    override func isFlowMandatory() -> Bool {
        return false
    }
    
    override func startFlow(force : Bool, presentingController:UIViewController){
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let acceptInviteController = storyboard.instantiateViewController(withIdentifier: "AcceptInviteVC") as! AcceptInviteVC
        acceptInviteController.inviteDelegate = self
        presentingController.present(acceptInviteController, animated: true, completion: nil)
    }
    
    override func getFlowPriority() -> Int {
        return -1
    }
}

extension InviteFlowController: HyperTrackInviteDelegate {
    func didSkipInvite(currentController: UIViewController) {
        self.interactorDelegate?.haveFinishedFlow(sender: self)
    }

    func didAcceptInvite(currentController: UIViewController) {
        self.interactorDelegate?.haveFinishedFlow(sender: self)
    }
}
