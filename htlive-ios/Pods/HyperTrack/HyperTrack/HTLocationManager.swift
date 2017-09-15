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
    weak var eventDelegate : HTEventsDelegate?

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
                    if location.horizontalAccuracy < 100 {
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
    
    func startMonitoringForEntryAtPlace(place: HyperTrackPlace, radius:CLLocationDistance, identifier:String){
    
        HTLogger.shared.info("starting monitoring for region having identifier : " + identifier)
        let monitoringRegion = CLCircularRegion(center: (place.location?.toCoordinate2d())!, radius: radius, identifier: identifier)
        HTLogger.shared.info("startMonitorForPlace having identifier: \(place.getIdentifier() ) ")
        locationManager.startMonitoring(for: monitoringRegion)
        monitoringRegion.notifyOnEntry = true
    }

    func startMonitorForPlace(place : HyperTrackPlace){
        if let location = Transmitter.sharedInstance.locationManager.getLastKnownLocation(){
            let monitoringRegion = CLCircularRegion(center: (place.location?.toCoordinate2d())!, radius: 30, identifier: (place.getIdentifier()))
            
            if(monitoringRegion.contains(location.coordinate)){
                HTLogger.shared.info("user coordinate is in monitoringRegion" + location.description)
                let nc = NotificationCenter.default
                nc.post(name: Notification.Name(rawValue:HTConstants.HTMonitoredRegionEntered),
                        object: nil,
                        userInfo: ["region":monitoringRegion])
                return
            }
        }
        
        for clRegion in locationManager.monitoredRegions {
            if (clRegion.identifier == place.getIdentifier()){
                HTLogger.shared.info("already monitoring for this place, not registering again")
                return
            }
        }
        
        HTLogger.shared.info("starting monitoring for region having identifier : " + place.getIdentifier())
        let monitoringRegion = CLCircularRegion(center: (place.location?.toCoordinate2d())!, radius: 30, identifier: place.getIdentifier())
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
        
        let monitoringRegion = CLCircularRegion(center:location.coordinate, radius: 30, identifier: tag!)
        locationManager.startMonitoring(for: monitoringRegion)
        monitoringRegion.notifyOnExit = true
    }
    
    
    func getLocationIdentifier(location :CLLocation) -> String{
        return location.coordinate.latitude.description + location.coordinate.longitude.description
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
        
        if let eventDelegate = self.eventDelegate{
            eventDelegate.didEnterMonitoredRegion?(region: region)
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
