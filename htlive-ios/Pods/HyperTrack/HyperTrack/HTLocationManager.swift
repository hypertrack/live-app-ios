//
//  HTLocationManager.swift
//  HyperTrack
//
//  Created by Tapan Pandita on 21/02/17.
//  Copyright © 2017 HyperTrack, Inc. All rights reserved.
//

import Foundation
import CoreLocation
import CoreMotion
import UIKit

class LocationManager: NSObject {
    // Constants
    let kFilterDistance: Double = 50
    let kHeartbeat: TimeInterval = 10
    
    // Managers
    let locationManager = CLLocationManager()
    let pedometer = CMPedometer()
    var requestManager: RequestManager
    var motionManager: CMMotionActivityManager
    
    // State variables
    var isHeartbeatSetup: Bool = false
    var isFirstLocation: Bool = false
    
    lazy var activityQueue:OperationQueue = {
        var queue = OperationQueue()
        queue.name = "Activity queue"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    var isTracking:Bool {
        get {
            return Settings.getTracking()
        }
        
        set {
            Settings.setTracking(isTracking: newValue)
        }
    }
    
    //MARK: - Setup
    
    override init() {
        self.requestManager = RequestManager()
        self.motionManager = CMMotionActivityManager()
        
        super.init()
        locationManager.distanceFilter = kFilterDistance
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.delegate = self
    }
    
    func allowBackgroundLocationUpdates() {
        if #available(iOS 9.0, *) {
            locationManager.allowsBackgroundLocationUpdates = true
        } else {
            // Fallback on earlier versions
        }
    }

    func updateLocationManager(filterDistance: CLLocationDistance, pausesLocationUpdatesAutomatically: Bool = false) {
        locationManager.distanceFilter = filterDistance
        locationManager.pausesLocationUpdatesAutomatically = pausesLocationUpdatesAutomatically
        if false == pausesLocationUpdatesAutomatically {
            startLocationTracking()
        }
    }
    
    func getLastKnownLocation() -> CLLocation? {
        return self.locationManager.location
    }
    
    func setRegularLocationManager() {
        self.updateLocationManager(filterDistance: kFilterDistance)
    }
    
    func updateRequestTimer(batchDuration: Double) {
        self.requestManager.resetTimer(batchDuration: batchDuration)
    }
    
    func startLocationTracking() {
        self.locationManager.startMonitoringVisits()
        self.locationManager.startMonitoringSignificantLocationChanges()
        self.locationManager.startUpdatingLocation()
    }
    
    func stopLocationTracking() {
        self.locationManager.stopMonitoringSignificantLocationChanges()
        self.locationManager.stopMonitoringVisits()
        self.locationManager.stopUpdatingLocation()
    }
    
    
    func startPassiveTrackingService() {
        self.startLocationTracking()
        self.requestManager.startTimer()
        self.motionManager.startActivityUpdates(to: self.activityQueue) { activity in
            guard let cmActivity = activity else { return }
            self.saveActivityChanged(activity: cmActivity)
        }
        
        if !self.isTracking {
            // Tracking started for the first time
            self.saveTrackingStarted()
            self.isFirstLocation = true
            
            if #available(iOS 9.0, *) {
                self.locationManager.requestLocation()
            } else {
                // Fallback on earlier versions
            }
        }
    }
    
    func canStartPassiveTracking() -> Bool {
        // TODO: Fix this
        return true
    }
    
    func stopPassiveTrackingService() {
        self.stopLocationTracking()
        self.motionManager.stopActivityUpdates()
        
        if self.isTracking {
            // Tracking stopped because it was running for the first time
            self.saveTrackingEnded()

            // State cleaning up
            self.isFirstLocation = true
            Settings.isAtStop = false
        }
    }
    
    func setupHeartbeatMonitoring() {
        isHeartbeatSetup = true
        DispatchQueue.main.asyncAfter(deadline: .now() + kHeartbeat, execute: {
            self.isHeartbeatSetup = false
            // TODO: For iOS 8, Figure out Heartbeat monitoring to detect 
            //       if the user is at a stop or not
            if #available(iOS 9.0, *) {
                self.locationManager.requestLocation()
            }
        })
    }
    
    // Request location permissions
    func requestWhenInUseAuthorization() {
        self.locationManager.requestWhenInUseAuthorization()
    }
    
    func requestAlwaysAuthorization() {
        self.locationManager.requestAlwaysAuthorization()
    }
    
    func requestMotionAuthorization() {
        if !self.isTracking {
            // Only trigggering this when the location manager
            // is not tracking. If it was tracking then the
            // permissions dialog box would have been fired anyway
            self.motionManager.startActivityUpdates(to: OperationQueue(), withHandler: { (activity) in
                // Do nothing actually
            })
            self.motionManager.stopActivityUpdates()
        }
    }
}

//MARK: - Events Handling

extension LocationManager {
    // Handle events
    
    func saveLocationChanged(location:CLLocation) {
        HTLogger.shared.verbose("Saving location.changed event")
        let eventType = "location.changed"
        
        let activity = Settings.getActivity() ?? ""
        let activityConfidence = Settings.getActivityConfidence() ?? 0
        
        let htLocation = HyperTrackLocation(clLocation:location, locationType:"Point", activity: activity, activityConfidence: activityConfidence)
        guard let userId = Settings.getUserId() else { return }
        
        let event = HyperTrackEvent(
            userId:userId,
            recordedAt:htLocation.recordedAt,
            eventType:eventType,
            location:htLocation
        )
        event.save()
        Settings.setLastKnownLocation(location: htLocation)
        Transmitter.sharedInstance.callDelegateWithEvent(event: event)
    }
    
    func getDeviceModel() -> String {
        // Helper method to return exact model number, eg iPhone8,1
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
    
    func getDeviceInfo() -> [String:String?] {
        let data = [
            "product": UIDevice.current.model,
            "brand": "apple",
            "time_zone": TimeZone.current.identifier,
            "os_version": UIDevice.current.systemVersion,
            "sdk_version": Settings.sdkVersion,
            "device": UIDevice.current.model,
            "model": getDeviceModel(),
            "manufacturer": "apple",
            "os": UIDevice.current.systemName,
            "custom_os_version": UIDevice.current.systemVersion,
            "device_id": UIDevice.current.identifierForVendor?.uuidString
        ]
        return data
    }
    
    func getDevicePower() -> [String:String?] {
        let data = [
            // TODO
            "percentage": "0", // percentage
            "charging": "0", // charging status
            "source": "0",
            "power_saver": "0"
        ]
        return data
    }
    
    func getActivity(activity:CMMotionActivity) -> String {
        if activity.automotive {
            return "automotive"
        } else if activity.stationary {
            return "stationary"
        } else if activity.walking {
            return "walking"
        } else if activity.running {
            return "running"
        } else if activity.cycling {
            return "cycling"
        } else if activity.unknown {
            return "unknown"
        } else {
            return "unknown"
        }
    }
    
    func getActivityConfidence(activity:CMMotionActivity) -> Int {
        if activity.confidence.rawValue == 2 {
            return 100
        } else if activity.confidence.rawValue == 1 {
            return 50
        } else {
            return 0
        }
    }
    
    func saveActivityChanged(activity:CMMotionActivity) {
        let eventType = "activity.changed"
        var lastActivity:String
        
        guard let userId = Settings.getUserId(),
            let htLocation = Settings.getLastKnownLocation() else { return }
        
        if Settings.getActivity() != nil {
            lastActivity = Settings.getActivity()!
        } else {
            lastActivity = ""
        }
        
        let currentActivity = self.getActivity(activity: activity)
        
        if currentActivity == lastActivity {
            return
        }
        
        if currentActivity == "unknown" { return }
        
        htLocation.activity = currentActivity
        htLocation.activityConfidence = getActivityConfidence(activity: activity)
        HTLogger.shared.verbose("Saving activity changed event")
        
        let event = HyperTrackEvent(
            userId:userId,
            recordedAt:activity.startDate,
            eventType:eventType,
            location:htLocation
        )
        event.save()
        Settings.setActivity(activity: getActivity(activity: activity))
        Settings.setActivityRecordedAt(activityRecordedAt: activity.startDate)
        Settings.setActivityConfidence(confidence: getActivityConfidence(activity: activity))
        Transmitter.sharedInstance.callDelegateWithEvent(event: event)
    }
    
    func saveDeviceInfoChangedEvent() {
        let eventType = "device.info.changed"
        guard let userId = Settings.getUserId() else { return }
        let event = HyperTrackEvent(
            userId:userId,
            recordedAt:Date(),
            eventType:eventType,
            location:nil,
            data:self.getDeviceInfo()
        )
        event.save()
        Transmitter.sharedInstance.callDelegateWithEvent(event: event)
    }
    
    func saveDevicePowerChangedEvent() {
        let eventType = "device.power.changed"
        guard let userId = Settings.getUserId() else { return }
        let event = HyperTrackEvent(
            userId:userId,
            recordedAt:Date(),
            eventType:eventType,
            location:nil,
            data:self.getDevicePower()
        )
        event.save()
        Transmitter.sharedInstance.callDelegateWithEvent(event: event)
    }
    
    func saveTrackingStarted() {
        let eventType = "tracking.started"
        guard let userId = Settings.getUserId() else { return }
        let event = HyperTrackEvent(
            userId:userId,
            recordedAt:Date(),
            eventType:eventType,
            location:nil
        )
        event.save()
        self.saveDeviceInfoChangedEvent()
        isTracking = true
        requestManager.postEvents(flush:true)
        Transmitter.sharedInstance.callDelegateWithEvent(event: event)
    }
    
    func saveTrackingEnded() {
        let eventType = "tracking.ended"
        isTracking = false
        
        guard let userId = Settings.getUserId() else { return }
        let event = HyperTrackEvent(
            userId:userId,
            recordedAt:Date(),
            eventType:eventType,
            location:nil
        )
        event.save()
        requestManager.postEvents(flush:true)
        Transmitter.sharedInstance.callDelegateWithEvent(event: event)
    }
    
    // Stops handling
    
    func getCLLocationFromVisit(visit:CLVisit) -> CLLocation {
        let clLocation = CLLocation(
            coordinate:visit.coordinate,
            altitude:CLLocationDistance(0),
            horizontalAccuracy:visit.horizontalAccuracy,
            verticalAccuracy:CLLocationAccuracy(0),
            course:CLLocationDirection(0),
            speed:CLLocationSpeed(0),
            timestamp:visit.arrivalDate
        )
        return clLocation
    }
    
    func saveStop(eventType:String, location:CLLocation, recordedAt:Date, data:[String:Any], stopId:String) -> HyperTrackEvent? {
        let htLocation = HyperTrackLocation(clLocation:location, locationType:"Point")
        
        guard let userId = Settings.getUserId() else {
                return nil
        }
        
        var dataDict = data
        dataDict["stop_id"] = stopId
        
        let event = HyperTrackEvent(
            userId:userId,
            recordedAt:recordedAt,
            eventType:eventType,
            location:htLocation,
            data:dataDict
        )
        event.save()
        Settings.setLastKnownLocation(location: htLocation)
        Transmitter.sharedInstance.callDelegateWithEvent(event: event)
        return event
    }
    
    func saveStopStarted(location:CLLocation, recordedAt:Date) {
        HTLogger.shared.info("Saving stop.started event recorded at: \(String(describing: recordedAt.iso8601))")
        let eventType = "stop.started"
        let stopId = UUID().uuidString
        Settings.setStopId(stopId: stopId)
        
        guard let event = self.saveStop(
            eventType: eventType,
            location: location,
            recordedAt:recordedAt,
            data: [:],
            stopId: stopId
            ) else { return }
        
        Settings.isAtStop = true
        Settings.stopLocation = event.location
        Settings.stopStartTime = recordedAt
        requestManager.postEvents(flush:true)
        
        // Setup location updates after every 10 secs since we're at a stop
        // and check that we don't fire it more than once
        locationManager.stopUpdatingLocation()
        if false == isHeartbeatSetup {
            setupHeartbeatMonitoring()
        }
    }
    
    func saveStopEndedWithSteps(location:CLLocation, recordedAt:Date) {
        HTLogger.shared.info("Saving stop.ended event recorded at: \(String(describing: recordedAt.iso8601))")
        
        if !Settings.isAtStop {
            HTLogger.shared.error("User not at stop, not saving stop.ended event")
            return
        }
        
        guard let stopId = Settings.getStopId() else {
            HTLogger.shared.error("Stop id not found in settings. Not saving stop.ended event")
            return
        }
        
        if let startTime = Settings.stopStartTime {
            pedometer.queryPedometerData(from: startTime, to: recordedAt) { (data, error) in
                
                var stepCount:Int? = nil
                var stepDistance:Int? = nil
                
                if (error != nil) {
                    HTLogger.shared.info("Error in handling pedometer updates")
                }
                
                if let data = data {
                    stepCount = data.numberOfSteps as? Int
                    stepDistance = data.distance as? Int
                }
                
                self.saveStopEnded(location: location, recordedAt: recordedAt, stopId: stopId, stepCount: stepCount, stepDistance: stepDistance)
            }
        } else {
            self.saveStopEnded(location: location, recordedAt: recordedAt, stopId: stopId, stepCount: nil, stepDistance: nil)
        }
    }
    
    func saveStopEnded(location:CLLocation, recordedAt:Date, stopId: String, stepCount:Int?, stepDistance:Int?) {
        let eventType = "stop.ended"
        var data:[String:Any] = [:]
        
        if let stepCount = stepCount {
            data["step_count"] = stepCount
        }
        
        if let stepDistance = stepDistance {
            data["step_distance"] = stepDistance
        }
        
        guard let event = self.saveStop(
            eventType: eventType,
            location: location,
            recordedAt: recordedAt,
            data: data,
            stopId: stopId
            ) else { return }
        
        // Stop pedometer updates since we're only saving steps for stops
        Settings.isAtStop = false
        Settings.stopStartTime = nil
        Settings.stopLocation = event.location
        self.requestManager.postEvents(flush:true)
        HTLogger.shared.info("Adding distance filter")
        self.updateLocationManager(filterDistance: self.kFilterDistance)
    }
    
    @objc func endCurrentStop() {
        saveStopEndedWithSteps(location: (Settings.stopLocation?.clLocation)!, recordedAt: Date())
    }
    
    func saveFirstLocationAsStop(clLocation: CLLocation) {
        HTLogger.shared.info("Saving first location as stop.started event")
        saveStopStarted(location: clLocation, recordedAt: Date())
        isFirstLocation = false
    }
}

//MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    
    func filterLocationsWithDistance(locations:[CLLocation],
                                     distanceFilter:CLLocationDistance) -> [CLLocation] {
        var filteredLocations:[CLLocation] = []
        var index = 0
        var nextIndex = 0
        
        filteredLocations.append(locations[index])
        
        while nextIndex < locations.count - 1 {
            nextIndex = nextIndex + 1
            let distance = locations[index].distance(from: locations[nextIndex])
            
            if distance > distanceFilter {
                filteredLocations.append(locations[nextIndex])
                index = nextIndex
            } else {
                continue
            }
        }
        
        return filteredLocations
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didChangeAuthorization status: CLAuthorizationStatus) {
        HTLogger.shared.info("Did change authorization: \(status)")
        let nc = NotificationCenter.default
        nc.post(name:Notification.Name(rawValue:HTConstants.LocationPermissionChangeNotification),
                object: nil,
                userInfo: nil)
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didVisit visit: CLVisit) {
        let clLocation = self.getCLLocationFromVisit(visit: visit)
        let stopId = Settings.getStopId() ?? "none"
        HTLogger.shared.info("Did visit method called with arrival: \(String(describing: visit.arrivalDate.iso8601)) departure: \(String(describing: visit.departureDate.iso8601)) stop id: \(stopId)")
        
        if (visit.arrivalDate != NSDate.distantPast && visit.departureDate != NSDate.distantFuture) {
            // The visit instance has both arrival and departure timestamps
            if Settings.isAtStop {
                // If this is true, then this is definitely a stop.ended event
                saveStopEndedWithSteps(location: Settings.stopLocation?.clLocation ?? clLocation, recordedAt: visit.departureDate)
            } else {
                // The stop has been ended with a fallback. This is ignored.
            }
        } else if (visit.arrivalDate != NSDate.distantPast && visit.departureDate == NSDate.distantFuture) {
            // Visit instance does not have a departure time, but has arrival time
            // This is most likely a stop.started event, in case we are not already at a stop
            if Settings.isAtStop {
                // If this is true, then we ignore this stop started event
            } else {
                // Since we're not at a stop, this event starts a new stop
                saveStopStarted(location: clLocation, recordedAt: visit.arrivalDate)
            }
        } else if (visit.arrivalDate == NSDate.distantPast && visit.departureDate != NSDate.distantFuture) {
            // Visit instance does not have an arrival time, but has a departure time
            // This is only possible if the stop that was artificially started on tracking.started
            // has now ended. Hence, send stop.ended event.
            if Settings.isAtStop {
                // If this is true, then this is definitely a stop.ended event
                saveStopEndedWithSteps(location: Settings.stopLocation?.clLocation ?? clLocation, recordedAt: visit.departureDate)
            } else {
                // The stop has been ended with a fallback. This is ignored.
            }
        }
    }
    
    func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
        HTLogger.shared.info("Did pause location updates")
    }
    
    func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {
        HTLogger.shared.info("Did resume location updates")
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        
        if !isTracking {
            // This method can be called after the location manager is stopped
            // Hence, to not save those locations, the method checks for a live
            // tracking session
            return
        }

        if isFirstLocation && !Settings.isAtStop {
            guard let clLocation = locations.last else { return }
            // Check if the first location we're getting is at a good enough
            // accuracy before saving it as a stop
            if clLocation.horizontalAccuracy < 100 {
                HTLogger.shared.info("First location fired and stop started")
                saveFirstLocationAsStop(clLocation: clLocation)
            }
        } else if Settings.isAtStop {
            // Handle location changes while at stop
            guard let stopLocation = Settings.stopLocation else { return }
            guard let currentLocation = locations.last else { return }
            
            let distance = currentLocation.distance(from: stopLocation.clLocation)
            
            if (distance > kFilterDistance && currentLocation.horizontalAccuracy < 50.0) {
                let stopId = Settings.getStopId() ?? "none"
                HTLogger.shared.info("Ending stop due to location fallback, distance: \(String(describing: distance)) accuracy: \(String(describing: currentLocation.horizontalAccuracy)) stop id: \(stopId)")
                saveStopEndedWithSteps(location: currentLocation, recordedAt: Date())
                saveLocationChanged(location: currentLocation)
                locationManager.startUpdatingLocation()
            } else {
                // Setup location updates after every 10 secs since we're at a stop
                // and check that we don't fire it more than once
                locationManager.stopUpdatingLocation()
                if false == isHeartbeatSetup {
                    setupHeartbeatMonitoring()
                }
            }
        } else {
            HTLogger.shared.verbose("On a trip and tracking locations")
            for location in locations {
                if location.horizontalAccuracy < 100 {
                    saveLocationChanged(location: location)
                }
            }
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didFailWithError error: Error) {
        HTLogger.shared.error("Did fail with error: \(error.localizedDescription)")
    }
}
