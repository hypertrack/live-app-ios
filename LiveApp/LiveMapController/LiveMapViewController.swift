//
//  LiveMapViewController.swift
//  LiveApp
//
//  Created by Dmytro Shapovalov on 6/25/19.
//  Copyright © 2019 Dmytro Shapovalov. All rights reserved.
//

import UIKit
import HyperTrack
import MapKit
import CoreMotion
import CoreLocation

class LiveMapViewController: UIViewController {
    private var requestService: RequestService!
    private var trackingLink: URL?
    private var isFirstStart: Bool = true
    private let tipsView: HTTipsView = {
        let view = HTTipsView()
        view.isHidden = true
        return view
    }()
    private let notificationView: HTNotificationView = {
        let view = HTNotificationView()
        return view
    }()
    @objc private let map: MKMapView = {
        let map = MKMapView()
        map.tintColor = UIColor("#00CE5B")
        map.translatesAutoresizingMaskIntoConstraints = false
        map.showsCompass = false
        return map
    }()
    private let btCurrentUserPlace: HTButton = {
        let btn = HTButton(type:.custom)
        btn.clipsToBounds = true
        btn.setOnStateImage(
            normalImage: UIImage(named: "user_location_normal"),
            highlightedImage: UIImage(named: "user_location_selected"),
            disableImage: UIImage(named: "user_location_disable"))
        btn.currentState = .on
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(
            self,
            action: #selector(moveToUserDotHendler),
            for: .touchUpInside)
        return btn
    }()
    private let btChangeTrackingState: HTButton = {
        let btn = HTButton(type:.custom)
        btn.clipsToBounds = true
        btn.setOnStateImage(
            normalImage: UIImage(named: "tracking_on_normal"),
            highlightedImage: UIImage(named: "tracking_on_selected"),
            disableImage: UIImage(named: "tracking_on_disabled"))
        btn.setOffStateImage(
            normalImage: UIImage(named: "tracking_off_normal"),
            highlightedImage: UIImage(named: "tracking_off_selected"),
            disableImage: UIImage(named: "tracking_on_disabled"))
        btn.currentState = .off
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(
            self,
            action: #selector(changeTrackingStateHendler(_:)),
            for: .touchUpInside)
        return btn
    }()
    private let btShareLiveLocation: UIButton = {
        let btn = UIButton.baseGreen
        btn.setTitle(String.localize(key: "MAP_BUTTON_TITLE"),
                     for: .normal)
        btn.addTarget(
            self,
            action: #selector(shareUserLocationHendler(_ :)),
            for: .touchUpInside)
        return btn
    }()
    
    convenience init(appState: AppState) {
        self.init(nibName: nil, bundle: nil)
        self.requestService = RequestService(appState)
        configureController()
    }
    
    private func configureController() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(determineTrackingStateBehaviour),
            name: UIApplication.willEnterForegroundNotification,
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(determineTrackingStateBehaviour),
            name: NSNotification.Name.HyperTrackStartedTracking,
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(determineTrackingStateBehaviour),
            name: NSNotification.Name.HyperTrackStoppedTracking,
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(getHyperTrackError(_:)),
            name: Notification.Name.getErrorNotification,
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(hypertrackInitialized(_:)),
            name: Notification.Name.HyperTrackHasInitialized,
            object: nil)
        map.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        getTrackingLinkFromServer { [weak self] link in
            guard let link = link, let self = self else { return }
            self.trackingLink = link
        }
        createUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadHyperTrackInitialization()
    }
    
    @objc private func createUI() {
        
        self.navigationController?.navigationBar.isHidden = true
        
        view.backgroundColor = .white
        let viewContainer = UIView()
        viewContainer.backgroundColor = .white
        viewContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(map)
        view.addSubview(btChangeTrackingState)
        view.addSubview(viewContainer)
        viewContainer.addSubview(btShareLiveLocation)
        view.addSubview(btCurrentUserPlace)
        view.addSubview(notificationView)
        view.addSubview(tipsView)

        viewContainer.leftAnchor.constraint(equalTo:view.leftAnchor, constant: 0).isActive = true
        viewContainer.rightAnchor.constraint(equalTo:view.rightAnchor, constant: 0).isActive = true
        viewContainer.bottomAnchor.constraint(equalTo:view.bottomAnchor, constant: 0).isActive = true
        viewContainer.heightAnchor.constraint(equalToConstant: 90).isActive = true
        
        map.topAnchor.constraint(equalTo:view.topAnchor, constant: 0).isActive = true
        map.leftAnchor.constraint(
            equalTo:view.leftAnchor,
            constant: 0).isActive = true
        map.rightAnchor.constraint(
            equalTo:view.rightAnchor,
            constant: 0).isActive = true
        map.bottomAnchor.constraint(
            equalTo:view.bottomAnchor,
            constant: 0).isActive = true
        
        btChangeTrackingState.topAnchor.constraint(
            equalTo:view.safeAreaLayoutGuide.topAnchor,
            constant: 5).isActive = true
        btChangeTrackingState.rightAnchor.constraint(
            equalTo:view.rightAnchor,
            constant: -15).isActive = true
        
        tipsView.rightAnchor.constraint(
            equalTo:btChangeTrackingState.leftAnchor,
            constant: -10).isActive = true
        tipsView.centerYAnchor.constraint(
            equalTo: btChangeTrackingState.centerYAnchor).isActive = true
        
        btCurrentUserPlace.rightAnchor.constraint(
            equalTo:viewContainer.rightAnchor,
            constant: -15).isActive = true
        btCurrentUserPlace.bottomAnchor.constraint(
            equalTo:viewContainer.topAnchor,
            constant: -17).isActive = true
        
        btShareLiveLocation.bottomAnchor.constraint(
            equalTo:viewContainer.bottomAnchor,
            constant: -28).isActive = true
        btShareLiveLocation.leftAnchor.constraint(
            equalTo:viewContainer.leftAnchor,
            constant:28).isActive = true
        btShareLiveLocation.rightAnchor.constraint(
            equalTo:viewContainer.rightAnchor,
            constant:-28).isActive = true
        btShareLiveLocation.heightAnchor.constraint(
            equalToConstant: 40).isActive = true
        
        notificationView.leftAnchor.constraint(
            equalTo:view.leftAnchor,
            constant: 0).isActive = true
        notificationView.rightAnchor.constraint(
            equalTo:view.rightAnchor,
            constant: 0).isActive = true
        notificationView.bottomAnchor.constraint(
            equalTo:view.bottomAnchor,
            constant: -90).isActive = true
        
        determineTrackingStateBehaviour()
    }
    
    @objc private func determineTrackingStateBehaviour() {
        if HyperTrack.isTracking {
            map.showsUserLocation = true
            btShareLiveLocation.isEnabled = true
            btChangeTrackingState.currentState = .on
            notificationView.hideNotificationView()
            tipsView.hideTipsView()
        } else {
            btCurrentUserPlace.hide(false)
            map.showsUserLocation = false
            btShareLiveLocation.isEnabled = false
            btChangeTrackingState.currentState = .off
        }
    }
    
    private func showCurrentUserPlaceButtonIfNeeded() {
        if HyperTrack.isTracking,
            !map.isUserLocationVisible {
            btCurrentUserPlace.show(true)
        } else {
            btCurrentUserPlace.hide(true)
        }
    }
    
    @objc private func changeTrackingStateHendler(_ sender: HTButton) {
        if HyperTrack.isTracking {
            HyperTrack.stopTracking()
            NotificationCenter.default.post(
                name: Notification.Name.updateTrackingStateNotification,
                object: nil,
                userInfo: [userTrackingStateKey: false])
        } else {
            HyperTrack.startTracking()
            NotificationCenter.default.post(
                name: Notification.Name.updateTrackingStateNotification,
                object: nil,
                userInfo: [userTrackingStateKey: true])
        }
        
        if let userCoordinate = self.map.userLocation.location,
            !map.visibleMapRect.contains(MKMapPoint(userCoordinate.coordinate)),
            !self.isFirstStart {
            self.btCurrentUserPlace.show(true)
        }
    }
    
    // MARK: Map
    
    @objc private func moveToUserDotHendler() {
        btCurrentUserPlace.hide(true)
        map.setRegion(MKCoordinateRegion(
            center: map.userLocation.coordinate,
            latitudinalMeters: 400,
            longitudinalMeters: 400), animated: true)
    }
    
    // MARK: Tracking link
    
    @objc private func shareUserLocationHendler(_ sender: HTButton) {
        if let trackingLink = self.trackingLink {
            self.openShareActionSheet(link: trackingLink)
        } else {
            getTrackingLinkFromServer { [weak self] link in
                guard let link = link, let self = self else { return }
                self.trackingLink = link
                self.openShareActionSheet(link: link)
            }
        }
    }
    
    private func openShareActionSheet(link: URL) {
        let linkString = "\(NSLocalizedString("MAP_LINK_SHARING", comment: "")) \(link.absoluteString)"
        DispatchQueue.main.async {
            let actionSheet = UIActivityViewController(activityItems: [linkString],
                                                       applicationActivities: nil)
            actionSheet.excludedActivityTypes = [.saveToCameraRoll]
            self.present(actionSheet, animated: true, completion: nil)
        }
    }
    
    private func getTrackingLinkFromServer(completionHandler: @escaping (_ link: URL?) -> Void) {
        requestService.getSharedLink { link in
            guard let link = link else { return }
            completionHandler(link)
        }
    }
    
    // MARK: Error hendler
    
    @objc private func getHyperTrackError(_ notif: Notification) {
        determineTrackingStateBehaviour()
        guard let error = notif.userInfo?[errorKey] as? HyperTrackCriticalError else { return }
        switch error.type {
        case .criticalErrorPermissionDenied:
            notificationView.showNotificationView(errorText: NSLocalizedString("PERMISSIONS_ERROR_MESSAGE", comment: ""))
        case .criticalErrorAuthorizationError,
             .criticalErrorGeneralError,
             .criticalErrorInvalidPublishableKey:
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.displayError(error, alertTitle: "Error")
        @unknown default:
            fatalError()
        }
        tipsView.hideTipsView()
    }
    
    @objc private func hypertrackInitialized(_ notif: Notification) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if !HyperTrack.isTracking,
            let trackingState = appDelegate.appProvider?.appState.isTrackingStartedByUser,
            !trackingState {
            tipsView.showTipsView()
        } else {
            tipsView.hideTipsView()
        }
    }
    
    private func reloadHyperTrackInitialization() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.appProvider?.canSetupHyperTrack()
    }
}

extension LiveMapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView,
                 regionDidChangeAnimated
        animated: Bool) {
        showCurrentUserPlaceButtonIfNeeded()
    }
    
    // First time change Camera&Zoom to current user location
    func mapView(_ mapView: MKMapView,
                 didUpdate
        userLocation: MKUserLocation) {
        if isFirstStart {
            isFirstStart = false
            moveToUserDotHendler()
        }
    }
}
