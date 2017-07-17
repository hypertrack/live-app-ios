//
//  RequestPermissionsVC.swift
//  htlive-ios
//
//  Created by Piyush on 17/07/17.
//  Copyright © 2017 PZRT. All rights reserved.
//

import Foundation
import HyperTrack

class RequestPermissionsVC : UIViewController {
    
    @IBOutlet weak var radiationCircle: UIImageView!
    @IBOutlet weak var requestLocationDescriptionLabel: UILabel!
    @IBOutlet weak var enableLocationCTAButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.radiate()
        // Do any additional setup after loading the view.
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
    
    private func checkForLocationSettings() {
        // Check for Location Authorization Status (Always by default)
        if (HyperTrack.locationAuthorizationStatus() != .authorizedAlways) {
            HyperTrack.requestAlwaysAuthorization()
            return
        }
        
        // TODO Add motionAuthorizationStatus() API in HyperTrack SDK
        
        // Check for Motion Authorization Status
        // if (HyperTrack.motionAuthorizationStatus()) {
        //    HyperTrack.requestMotionAuthorization()
        //    return
        // }
        
        // Check if Location Services are enabled
        if (HyperTrack.locationServicesEnabled()) {
            // TODO Add API to requestLocationServices in HyperTrack SDK
            return
        }
        
        // TODO Proceed further if all required settings are enabled
    }
    
    func radiate() {
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
