//
//  BaseFlowController.swift
//  LiveApp
//
//  Created by Dmytro Shapovalov on 6/26/19.
//  Copyright © 2019 Dmytro Shapovalov. All rights reserved.
//

import UIKit

class BaseFlowController: UIViewController {

    var interactorDelegate: LiveFlowInteractorDelegate? = nil
    var isAnimationNeeded: Bool = true
    
    func isFlowCompleted() -> Bool {
        return true
    }
}
