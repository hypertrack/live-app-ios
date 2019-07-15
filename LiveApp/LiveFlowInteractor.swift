//
//  LiveFlowInteractor.swift
//  LiveApp
//
//  Created by Dmytro Shapovalov on 6/25/19.
//  Copyright © 2019 Dmytro Shapovalov. All rights reserved.
//

import UIKit

protocol LiveFlowInteractorDelegate: class {
    func haveStartedFlow(sender: BaseFlowController)
    func haveFinishedFlow(sender: BaseFlowController)
}

class LiveFlowInteractor {
    
    private let appState: AppState
    private let welcomeViewController: WelcomeViewController
    private let pkVerifyViewController: PKVerifyViewController
    private let getPermissionsViewController: GetPermissionsViewController
    private var navigationController: HTNavigationController?
    private var flows = [BaseFlowController]()
    private var isPresentingFlow = false
    
    init(appState: AppState) {
        self.appState = appState
        self.welcomeViewController = WelcomeViewController()
        self.pkVerifyViewController = PKVerifyViewController(appState: self.appState)
        self.getPermissionsViewController = GetPermissionsViewController(appState: self.appState)
        initializeFlows()
    }
    
    func initializeFlows() {
        
        self.navigationController = UIApplication.shared.windows.first?.rootViewController as? HTNavigationController
        var flowlist = [BaseFlowController]()
        flowlist.append(welcomeViewController)
        flowlist.append(pkVerifyViewController)
        flowlist.append(getPermissionsViewController)
        flowlist.filter{ $0.isFlowCompleted() == false }
            .forEach{ appendController($0) }
        flows.first?.isAnimationNeeded = false
    }
    
    private func appendController(_ controller: BaseFlowController) {
        controller.interactorDelegate = self
        flows.append(controller)
    }
    
    func presentFlowsIfNeeded() {
        if !appState.isFlowComplited, !isPresentingFlow {
            for flowController in self.flows {
                if !flowController.isFlowCompleted() {
                    self.navigationController?.pushViewController(flowController,
                                                                  animated: flowController.isAnimationNeeded)
                    isPresentingFlow = true
                    break
                }
            }
        }
        if appState.isFlowComplited || flows.count == 0  {
            self.navigationController?.setViewControllers([LiveMapViewController(appState: appState)], animated: true)
        }
    }
}

extension LiveFlowInteractor: LiveFlowInteractorDelegate {
    func haveStartedFlow(sender: BaseFlowController) {
        
    }
    
    func haveFinishedFlow(sender: BaseFlowController) {
        isPresentingFlow = false
        guard let index =  flows.firstIndex(of: sender) else {
            return
        }
        flows.remove(at: index)
        presentFlowsIfNeeded()
    }
}
