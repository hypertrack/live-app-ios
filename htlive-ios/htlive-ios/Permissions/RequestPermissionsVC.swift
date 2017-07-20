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

class RequestPermissionsVC : UIViewController {
    
    @IBOutlet weak var radiationCircle: UIImageView!
    @IBOutlet weak var requestLocationDescriptionLabel: UILabel!
    @IBOutlet weak var enableLocationCTAButton: UIButton!
    
    var permissionDelegate:PermissionsDelegate? = nil

    var pollingTimer: Timer?
    var currentTimerHit = 0

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.radiate()
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
            HyperTrack.requestAlwaysAuthorization(completionHandler: { (isAuthorized) in
                if(isAuthorized){
                  self.permissionDelegate?.didAcceptedLocationPermissions(currentController: self)
                }else{
                    self.permissionDelegate?.didDeniedLocationPermissions(currentController: self)
                }
                
                if(HyperTrack.canAskMotionPermissions()){
                    HyperTrack.requestMotionAuthorization()
                    self.initializeTimer()

                }else{
                    
                    self.dismissViewController()
                
                }
            })
        }
    }
    
    func dismissViewController (){
        self.dismiss(animated: false, completion: {
            self.permissionDelegate?.didFinishedAskingPermissions(currentController: self)
        })
    }
    
    private func initializeTimer() {
        pollingTimer = Timer.scheduledTimer(timeInterval: 1,
                                            target: self, selector: #selector(checkForMotionPermission),
                                            userInfo: nil, repeats: true)
    }
    
    @objc private func checkForMotionPermission() {
        currentTimerHit += 1
        if(currentTimerHit == 5){
            pollingTimer?.invalidate()
            self.dismissViewController()
            return
        }
        else{
            HyperTrack.motionAuthorizationStatus(completionHandler: { (authorized) in
                if(authorized){
                    self.pollingTimer?.invalidate()
                    self.dismissViewController()
                }
            })
        }
    }
    
    private func radiate() {
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(0), execute: {
            UIView.animate(withDuration: 2, delay: 0, options: [.repeat], animations: {
                self.radiationCircle.transform = CGAffineTransform(scaleX: 80, y: 80)
                self.radiationCircle.alpha = 0
            }, completion: { (hello) in
                self.radiationCircle.alpha = 1
                self.radiationCircle.transform = CGAffineTransform(scaleX: 0, y: 0)
            })
        })
    }
}
