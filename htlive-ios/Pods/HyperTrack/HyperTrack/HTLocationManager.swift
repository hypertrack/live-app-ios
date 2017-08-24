//
//  HTLocationManager.swift
//  HyperTrack
//
//  Created by Tapan Pandita on 21/02/17.
//  Copyright © 2017 HyperTrack, Inc. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit
import CoreMotion

protocol LocationEventsDelegate : class {
     func locationManager(_ manager: LocationManager, didEnterRegion region: CLRegion)
     func locationManager(_ manager: LocationManager, didExitRegion region: CLRegion)
     func locationManager(_ manager: LocationManager,didUpdateLocations locations: [CLLocation])
     func locationManager(_ manager: LocationManager,
                         didVisit visit: CLVisit)
     func locationManager(_ manager: LocationManager,
                         didChangeAuthorization status: CLAuthorizationStatus)
}
enum LocationInRegion : String {
    case BELONGS_TO_REGION = "BELONGS_TO_REGION"
    case BELONGS_OUTSIDE_REGION =  "BELONGS_OUTSIDE_REGION"
    case CANNOT_DETERMINE = "CANNOT_DETERMINE"
}


class LocationManager: NSObject {
    // Constants
    let kFilterDistance: Double = 50
    let kHeartbeat: TimeInterval = 10
    
    // Managers
    let locationManager = CLLocationManager()
    var requestManager: RequestManager
    
    // State variables
    var isHeartbeatSetup: Bool = false
    var isFirstLocation: Bool = false
    let pedometer = CMPedometer()

    var locationPermissionCompletionHandler : ((_ isAuthorized: Bool) -> Void)? = nil
    weak var locationEventsDelegate : LocationEventsDelegate? = nil
 
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
        super.init()
        locationManager.distanceFilter = kFilterDistance
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.delegate = self
        locationManager.activityType = CLActivityType.automotiveNavigation
    }
    
    func allowBackgroundLocationUpdates() {
        if #available(iOS 9.0, *) {
            locationManager.allowsBackgroundLocationUpdates = true
        } else {
            // Fallback on earlier versions
        }
    }
    
    func requestLocation(){
        if #available(iOS 9.0, *) {
            self.locationManager.requestLocation()
        } else {
            // Fallback on earlier versions
        }
    }
    
    func onActivityChange(ativity : CMMotionActivity){
        
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
    
    func getLastKnownHeading() -> CLHeading?{
       return self.locationManager.heading
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
        NotificationCenter.default.addObserver(self, selector: #selector(onAppTerminate(_:)), name: Notification.Name.UIApplicationWillTerminate, object: nil)

    }
    
    func onAppTerminate(_ notification: Notification){
            self.locationManager.startUpdatingLocation()
    }
    
    func stopLocationTracking() {
        self.locationManager.stopMonitoringSignificantLocationChanges()
        self.locationManager.stopMonitoringVisits()
        self.locationManager.stopUpdatingLocation()
        NotificationCenter.default.removeObserver(self)
    }

    func startPassiveTrackingService() {
        self.startLocationTracking()
    }
    
    func canStartPassiveTracking() -> Bool {
        // TODO: Fix this
        return true
    }
    
    
    func stopPassiveTrackingService() {
        self.stopLocationTracking()
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
    
    func requestAlwaysAuthorization(completionHandler: @escaping (_ isAuthorized: Bool) -> Void) {
        locationPermissionCompletionHandler  = completionHandler
        self.locationManager.requestAlwaysAuthorization()
    }
    
    func doesLocationBelongToRegion(stopLocation:HyperTrackLocation,radius:Int,identifier : String) -> LocationInRegion{
            let clLocation = stopLocation.clLocation
            let monitoringRegion = CLCircularRegion(center:clLocation.coordinate, radius: CLLocationDistance(radius), identifier:identifier)
            if let location = self.getLastKnownLocation(){
                if (location.timestamp.timeIntervalSince1970 > (Date().timeIntervalSince1970 - 120)){
                    if location.horizontalAccuracy < 25 {
                        if(monitoringRegion.contains(location.coordinate)){
                            HTLogger.shared.info("user coordinate is in monitoringRegion" + location.description)
                            return LocationInRegion.BELONGS_TO_REGION
                        }else{
                            return LocationInRegion.BELONGS_OUTSIDE_REGION
                        }
                    }else{
                        HTLogger.shared.info("user coordinate is not accurate so not considering for geofenceing")
                    }
                }else{
                    HTLogger.shared.info("user coordinate is very old so not using for geofencing requesting location")
                }
            }else{
                HTLogger.shared.info("user coordinate does not belong to monitoringRegion" + stopLocation.description)
            }
        self.requestLocation()

        return LocationInRegion.CANNOT_DETERMINE
    }

    func startMonitorForPlace(place : HyperTrackPlace){
        if let location = Transmitter.sharedInstance.locationManager.getLastKnownLocation(){
            let monitoringRegion = CLCircularRegion(center: (place.location?.toCoordinate2d())!, radius: 40, identifier: (place.getIdentifier()))
            
            if(monitoringRegion.contains(location.coordinate)){
                HTLogger.shared.info("user coordinate is in monitoringRegion" + location.description)
                let nc = NotificationCenter.default
                nc.post(name: Notification.Name(rawValue:HTConstants.HTMonitoredRegionEntered),
                        object: nil,
                        userInfo: ["region":monitoringRegion])
                return
            }
        }
       
        let monitoringRegion = CLCircularRegion(center: (place.location?.toCoordinate2d())!, radius: 40, identifier: place.getIdentifier())
        HTLogger.shared.info("startMonitorForPlace having identifier: \(place.getIdentifier() ) ")
        locationManager.startMonitoring(for: monitoringRegion)
        monitoringRegion.notifyOnEntry = true
        monitoringRegion.notifyOnExit = true
    }
    
    func startMonitoringExitForLocation(location : CLLocation , identifier : String? = nil ){
        
        HTLogger.shared.info("startMonitoringExitForLocation having identifier: \(identifier ?? "") ")

        var tag = identifier
        if (identifier == nil){
            tag = getLocationIdentifier(location: location)
        }
        
        let monitoringRegion = CLCircularRegion(center:location.coordinate, radius: 40, identifier: tag!)
        locationManager.startMonitoring(for: monitoringRegion)
        monitoringRegion.notifyOnExit = true
    }
    
    
    func getLocationIdentifier(location :CLLocation) -> String{
        return location.coordinate.latitude.description + location.coordinate.longitude.description
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
        
        startMonitoringExitForLocation(location:location)
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
        if let locationEventDelegate = self.locationEventsDelegate{
            locationEventDelegate.locationManager(self, didChangeAuthorization: status)
        }
        
        HTLogger.shared.info("Did change authorization: \(status)")
        let nc = NotificationCenter.default
        nc.post(name:Notification.Name(rawValue:HTConstants.HTLocationPermissionChangeNotification),
                object: nil,
                userInfo: nil)
        if(locationPermissionCompletionHandler != nil){
            if(status == .authorizedAlways){
                locationPermissionCompletionHandler!(true)
            }else{
                locationPermissionCompletionHandler!(false)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didVisit visit: CLVisit) {
        
        if !Settings.getTracking() {
            // This method can be called after the location manager is stopped
            // Hence, to not save those locations, the method checks for a live
            // tracking session
            return
        }
        

        if let locationEventDelegate = self.locationEventsDelegate{
            locationEventDelegate.locationManager(self, didVisit: visit)
        }
        let nc = NotificationCenter.default
        nc.post(name: Notification.Name(rawValue:HTConstants.HTLocationChangeNotification),
                object: nil,
                userInfo: nil)
//
//        let clLocation = HTMapUtils.getCLLocationFromVisit(visit: visit)
//        let stopId = Settings.getStopId() ?? "none"
//        HTLogger.shared.info("Did visit method called with arrival: \(String(describing: visit.arrivalDate.iso8601)) departure: \(String(describing: visit.departureDate.iso8601)) stop id: \(stopId)")
//        
//        if (visit.arrivalDate != NSDate.distantPast && visit.departureDate != NSDate.distantFuture) {
//            // The visit instance has both arrival and departure timestamps
//            if Settings.isAtStop {
//                // If this is true, then this is definitely a stop.ended event
//                saveStopEndedWithSteps(location: Settings.stopLocation?.clLocation ?? clLocation, recordedAt: visit.departureDate)
//            } else {
//                // The stop has been ended with a fallback. This is ignored.
//            }
//        } else if (visit.arrivalDate != NSDate.distantPast && visit.departureDate == NSDate.distantFuture) {
//            // Visit instance does not have a departure time, but has arrival time
//            // This is most likely a stop.started event, in case we are not already at a stop
//            if Settings.isAtStop {
//                // If this is true, then we ignore this stop started event
//            } else {
//                // Since we're not at a stop, this event starts a new stop
//                saveStopStarted(location: clLocation, recordedAt: visit.arrivalDate)
//            }
//        } else if (visit.arrivalDate == NSDate.distantPast && visit.departureDate != NSDate.distantFuture) {
//            // Visit instance does not have an arrival time, but has a departure time
//            // This is only possible if the stop that was artificially started on tracking.started
//            // has now ended. Hence, send stop.ended event.
//            if Settings.isAtStop {
//                // If this is true, then this is definitely a stop.ended event
//                saveStopEndedWithSteps(location: Settings.stopLocation?.clLocation ?? clLocation, recordedAt: visit.departureDate)
//            } else {
//                // The stop has been ended with a fallback. This is ignored.
//            }
//        }
    }
    
    func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
        HTLogger.shared.info("Did pause location updates")
    }
    
    func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {
        HTLogger.shared.info("Did resume location updates")
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        
        if !Settings.getTracking() {
            // This method can be called after the location manager is stopped
            // Hence, to not save those locations, the method checks for a live
            // tracking session
            return
        }
        
        
        if let locationEventDelegate = self.locationEventsDelegate{
            locationEventDelegate.locationManager(self, didUpdateLocations: locations)
        }
        
        let nc = NotificationCenter.default
        nc.post(name: Notification.Name(rawValue:HTConstants.HTLocationChangeNotification),
                object: nil,
                userInfo: nil)

//        if isFirstLocation && !Settings.isAtStop {
//            guard let clLocation = locations.last else { return }
//            // Check if the first location we're getting is at a good enough
//            // accuracy before saving it as a stop
//            if clLocation.horizontalAccuracy < 100 {
//                HTLogger.shared.info("First location fired and stop started")
//                saveFirstLocationAsStop(clLocation: clLocation)
//            }
//        } else if Settings.isAtStop {
//            // Handle location changes while at stop
//            guard let stopLocation = Settings.stopLocation else { return }
//            guard let currentLocation = locations.last else { return }
//            
//            let distance = currentLocation.distance(from: stopLocation.clLocation)
//            
//            if (distance > kFilterDistance && currentLocation.horizontalAccuracy < 50.0) {
//                let stopId = Settings.getStopId() ?? "none"
//                HTLogger.shared.info("Ending stop due to location fallback, distance: \(String(describing: distance)) accuracy: \(String(describing: currentLocation.horizontalAccuracy)) stop id: \(stopId)")
//                saveStopEndedWithSteps(location: currentLocation, recordedAt: Date())
//                saveLocationChanged(location: currentLocation)
//                locationManager.startUpdatingLocation()
//            } else {
//                // Setup location updates after every 10 secs since we're at a stop
//                // and check that we don't fire it more than once
//                locationManager.stopUpdatingLocation()
//                if false == isHeartbeatSetup {
//                    setupHeartbeatMonitoring()
//                }
//            }
//        } else {
//            HTLogger.shared.verbose("On a trip and tracking locations")
//            for location in locations {
//                if location.horizontalAccuracy < 100 {
//                    saveLocationChanged(location: location)
//                }
//            }
//        }
        
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didFailWithError error: Error) {
        HTLogger.shared.error("Did fail with error: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading){
        
        
        if newHeading.headingAccuracy < 0 { return }
        let nc = NotificationCenter.default
        nc.post(name: Notification.Name(rawValue:HTConstants.HTLocationHeadingChangeNotification),
                object: nil,
                userInfo: ["heading":newHeading])

    }

    public func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion){
        HTLogger.shared.info(" location manager didEnterRegion " + region.identifier)
        if let locationEventDelegate = self.locationEventsDelegate{
            locationEventDelegate.locationManager(self, didEnterRegion: region)
        }
        
        let nc = NotificationCenter.default
        nc.post(name: Notification.Name(rawValue:HTConstants.HTMonitoredRegionEntered),
                object: nil,
                userInfo: ["region":region])
    }
    
    public func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion){
        
        if let locationEventDelegate = self.locationEventsDelegate{
            locationEventDelegate.locationManager(self, didExitRegion: region)
        }
        
        HTLogger.shared.info("First location didExitRegion")

        let nc = NotificationCenter.default
        nc.post(name: Notification.Name(rawValue:HTConstants.HTMonitoredRegionExited),
                object: nil,
                userInfo: ["region":region])
       }
}
