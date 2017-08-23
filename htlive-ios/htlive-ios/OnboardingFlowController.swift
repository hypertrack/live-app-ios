//
//  OnboardingFlowController.swift
//  htlive-ios
//
//  Created by Ravi Jain on 7/14/17.
//  Copyright © 2017 PZRT. All rights reserved.
//

import UIKit
import HyperTrack

protocol OnboardingViewDelegate {
    func didSkipProfile(currentController : UIViewController)
    func didCreatedUser(user: HyperTrackUser,currentController : UIViewController)
    func willGoToValidateCode(currentController : UIViewController, presentController: ValidateCodeVC)
    func didValidateCode(currentController : UIViewController)
}

enum OnboardingState: Int {
    
    case OnboardingNotStarted = 0
    case OnboardingSkipped = 1
    case OnboardingCompleted = 2
    
}

let onboardingStateKey = "onboardingStateKey"

class OnboardingFlowController: BaseFlowController, OnboardingViewDelegate {

    
    var currentOnboardingState : OnboardingState
    
    override init() {
        currentOnboardingState = OnboardingState(rawValue: UserDefaults.standard.integer(forKey: onboardingStateKey))!
        super.init()
    }
    
    
    override func isFlowCompleted() -> Bool {
        
        if( HyperTrack.getUserId() == nil){
            currentOnboardingState = OnboardingState.OnboardingNotStarted
            UserDefaults.standard.set(OnboardingState.OnboardingNotStarted.rawValue, forKey: onboardingStateKey)
            return false
        }
       
        if(currentOnboardingState == OnboardingState.OnboardingSkipped || currentOnboardingState == OnboardingState.OnboardingCompleted ){
                return true
        }
        return false
    }
    
    override func isFlowMandatory() -> Bool {
        return false
    }
    
    override func startFlow(force : Bool, presentingController:UIViewController) {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let userProfileController = storyboard.instantiateViewController(withIdentifier: "UserProfileVC") as! UserProfileVC
        userProfileController.onboardingViewDelegate = self
        presentingController.present(userProfileController, animated:false, completion: nil)
        return
    }
    
    override func getFlowPriority() -> Int {
        return -1
    }
    
    func didSkipProfile(currentController : UIViewController){
        // This method is called from the user profile screen
        // whenever the profile was skipped or phone number
        // was not entered.
        
        UserDefaults.standard.set(OnboardingState.OnboardingSkipped.rawValue, forKey: onboardingStateKey)
        currentController.dismiss(animated: false) {
            self.interactorDelegate?.haveFinishedFlow(sender: self)
        }

    }
    
    func didCreatedUser(user: HyperTrackUser,currentController : UIViewController){
        let nc = NotificationCenter.default
        nc.post(name:Notification.Name(rawValue:HTLiveConstants.userCreatedNotification),
                object: nil,
                userInfo: nil)

    }
    
    func didValidateCode(currentController : UIViewController){
        // This method is called when we have successfully validated
        // the phone number on the validate code screen.
        UserDefaults.standard.set(OnboardingState.OnboardingCompleted.rawValue, forKey: onboardingStateKey)
        currentOnboardingState = OnboardingState.OnboardingCompleted
        currentController.presentingViewController?.presentingViewController?.dismiss(animated: false) {
            self.interactorDelegate?.haveFinishedFlow(sender: self)
        }
    }
    
    func willGoToValidateCode(currentController : UIViewController , presentController: ValidateCodeVC){
        
       
    }
   
}
