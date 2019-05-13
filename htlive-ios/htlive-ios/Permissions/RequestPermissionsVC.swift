//
//  RequestPermissionsVC.swift
//  htlive-ios
//
//  Created by Piyush on 17/07/17.
//  Copyright © 2017 PZRT. All rights reserved.
//

import Foundation
import HyperTrack
import CoreLocation
import HyperTrackV3

class RequestPermissionsVC : UIViewController {
    @IBOutlet weak var requestLocationDescriptionLabel: UILabel!
    @IBOutlet weak var enableLocationCTAButton: UIButton!
    
    var permissionDelegate:PermissionsDelegate? = nil
    
    var pollingTimer: Timer?
    var currentTimerHit = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(self.onForegroundNotification), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        self.requestLocationDescriptionLabel.text = "HyperTrack live app needs location permission to track your location."

        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if (HyperTrack.locationAuthorizationStatus() == .denied) {
            changeToSettingsCTAButton()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didTapEnableLocationButton(_ sender: Any) {
        // Handle tap enable location button (request authorization
        // and location services)
        self.checkForLocationSettings()
    }
    
    func checkForLocationSettings() {
        // Check if Location Services are enabled
        if (!HyperTrack.locationServicesEnabled()) {
            HyperTrack.requestLocationServices()
            return
        }
        
        // Check for Location Authorization Status (Always by default)
        if (HyperTrack.locationAuthorizationStatus() != .authorizedAlways) {
            HyperTrack.requestAlwaysLocationAuthorization(completionHandler: { (isAuthorized) in
                if(isAuthorized) {
                    self.permissionDelegate?.didAcceptedLocationPermissions(currentController: self)
                    
                    if(HyperTrack.isActivityAvailable()){
                        HyperTrack.requestMotionAuthorization()
                        self.initializeTimer()
                        
                    }else{
                        self.dismissViewController()
                    }
                    
                    HyperTrackV3.startTracking(requestsPermissions: true)
                    
                }else{
                    self.permissionDelegate?.didDeniedLocationPermissions(currentController: self)
                    
                    
                    self.requestLocationDescriptionLabel.text = "Please give 'Always' location permission from Settings."

                    self.changeToSettingsCTAButton()
                }
          
            })
        }else if (HyperTrack.locationAuthorizationStatus() == .authorizedAlways){
           
            if(HyperTrack.isActivityAvailable()){
                HyperTrack.requestMotionAuthorization()
                self.initializeTimer()
                
            }else{
                self.dismissViewController()
            }
            
            HyperTrackV3.startTracking(requestsPermissions: true)
        }
    }
    
    @objc func onForegroundNotification(_ notification: Notification){
        if (HyperTrack.locationAuthorizationStatus() == .authorizedAlways) {
            changeToEnablePermissions()
            if(HyperTrack.isActivityAvailable()){
                HyperTrack.requestMotionAuthorization()
                self.initializeTimer()
                
            }else{
                self.dismissViewController()
            }
        }
    }
    
    @IBAction func didTapGoToSettings(_ sender: Any) {
        UIApplication.shared.open(URL(string:UIApplication.openSettingsURLString)!)
    }
    
    func changeToSettingsCTAButton(){
        
        self.requestLocationDescriptionLabel.text = "HyperTrack live app needs location permission to track your location.\nPlease give 'Always' location permission from Settings."

        self.enableLocationCTAButton.setTitle("Open Settings", for: UIControl.State.normal)
        self.enableLocationCTAButton.removeTarget(self, action: #selector(didTapEnableLocationButton(_:)), for: UIControl.Event.touchUpInside)
        self.enableLocationCTAButton.addTarget(self, action: #selector(didTapGoToSettings(_:)), for: UIControl.Event.touchUpInside)
    }
    
    
    func changeToEnablePermissions(){
        
        self.requestLocationDescriptionLabel.text = "HyperTrack live app needs location permission to track your location."
        
        self.enableLocationCTAButton.setTitle("Allow Access", for: UIControl.State.normal)
        self.enableLocationCTAButton.removeTarget(self, action: #selector(didTapGoToSettings(_:)), for: UIControl.Event.touchUpInside)
        self.enableLocationCTAButton.addTarget(self, action: #selector(didTapEnableLocationButton(_:)), for: UIControl.Event.touchUpInside)

    }
    
    
    func dismissViewController (){
        self.permissionDelegate?.didFinishedAskingPermissions(currentController: self)
    }
    
    private func initializeTimer() {
        pollingTimer = Timer.scheduledTimer(timeInterval: 1,
                                            target: self, selector: #selector(checkForMotionPermission),
                                            userInfo: nil, repeats: false)
    }
    
    @objc private func checkForMotionPermission() {
        currentTimerHit += 1
        if currentTimerHit >= 10 {
            pollingTimer?.invalidate()
            pollingTimer = nil
            self.dismissViewController()
            return
        } else {
            HyperTrack.motionAuthorizationStatus(completionHandler: { [weak self] (authorized) in
                if authorized {
                    self?.pollingTimer?.invalidate()
                    self?.pollingTimer = nil
                    self?.dismissViewController()
                } else {
                    self?.initializeTimer()
                }
            })
        }
    }
}
