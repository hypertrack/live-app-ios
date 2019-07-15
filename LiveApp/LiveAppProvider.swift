//
//  LiveAppService.swift
//  LiveApp
//
//  Created by Dmytro Shapovalov on 6/26/19.
//  Copyright © 2019 Dmytro Shapovalov. All rights reserved.
//

import UIKit
import HyperTrack

class LiveAppProvider: NSObject {
    let appState: AppState!
    let flowInteractor: LiveFlowInteractor!
    
    override init() {
        self.appState = AppState()
        self.flowInteractor = LiveFlowInteractor(appState: appState)
        super.init()
    }
    
    func setUp() {
        flowInteractor.presentFlowsIfNeeded()
        canSetupHyperTrack()
    }
}

extension LiveAppProvider {
    
    public func canSetupHyperTrack() {
        canSetupHyperTrack(appState.pk_key ?? "",
                           appState.isTrackingStartedByUser,
                           appState.isTrackingStartedByUser)
    }
    
    public func canSetupHyperTrack(_ pk: String,
                                   _ startsTracking: Bool,
                                   _ requestsPermissions: Bool) {
        if !pk.isEmpty {
            HyperTrack.initialize(
                publishableKey: pk,
                delegate: self,
                startsTracking: startsTracking,
                requestsPermissions: requestsPermissions)
        }
    }
}

extension LiveAppProvider: HyperTrackDelegate {
    func hyperTrack(_ hyperTrack: AnyClass,
                    didEncounterCriticalError
        criticalError: HyperTrackCriticalError) {
        NotificationCenter.default.post(
            name: Notification.Name.getErrorNotification,
            object: nil,
            userInfo: [errorKey: criticalError])
    }
}
