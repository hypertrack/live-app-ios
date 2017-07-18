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
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        self.requestLocationDescriptionLabel.isHidden = true
        self.enableLocationCTAButton.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.radiate()
        
        if (HyperTrack.locationServicesEnabled() && HyperTrack.locationAuthorizationStatus() == .authorizedAlways) {
            self.proceedToNextScreen()
            return
        }
        
        self.requestLocationDescriptionLabel.isHidden = false
        self.enableLocationCTAButton.isHidden = false
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
        
        // Request Motion Authorization Status
        HyperTrack.requestMotionAuthorization()
        
        // Check for Location Authorization Status (Always by default)
        if (HyperTrack.locationAuthorizationStatus() != .authorizedAlways) {
            HyperTrack.requestAlwaysAuthorization()
        }
        
        self.proceedToNextScreen()
    }
    
    private func proceedToNextScreen() {
        // Proceed further depending on if the user is signed up or not
        if (HyperTrack.getUserId() != nil) {
            let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            let placelineController = storyboard.instantiateViewController(withIdentifier: "PlacelineVC") as! ViewController
            self.present(placelineController, animated: true, completion: nil)
            
        } else {
            let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            let profileController = storyboard.instantiateViewController(withIdentifier: "UserProfileVC") as! UserProfileVC
            self.present(profileController, animated: true, completion: nil)
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
