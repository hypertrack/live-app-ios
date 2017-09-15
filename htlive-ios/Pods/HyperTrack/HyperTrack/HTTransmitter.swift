//
//  HTTransmitter.swift
//  HyperTrack
//
//  Created by Tapan Pandita on 23/02/17.
//  Copyright © 2017 HyperTrack, Inc. All rights reserved.
//

import Foundation
import Alamofire
import MapKit
import CoreMotion

final class Transmitter {
    static let sharedInstance = Transmitter()
    var delegate:HyperTrackDelegate? = nil
    let locationManager:LocationManager
    let activityManager: HTActivityManager
    let mockLocationManager:MockLocationManager
    let requestManager: RequestManager
    let eventManager : EventsManager
    let deviceInfoService : HTDeviceInfoService
    var ttlTimer: Timer?
    
    var isTracking:Bool {
        get {
            return Settings.getTracking()
        }
    }
    
    var isMockTracking:Bool {
        get {
            return self.mockLocationManager.isTracking
        }
    }
    
    init() {
        self.locationManager = LocationManager()
        self.requestManager = RequestManager()
        self.mockLocationManager = MockLocationManager()
        self.deviceInfoService = HTDeviceInfoService()
        self.activityManager = HTActivityManager()
        self.eventManager = EventsManager()
        self.activityManager.activityEventDelegate = self.eventManager
        self.locationManager.locationEventsDelegate = self.eventManager

    }
    
    func initialize() {
        HTLogger.shared.info("Initialize transmitter")
        HTLogger.shared.postLogs()

        if self.isTracking {
            self.startTracking(completionHandler: nil)
        }
    }
    
    func sync() {
        let isTracking = Settings.getTracking()
        if isTracking {
            self.startTracking(completionHandler: nil)
        }
    }
    
  
    func getCurrentLocation(completionHandler: @escaping (_ currentLocation: CLLocation?,
                                                          _ error: HyperTrackError?) -> Void) {
        // Check location authorization status
        let authStatus: CLAuthorizationStatus = HyperTrack.locationAuthorizationStatus()
        if (authStatus != .authorizedAlways && authStatus != .authorizedWhenInUse) {
            let htError = HyperTrackError(HyperTrackErrorType.locationPermissionsError)
            HTLogger.shared.error("Error while getCurrentLocation: \(htError.errorMessage)")
            completionHandler(nil, htError)
            return
        }
        
        // Check location services status
        if (!HyperTrack.locationServicesEnabled()) {
            let htError = HyperTrackError(HyperTrackErrorType.locationDisabledError)
            HTLogger.shared.error("Error while getCurrentLocation: \(htError.errorMessage)")
            completionHandler(nil, htError)
            return
        }

        // Fetch current location from LocationManager
        let currentLocation = self.locationManager.getLastKnownLocation()
        if (currentLocation == nil) {
            let htError = HyperTrackError(HyperTrackErrorType.invalidLocationError)
            HTLogger.shared.error("Error while getCurrentLocation: \(htError.errorMessage)")
            completionHandler(nil, htError)
            
        } else {
            completionHandler(currentLocation, nil)
        }
    }
        
    func canStartTracking(completionHandler: ((_ error: HyperTrackError?) -> Void)?) -> Bool {
        // Allow Background Location updates
        self.locationManager.allowBackgroundLocationUpdates()
        
        if (Settings.getUserId() == nil) {
            HTLogger.shared.error("Can't start tracking. Need userId.")
            let error = HyperTrackError(HyperTrackErrorType.userIdError)
            delegate?.didFailWithError(error)
            
            guard let completionHandler = completionHandler else { return false }
            completionHandler(error)
            return false
        } else if (Settings.getPublishableKey() == nil) {
            HTLogger.shared.error("Can't start tracking. Need publishableKey.")
            let error = HyperTrackError(HyperTrackErrorType.publishableKeyError)
            delegate?.didFailWithError(error)
            
            guard let completionHandler = completionHandler else { return false }
            completionHandler(error)
            return false
        }
        
        return true
    }
    
    func startTracking(completionHandler: ((_ error: HyperTrackError?) -> Void)?) {
        if !canStartTracking(completionHandler: completionHandler) {
            return
        }
        
        if isMockTracking {
            // If mock tracking is active, the normal tracking flow will
            // not continue and throw an error.
            // TODO: better error message
            guard let completionHandler = completionHandler else { return }
            let error = HyperTrackError(HyperTrackErrorType.invalidParamsError)
            completionHandler(error)
            return
        }
        if !Settings.getTracking() {
            self.locationManager.requestLocation()
        }
        
        self.requestManager.startTimer()
        self.eventManager.startPassiveTrackingService()
        self.locationManager.startPassiveTrackingService()
        self.activityManager.startPassiveTrackingService()
        
        guard let completionHandler = completionHandler else { return }
        completionHandler(nil)
    }
    
    func startMockTracking(completionHandler: ((_ error: HyperTrackError?) -> Void)?) {
        if !canStartTracking(completionHandler: completionHandler) {
            return
        }
        
        if isTracking {
            // If tracking is active, the mock tracking will
            // not continue and throw an error.
            guard let completionHandler = completionHandler else { return }
            let error = HyperTrackError(HyperTrackErrorType.invalidParamsError)
            completionHandler(error)
            return
        }
        
        var originLatlng:String = ""
        
        if let location = locationManager.getLastKnownLocation() {
            originLatlng = "\(location.coordinate.latitude),\(location.coordinate.longitude)"
        } else {
            originLatlng = "28.556446,77.174095"
        }
        
        self.requestManager.getSimulatePolyline(originLatlng: originLatlng) { (polyline, error) in
            if let error = error {
                guard let completionHandler = completionHandler else { return }
                completionHandler(error)
                return
            }
            
            if let polyline = polyline {
                
                HTLogger.shared.info("Get simulated polyline successful")
                
                // Mock location manager maintains a request manager
                // and converts these locations into events
                let decoded = timedCoordinatesFrom(polyline: polyline)
                self.mockLocationManager.startService(coordinates: decoded!)
            }
        }
    }
    
    func stopMockTracking() {
        mockLocationManager.stopService()
    }
    
    func stopTracking(completionHandler: ((_ error: HyperTrackError?) -> Void)?) {
        self.eventManager.stopPassiveTrackingService()
        self.locationManager.stopPassiveTrackingService()
        self.activityManager.stopPassiveTrackingService()
        
        if (completionHandler != nil) {
            completionHandler!(nil)
        }
    }
    
    func refreshTransmitterWithControls(controls: HyperTrackSDKControls){
        if let ttl = controls.ttl {
            
            if ttl > 0 {
                // Handle ttl and set a timer that will
                // reset to defaults
                if (self.ttlTimer != nil) {
                    self.ttlTimer?.invalidate()
                }
                
                self.ttlTimer = Timer.scheduledTimer(timeInterval: Double(ttl),
                                                     target: self,
                                                     selector: #selector(self.resetTransmitter),
                                                     userInfo: nil,
                                                     repeats: false);
            }
        }

    }
    
        
    func refreshTransmitter() {
        // Get new controls and recreate transmitter timers
        let (batchDuration, minimumDisplacement) = HyperTrackSDKControls.getControls()
        HTLogger.shared.info("Set new transmitter controls, batch duration: \(String(describing: batchDuration)), displacement: \(String(describing: minimumDisplacement))")
        
        // TODO: abstract this for location manager and mock location manager
        locationManager.updateRequestTimer(batchDuration: batchDuration)
        locationManager.updateLocationManager(filterDistance: minimumDisplacement)
    }
    
    @objc func resetTransmitter() {
        // Reset transmitter to default controls
        // Clear controls from settings
        HTLogger.shared.info("Resetting transmitter controls as ttl is over")
        HyperTrackSDKControls.clearSavedControls()
        self.refreshTransmitter()
    }

        
    // Utility methods
    func requestWhenInUseAuthorization() {
        self.locationManager.requestWhenInUseAuthorization()
    }
    
    func requestAlwaysAuthorization() {
        self.locationManager.requestAlwaysAuthorization()
    }
    

    func requestAlwaysAuthorization(completionHandler: @escaping (_ isAuthorized: Bool) -> Void) {
        self.locationManager.requestAlwaysAuthorization(completionHandler:completionHandler)
    
    }

    func motionAuthorizationStatus(_ completionHandler: @escaping (_ isAuthorized: Bool) -> Void) {
        let coreMotionActivityManager = CMMotionActivityManager()
        let today: Date = Date()
        
        coreMotionActivityManager.queryActivityStarting(
            from: today, to: today, to: OperationQueue.main) { (activities, error) in
                if (error != nil) {
                    completionHandler(false)
                } else {
                    completionHandler(true)
                }
        }
    }
    
    func requestMotionAuthorization() {
        self.activityManager.requestMotionAuthorization()
    }
    
    func callDelegateWithEvent(event: HyperTrackEvent) {
        delegate?.didReceiveEvent(event)
    }
    
    func callDelegateWithError(error: HyperTrackError) {
        delegate?.didFailWithError(error)
    }
    
    func doesLocationBelongToRegion(stopLocation:HyperTrackLocation,radius:Int,identifier : String) -> LocationInRegion{
        return self.locationManager.doesLocationBelongToRegion(stopLocation:stopLocation,radius:radius,identifier:identifier)
    }
    
    func startMonitoringForEntryAtPlace(place: HyperTrackPlace, radius:CLLocationDistance, identifier: String){
        return self.locationManager.startMonitoringForEntryAtPlace(place:place,radius:radius,identifier:identifier)
    }
  
}

