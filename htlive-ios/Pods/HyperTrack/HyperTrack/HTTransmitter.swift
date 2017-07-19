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
    let mockLocationManager:MockLocationManager

    let requestManager: RequestManager
    let deviceInfoService : HTDeviceInfoService
    var ttlTimer: Timer?
    
    var isTracking:Bool {
        get {
            return self.locationManager.isTracking
        }
    }
    
    var isMockTracking:Bool {
        get {
            return self.mockLocationManager.isTracking
        }
    }
    
    init() {
        self.locationManager = LocationManager()
        EventsDatabaseManager.sharedInstance.createEventsTable()
        self.requestManager = RequestManager()
        self.mockLocationManager = MockLocationManager()
        self.deviceInfoService = HTDeviceInfoService()
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
    
    func setUserId(userId:String) {
        Settings.setUserId(userId: userId)
        PushNotificationService.registerDeviceToken()
    }
    
    func getUserId() -> String? {
        return Settings.getUserId()
    }
    
    func getCurrentLocation(completionHandler: @escaping (_ currentLocation: CLLocation?,
                                                          _ error: HyperTrackError?) -> Void) {
        // Check location authorization status
        let authStatus: CLAuthorizationStatus = HyperTrack.locationAuthorizationStatus()
        if (authStatus != .authorizedAlways && authStatus != .authorizedWhenInUse) {
            let htError = HyperTrackError(HyperTrackErrorType.locationPermissionsError)
            HTLogger.shared.error("Error while getCurrentLocation: \(htError.type.rawValue)")
            completionHandler(nil, htError)
            return
        }
        
        // Check location services status
        if (!HyperTrack.locationServicesEnabled()) {
            let htError = HyperTrackError(HyperTrackErrorType.locationDisabledError)
            HTLogger.shared.error("Error while getCurrentLocation: \(htError.type.rawValue)")
            completionHandler(nil, htError)
            return
        }

        // Fetch current location from LocationManager
        let currentLocation = self.locationManager.getLastKnownLocation()
        if (currentLocation == nil) {
            let htError = HyperTrackError(HyperTrackErrorType.invalidLocationError)
            HTLogger.shared.error("Error while getCurrentLocation: \(htError.type.rawValue)")
            completionHandler(nil, htError)
            
        } else {
            completionHandler(currentLocation, nil)
        }
    }
    
    func getETA(expectedPlaceCoordinates: CLLocationCoordinate2D, vehicleType: String?,
                completionHandler: @escaping (_ eta: NSNumber?, _ error: HyperTrackError?) -> Void) {
        var vehicleTypeParam = vehicleType
        if (vehicleTypeParam == nil) {
            vehicleTypeParam = "car"
        }
        
        self.getCurrentLocation { (currentLocation, error) in
            if (currentLocation != nil) {
                self.requestManager.getETA(currentLocationCoordinates: currentLocation!.coordinate,
                                           expectedPlaceCoordinates: expectedPlaceCoordinates,
                                           vehicleType: vehicleTypeParam!,
                                           completionHandler: completionHandler)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    func createUser(_ name:String, completionHandler: ((_ user: HyperTrackUser?, _ error: HyperTrackError?) -> Void)?) {
        self.requestManager.createUser(["name":name]) { user, error in
            
            if (user != nil) {
                self.setUserId(userId: (user?.id)!)
            } else if (error != nil) {
                HTLogger.shared.error("Error creating user: \(String(describing: error?.type.rawValue))")
            }
            
            if (completionHandler != nil) {
                completionHandler!(user, error)
            }
        }
    }
    
    func createUser(_ name: String, _ phone: String, _ lookupID: String, _ photo: UIImage?, _ completionHandler: @escaping (_ user: HyperTrackUser?, _ error: HyperTrackError?) -> Void) {
        var requestBody = ["name": name, "phone": phone, "lookup_id": lookupID]
        
        if let photo = photo {
            // Convert image to base64 before upload
            let imageData: NSData = UIImagePNGRepresentation(photo) as! NSData
            let strBase64 = imageData.base64EncodedString(options: .lineLength64Characters)
            requestBody["photo"] = strBase64
        }
        
        self.requestManager.createUser(requestBody) { user, error in
            
            if (user != nil) {
                self.setUserId(userId: (user?.id)!)
            } else if (error != nil) {
                HTLogger.shared.error("Error creating user: \(String(describing: error?.type.rawValue))")
            }
            
            completionHandler(user, error)
        }
    }
    
    func createUser(_ name: String, _ phone: String, _ lookupID: String, _ completionHandler: @escaping (_ user: HyperTrackUser?, _ error: HyperTrackError?) -> Void) {
        
        self.requestManager.createUser(["name": name, "phone": phone, "lookup_id": lookupID]) { user, error in
            if (user != nil) {
                self.setUserId(userId: (user?.id)!)
                Settings.setLookupId(lookupId: lookupID)
            } else if (error != nil) {
                HTLogger.shared.error("Error creating user: \(String(describing: error?.type.rawValue))")
            }
            
            completionHandler(user, error)
        }
    }
    
    
    func setPublishableKey(publishableKey:String) {
        Settings.setPublishableKey(publishableKey: publishableKey)
    }
    
    func getPublishableKey() -> String? {
        return Settings.getPublishableKey()
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
        
        self.locationManager.startPassiveTrackingService()
        
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
        self.locationManager.stopPassiveTrackingService()
        
        if (completionHandler != nil) {
            completionHandler!(nil)
        }
    }
    
    func getAction(_ actionId: String, _ completionHandler: @escaping (_ action: HyperTrackAction?, _ error: HyperTrackError?) -> Void) {
        self.requestManager.getAction(actionId) { action, error in
            if let action = action {
                completionHandler(action, nil)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    func getActionFromShortCode(_ shortCode:String,_ completionHandler: @escaping (_ action: [HyperTrackAction]?, _ error: HyperTrackError?) -> Void) {
        self.requestManager.getActionFromShortCode(shortCode) { action, error in
            if let action = action {
                completionHandler(action, nil)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    func createAndAssignAction(_ actionParams:HyperTrackActionParams, _ completionHandler: @escaping (_ action: HyperTrackAction?, _ error: HyperTrackError?) -> Void) {
        
        var action = [
            "user_id": Settings.getUserId() as Any,
            "type": actionParams.type as Any,
            "expected_at": actionParams.expectedAt as Any,
            "lookup_id":actionParams.lookupId as Any
            ] as [String: Any]
        
        if let expectedPlace = actionParams.expectedPlace {
            action["expected_place"] = expectedPlace.toDict() as Any
        } else if let expectedPlaceID = actionParams.expectedPlaceId {
            action["expected_place_id"] = expectedPlaceID as Any
        } else {
            completionHandler(nil, HyperTrackError(HyperTrackErrorType.invalidParamsError))
            return
        }
        
        self.getCurrentLocation(completionHandler: { (currentLocation, error) in
            if (currentLocation != nil) {
                action["current_location"] = HyperTrackLocation.init(locationCoordinate: currentLocation!.coordinate,
                                                                     timeStamp: Date()).toDict()
            }
        })
        
        self.requestManager.createAndAssignAction(action, completionHandler: completionHandler)
    }
    
    func assignActions(_ actionIds: [String], _ completionHandler: @escaping (_ action: HyperTrackUser?,
                                                                              _ error: HyperTrackError?) -> Void) {
        if (actionIds.isEmpty) {
            completionHandler(nil, HyperTrackError(HyperTrackErrorType.invalidParamsError))
            return
        }
        
        guard let userId = Settings.getUserId() else {
            completionHandler(nil, HyperTrackError(HyperTrackErrorType.userIdError))
            return
        }
        
        var params = [
            "action_ids":actionIds as Any
        ] as [String: Any]
        
        self.getCurrentLocation(completionHandler: { (currentLocation, error) in
            if (currentLocation != nil) {
                params["current_location"] = HyperTrackLocation.init(locationCoordinate: currentLocation!.coordinate,
                                                                     timeStamp: Date()).toDict()
            }
        })
        
        self.requestManager.assignActions(userId: userId, params, completionHandler: completionHandler)
    }
    
    func completeAction(actionId: String?) {
        guard let userId = self.getUserId() else { return }
        
        guard let actionId = actionId else {
            let event = HyperTrackEvent(userId: userId, recordedAt: Date(), eventType: "action.completed", location: Settings.getLastKnownLocation())
            event.save()
            self.requestManager.postEvents()
            return
        }
        
        let event = HyperTrackEvent(userId: userId, recordedAt: Date(), eventType: "action.completed", location: Settings.getLastKnownLocation(), data: ["action_id": actionId])
        event.save()
        self.requestManager.postEvents()
    }
    
    func cancelPendingActions(completionHandler: ((_ user: HyperTrackUser?, _ error: HyperTrackError?) -> Void)?) {
        guard let userId = self.getUserId() else {
            if let completion = completionHandler {
                completion(nil, HyperTrackError.init(HyperTrackErrorType.invalidParamsError))
            }
            return
        }
        
        self.requestManager.cancelActions(userId: userId, completionHandler: completionHandler)
    }
    
    func updateSDKControls() {
        guard let userId = self.getUserId() else { return }
        
        self.requestManager.getSDKControls(userId: userId) { (controls, error) in
            if (error == nil) {
                if let controls = controls {
                    // Successfully updated the SDKControls
                    HTLogger.shared.info("SDKControls for user: \(userId) updated to batch_duration: \(controls.batchDuration) displacement: \(controls.minimumDisplacement) ttl: \(controls.ttl)")
                    self.processSDKControls(controls: controls)
                }
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

    func processSDKControls(controls: HyperTrackSDKControls) {
        // Process controls
        if let runCommand = controls.runCommand {

            if runCommand == "GO_OFFLINE" {
                // Stop tracking from the backend
                if self.isTracking {
                    HyperTrack.stopTracking()
                }
            } else if runCommand == "FLUSH" {
                self.flushCachedData()
            } else if runCommand == "GO_ACTIVE" {
                // nothing to do as controls will handle
            } else if runCommand == "GO_ONLINE" {
                // nothing to do as controls will handle
            }
        }
        
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
        
        HyperTrackSDKControls.saveControls(controls: controls)
        refreshTransmitter()
    }
    
    func flushCachedData() {
        self.requestManager.postEvents(flush: true)
    }
    
    // Utility methods
    func requestWhenInUseAuthorization() {
        self.locationManager.requestWhenInUseAuthorization()
    }
    
    func requestAlwaysAuthorization() {
        self.locationManager.requestAlwaysAuthorization()
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
        self.locationManager.requestMotionAuthorization()
    }
    
    func callDelegateWithEvent(event: HyperTrackEvent) {
        delegate?.didReceiveEvent(event)
    }
    
    func callDelegateWithError(error: HyperTrackError) {
        delegate?.didFailWithError(error)
    }
    
    func getPlacelineActivity(date: Date? = nil, completionHandler: @escaping (_ placeline: HyperTrackPlaceline?, _ error: HyperTrackError?) -> Void) {
        // TODO: this method should not be in Transmitter, but needs access to request manager
        guard let userId = getUserId() else {
            completionHandler(nil, HyperTrackError(HyperTrackErrorType.userIdError))
            return
        }
        
        requestManager.getUserPlaceline(date: date, userId: userId) { (placeline, error) in
            if (error != nil) {
                completionHandler(nil, error)
                return
            }
            
            completionHandler(placeline, nil)
        }
    }
}
