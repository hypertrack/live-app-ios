//
//  BaseFlowController.swift
//  htlive-ios
//
//  Created by Ravi Jain on 7/14/17.
//  Copyright © 2017 PZRT. All rights reserved.
//

import UIKit

class BaseFlowController: NSObject {
    
    var interactorDelegate: HyperTrackFlowInteractorDelegate? = nil
    
    func isFlowCompleted() -> Bool {
        return true
    }
    
    func isFlowMandatory() -> Bool {
        return false
    }
    
    func startFlow(force : Bool, presentingController:UIViewController){
        return
    }
    
    func getFlowPriority() -> Int {
        return -1
    }
}
