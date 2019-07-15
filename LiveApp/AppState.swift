//
//  AppState.swift
//  LiveApp
//
//  Created by Dmytro Shapovalov on 6/28/19.
//  Copyright © 2019 Dmytro Shapovalov. All rights reserved.
//

import UIKit

let errorKey = "errorKey"
let notifyPublishableKey = "NotifyPublishableKey"
let userTrackingStateKey = "userTrackingStateKey"
let savedPublishableKey = "SaveHypertrackPK_Key"
let savedUserTrackingStateKey = "SaveUserTrackingStateKey"
let savedUserFlowStateKey = "SaveUserFlowStateKey"

class AppState {

    private(set) var pk_key: String?
    private(set) var isFlowComplited: Bool = false
    private(set) var isTrackingStartedByUser: Bool = false
    
    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updatePKey(_:)),
            name: Notification.Name.updatePKNotification,
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateUserTrackingState(_:)),
            name: Notification.Name.updateTrackingStateNotification,
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateFlowState),
            name: Notification.Name.flowComplitedNotification,
            object: nil)
        setupUserParams()
    }
    
    private func setupUserParams() {
        pk_key = UserDefaults.standard.string(forKey: savedPublishableKey)
        isTrackingStartedByUser = UserDefaults.standard.bool(forKey: savedUserTrackingStateKey)
        isFlowComplited = UserDefaults.standard.bool(forKey: savedUserFlowStateKey)
    }
    
    @objc private func updatePKey(_ notif: Notification) {
        guard let pk = notif.userInfo?[notifyPublishableKey] as? String else { return }
        pk_key = pk
        UserDefaults.standard.set(pk_key, forKey: savedPublishableKey)
    }
    
    @objc private func updateUserTrackingState(_ notif: Notification) {
        print("notif - \(notif)")
        guard let state = notif.userInfo?[userTrackingStateKey] as? Bool else { return }
        isTrackingStartedByUser = state
        print("isTrackingStartedByUser - \(isTrackingStartedByUser)")
        UserDefaults.standard.set(isTrackingStartedByUser, forKey: savedUserTrackingStateKey)
    }
    
    @objc private func updateFlowState() {
        isFlowComplited = true
        UserDefaults.standard.set(isFlowComplited, forKey: savedUserFlowStateKey)
    }
}
