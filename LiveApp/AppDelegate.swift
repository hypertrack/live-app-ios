//
//  AppDelegate.swift
//  LiveApp
//
//  Created by Dmytro Shapovalov on 6/25/19.
//  Copyright © 2019 Dmytro Shapovalov. All rights reserved.
//

import UIKit
import HyperTrack

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var appProvider: LiveAppProvider?
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
        ) -> Bool {
        
        window = UIWindow(frame:UIScreen.main.bounds)
        window?.makeKeyAndVisible()
        window?.rootViewController = HTNavigationController()
        appProvider = LiveAppProvider()
        appProvider?.setUp()
        
        HyperTrack.registerForRemoteNotifications()
        
        return true
    }
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken
        deviceToken: Data
        ) {
        HyperTrack.didRegisterForRemoteNotificationsWithDeviceToken(deviceToken)
    }
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError
        error: Error) {
        HyperTrack.didFailToRegisterForRemoteNotificationsWithError(error)
    }
    
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler:
        @escaping (UIBackgroundFetchResult) -> Void
        ) {
        HyperTrack.didReceiveRemoteNotification(userInfo,
                                                fetchCompletionHandler: completionHandler)
    }
    
    /// For this simple example we display alerts with an ability to try to start tracking again.
    func displayError(_ error: HyperTrackCriticalError, alertTitle: String) {
        guard let window = self.window,
            let viewController = window.rootViewController else { return }
        let alert = UIAlertController(
            title: NSLocalizedString(alertTitle, comment: ""),
            message: NSLocalizedString(error.errorMessage, comment: ""),
            preferredStyle: .alert)
        alert.addAction(
            UIAlertAction(title: NSLocalizedString("ALERT_OK_BUTTON", comment: ""), style: .cancel, handler: nil)
        )
        viewController.present(alert, animated: true, completion: nil)
    }
}

extension Notification.Name {
    static let updatePKNotification = Notification.Name("HyperTrackUpdatePK")
    static let updateTrackingStateNotification = Notification.Name("HyperTrackUpdateTrackingState")
    static let flowComplitedNotification = Notification.Name("HyperTrackFlowComplited")
    static let getErrorNotification = Notification.Name("HyperTrackGetErrorNotification")
}
