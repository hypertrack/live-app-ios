//
//  OnboardingFlowController.swift
//  htlive-ios
//
//  Created by Ravi Jain on 7/14/17.
//  Copyright © 2017 PZRT. All rights reserved.
//

import UIKit

protocol OnboardingViewDelegate {
    func didSkipProfile()
    
    func didValidateCode()
}

class OnboardingFlowController: BaseFlowController, OnboardingViewDelegate {

    override func isFlowCompleted() -> Bool {
        return true
    }
    
    override func isFlowMandatory() -> Bool {
        return false
    }
    
    override func startFlow(force : Bool, presentingController:UIViewController) {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        var userProfileController = storyboard.instantiateViewController(withIdentifier: "UserProfileVC") as! UserProfileVC
        userProfileController.onboardingViewDelegate = self
        presentingController.present(userProfileController, animated:true, completion: nil)
        return
    }
    
    override func getFlowPriority() -> Int {
        return -1
    }
    
    func didSkipProfile() {
        //
    }

    func didValidateCode() {
        //
    }
}
