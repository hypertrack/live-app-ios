//
//  HyperTrackFlowInteractor.swift
//  htlive-ios
//
//  Created by Ravi Jain on 7/14/17.
//  Copyright © 2017 PZRT. All rights reserved.
//

import UIKit
import UserNotifications

protocol HyperTrackFlowInteractorDelegate {
    func haveStartedFlow(sender: BaseFlowController)
    
    func haveFinishedFlow(sender: BaseFlowController)
}

class HyperTrackFlowInteractor: NSObject, HyperTrackFlowInteractorDelegate {
    
    let onboardingFlowController = OnboardingFlowController()
    let permissionFlowController = PermissionsFlowController()
    let inviteFlowController = InviteFlowController()
    
    var liveLocationViewControllers  = [ShareVC]()
    
    
    var flows = [BaseFlowController]()
    
    var isPresentingAFlow = false
    
    override init() {
        super.init()
        initializeFlows()
    }
    
    func initializeFlows(){
        appendController(permissionFlowController)
        appendController(onboardingFlowController)
    }
    
    func appendController(_ controller: BaseFlowController) {
        controller.interactorDelegate = self
        flows.append(controller)
    }
    
    func presentFlowsIfNeeded(){
        if(!isPresentingAFlow){
            for flowController in self.flows{
                if(!flowController.isFlowCompleted()){
                    flowController.startFlow(force: false, presentingController: HyperTrackFlowInteractor.topViewController())
                    isPresentingAFlow = true
                    break
                }
            }
        }
        
        if (!isPresentingAFlow){
            let center = UNUserNotificationCenter.current()
            let options: UNAuthorizationOptions = [.alert, .sound, .badge];
            center.requestAuthorization(options: options) {
                (granted, error) in
                if !granted {
                    print("Something went wrong")
                }
            }
            
            let defaultRoot = HyperTrackAppService.sharedInstance.getDefaultRootViewController()
            
            if !(HyperTrackAppService.sharedInstance.getCurrentRootViewController()?.isKind(of:type(of: defaultRoot)))!{
                HyperTrackFlowInteractor.switchRootViewController(rootViewController: defaultRoot, animated: false, completion: nil)
            }
            
            var date = DateComponents()
            date.hour = 21
            date.minute = 05
//            self.scheduleLocalNotification(titleOfNotification: "Review your activities", subtitleOfNotification: "Please review today's activities and give feedback", messageOfNotification: "", soundOfNotification: "", dateComponent: date)
        }
    }
    
    
    
    let requestIdentifier = "ReviewPlaceline"
    
    internal func scheduleLocalNotification(titleOfNotification:String, subtitleOfNotification:String, messageOfNotification:String, soundOfNotification:String, dateComponent:DateComponents) {
        
        if #available(iOS 10.0, *) {
            
            
            let content = UNMutableNotificationContent()
            content.title = titleOfNotification
            content.body = NSString.localizedUserNotificationString(forKey: subtitleOfNotification, arguments: nil)
            
            let trigger = UNCalendarNotificationTrigger.init(dateMatching: dateComponent, repeats: false)
            
            let request = UNNotificationRequest(identifier:requestIdentifier, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request){(error) in
                
                if (error != nil){
                    
                    print(error?.localizedDescription)
                } else {
                    print("Successfully Done")
                }
            }
        } else {
            // Fallback on earlier versions
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
    
    
    static func switchRootViewController(rootViewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
        
        let window = UIApplication.shared.windows.first
        if animated {
            UIView.transition(with: window!, duration: 0.5, options: .transitionCrossDissolve, animations: {
                let oldState: Bool = UIView.areAnimationsEnabled
                UIView.setAnimationsEnabled(false)
                window!.rootViewController = rootViewController
                UIView.setAnimationsEnabled(oldState)
            }, completion: { (finished: Bool) -> () in
                if (completion != nil) {
                    completion!()
                }
            })
        } else {
            window!.rootViewController = rootViewController
        }
    }

    
    func presentDeeplinkFlow(){
        
    }
    
    func acceptInvitation(_ accountId: String){
        inviteFlowController.acccountId = accountId
        inviteFlowController.autoAccept = true
        appendController(inviteFlowController)
        presentFlowsIfNeeded()
    }
    
    func addAcceptInviteFlow(_ userId: String, _ accountId: String, _ accountName: String){
        inviteFlowController.acccountId = accountId
        appendController(inviteFlowController)
        presentFlowsIfNeeded()
    }
    
    func presentLiveLocationFlow(shortCode : String){
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let liveLocationController = storyboard.instantiateViewController(withIdentifier: "ShareVC") as! ShareVC
        liveLocationController.shortCode = shortCode
        HyperTrackFlowInteractor.topViewController()?.present(liveLocationController, animated:true, completion: nil)
    }
    
    func presentLiveLocationFlow(lookUpId : String,shortCode: String){
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let liveLocationController = storyboard.instantiateViewController(withIdentifier: "ShareVC") as! ShareVC
        liveLocationController.lookupId = lookUpId
        liveLocationController.shortCode = shortCode
        HyperTrackFlowInteractor.topViewController()?.present(liveLocationController, animated:true, completion: nil)
    }
    
    
    func presentReviewPlaceLineView(){
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)

        let activityFeedbackVC = storyboard.instantiateViewController(withIdentifier: "ActivityFeedbackTableVC") as! ActivityFeedbackTableVC
        let navVC = UINavigationController.init(rootViewController: activityFeedbackVC)
        HyperTrackFlowInteractor.topViewController()?.present(navVC, animated: true, completion: nil)
    }
    
    func haveStartedFlow(sender: BaseFlowController) {
        //
    }
    
    func haveFinishedFlow(sender: BaseFlowController) {
        isPresentingAFlow = false
        let index =  flows.index(of: sender)
        flows.remove(at: index!)
        presentFlowsIfNeeded()
    }
}
