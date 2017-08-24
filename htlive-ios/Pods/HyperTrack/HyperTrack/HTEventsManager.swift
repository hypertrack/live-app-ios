//
//  HTEventsManager.swift
//  HyperTrack
//
//  Created by Tapan Pandita on 27/02/17.
//  Copyright © 2017 HyperTrack, Inc. All rights reserved.
//

import Foundation
import CoreMotion
import CoreLocation

enum StopState : String{
    case STOP_START = "STOP_START"
    case STOP_END_CONFIRMING = "STOP_END_CONFIRMING"
    case STOP_END = "STOP_END"
    case STOP_START_CONFIRMING = "STOP_START_CONFIRMING"
    case STOP_UNKNOWN = "STOP_UNKNOWN"
}

class EventsManager : NSObject {

    var requestManager: RequestManager
    var activities = [HTActivity]()
    var isFirstLocation: Bool = false
    var currentStopState : StopState = StopState.STOP_UNKNOWN{
        didSet{
           onStateChange(currentState: currentStopState, fromState: oldValue)
        }
    }
    var lastStateChangeTime : Date?
    var lastStateLocation : CLLocation?

    override init() {
        self.requestManager = RequestManager()
        if(Settings.isAtStop){
            currentStopState = StopState.STOP_START
           
        }else{
            currentStopState = StopState.STOP_END
        }
        HTLogger.shared.info("initializing with last known stop state of \(currentStopState.rawValue)")
        super.init()
        
        if(currentStopState == StopState.STOP_START){
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
                self.setUpGeoFencingForStop()
        })
      }
    }
    
    
    func setUpGeoFencingForStop(){
        if (currentStopState == StopState.STOP_START || currentStopState == StopState.STOP_END_CONFIRMING ){
            if let location = Settings.stopLocation{
                let doesLocationBelongsToRegion = Transmitter.sharedInstance.locationManager.doesLocationBelongToRegion(stopLocation: location, radius: 40, identifier: Settings.getStopId()!)
                if (doesLocationBelongsToRegion == LocationInRegion.BELONGS_OUTSIDE_REGION){
                    HTLogger.shared.info("location does not belong to the region and is 40 m away from stop location so ending thr stop")
                    self.saveStopEndedWithSteps(location: location.clLocation, recordedAt: Date())
                }else{
                    HTLogger.shared.info("Setting up geofence for exit for the current stop")
                    Transmitter.sharedInstance.locationManager.startMonitoringExitForLocation(location:location.clLocation,identifier:  Settings.getStopId()!)

                }

            }
  
        }
    }

    var isTracking:Bool {
        get {
            return Settings.getTracking()
        }
        
        set {
            Settings.setTracking(isTracking: newValue)
        }
    }
    
    func startPassiveTrackingService() {
        
        if !Settings.getTracking() {
            // Tracking started for the first time
            self.saveTrackingStarted()
            self.isFirstLocation = true
            if let location = Transmitter.sharedInstance.locationManager.getLastKnownLocation() {
                if location.horizontalAccuracy < 100 {
                    isFirstLocation = false
                    HTLogger.shared.info("got location from location manager and first stop started")
                    saveFirstLocationAsStop(clLocation: location)
                }
            }
        }
    }
    
    
    func stopPassiveTrackingService() {
        if Settings.getTracking() {
            // Tracking stopped because it was running for the first time
            self.saveTrackingEnded()
            Settings.isAtStop = false
            self.isFirstLocation = true
        }

    }
    
    func onStateChange(currentState : StopState, fromState:StopState){
        lastStateChangeTime = Date()
        self.lastStateLocation = Transmitter.sharedInstance.locationManager.getLastKnownLocation()
        if(lastStateLocation == nil){
            lastStateLocation = Settings.getLastKnownLocation()?.clLocation
        }
        
        HTLogger.shared.info("Stop states changed to : \(currentState.rawValue.description) from : \(fromState.rawValue.description) " )

        if(currentStopState == StopState.STOP_END_CONFIRMING){
            // Setup location updates after every 10 secs since we're at a stop
            // and check that we don't fire it more than once
            if false ==  Transmitter.sharedInstance.locationManager.isHeartbeatSetup {
                HTLogger.shared.info("Setting up heartbeat for requesting location every 10 sec")
                Transmitter.sharedInstance.locationManager.setupHeartbeatMonitoring()
            }
        }
        else if (currentStopState == StopState.STOP_START_CONFIRMING){
            DispatchQueue.main.asyncAfter(deadline: .now() + 150, execute: {
                if (self.currentStopState == StopState.STOP_START_CONFIRMING){
                    HTLogger.shared.info("Since no outliar event happened in last 2 mins so considering it as stop ")
                    if(self.lastStateLocation == nil){
                        self.lastStateLocation = Transmitter.sharedInstance.locationManager.getLastKnownLocation()
                        if (self.lastStateLocation == nil){
                            self.lastStateLocation = Settings.getLastKnownLocation()?.clLocation
                        }
                    }
                    if let location = self.lastStateLocation {
                        self.saveStopStarted(location: location, recordedAt:self.lastStateChangeTime!)
  
                    }
                    else{
                        HTLogger.shared.info("Cannot save stop started event as location is not available")

                    }

                }
            })
        }
        else if (currentStopState == StopState.STOP_END){
            Transmitter.sharedInstance.locationManager.locationManager.startUpdatingLocation()
        }
    }

}

extension EventsManager : HTActivityEventsDelegate {
    
    func didChangedActivityTo(activity:HTActivity, fromActivity:HTActivity?){
         HTLogger.shared.info("didChangedActivityTo : \(activity.activityType.rawValue) from activity : \(fromActivity?.activityType.rawValue ?? "")")

    }
    
    func didRecieveActivityUpdateTo(activity:HTActivity){
       // HTLogger.shared.info("Recieved an activity update \(activity.activityType.rawValue)")
        
        activities.append(activity)
        
        if confirmActivity(currentActivity: activity){
            HTLogger.shared.info("conformed activity \(activity.activityType))")
        }
        if(activity.activityType != HTActivityType.ActivityTypeStationary || activity.activityType == HTActivityType.ActivityTypeNone){
            if(currentStopState == StopState.STOP_START){
                HTLogger.shared.info("Changing state to STOP_END_CONFIRMING as recived an activity update which is not stationary")
                currentStopState = StopState.STOP_END_CONFIRMING
            }
            else if (currentStopState == StopState.STOP_START_CONFIRMING){
                if ((activity.activityType == HTActivityType.ActivityTypeDriving) && (activity.confidence > 60)) {
                    HTLogger.shared.info("Recieved an activity update \(activity.activityType.rawValue) with high confidence \(activity.confidence.description) when we are confirming start. So marking it to previous state which is Stop")
                    currentStopState = StopState.STOP_END
                }
            }
            else if (currentStopState == StopState.STOP_END_CONFIRMING){
                if ((activity.activityType == HTActivityType.ActivityTypeDriving) && (activity.confidence >= 50)) {
                    if confirmActivity(currentActivity: activity){
                        HTLogger.shared.info("Recieved an activity update \(activity.activityType.rawValue) with high confidence \(activity.confidence.description)  when we are confirming end. So ending stop here")
                        
                        if let location =   Transmitter.sharedInstance.locationManager.getLastKnownLocation(){
                            self.saveStopEndedWithSteps(location: location, recordedAt: Date())
                        }
                    }
                }
            }
            
        }else if activity.activityType == HTActivityType.ActivityTypeStationary {
            if(currentStopState == StopState.STOP_END){
                HTLogger.shared.info("Recieved an activity update \(activity.activityType.rawValue) , it might be a beginning of a stop")
                currentStopState = StopState.STOP_START_CONFIRMING
            }
        }
    }
    
    func confirmActivity(currentActivity:HTActivity) -> Bool{
        if (activities.count > 3){
            let activityArray = activities.suffix(from:activities.count - 3)
            let lastActivities = Array(activityArray)
            for activity in lastActivities{
                if (activity.activityType != currentActivity.activityType){
                   return false
                }
                
                if activity.confidence < 50 {
                    return false
                }
            }
            
            return true
        }
        return false
    }
    
    
}




extension EventsManager : LocationEventsDelegate {
    func locationManager(_ manager: LocationManager, didEnterRegion region: CLRegion){
        
    }
    
    func locationManager(_ manager: LocationManager, didExitRegion region: CLRegion){
        if(Settings.isAtStop){
            let stopId = Settings.getStopId()
            if region.identifier == stopId{
                HTLogger.shared.info("Ending a stop as an exit geofence triggered : stopId - \(stopId ?? "")")
                if let location = Transmitter.sharedInstance.locationManager.getLastKnownLocation(){
                    saveStopEndedWithSteps(location: location, recordedAt: Date())
                }
            }
        }
    }
    
    
    func locationManager(_ manager: LocationManager,didUpdateLocations locations: [CLLocation]){
        guard let clLocation = locations.last else { return }
        
        HTLogger.shared.info("got location from location manager updates : horizontalAccuracy \(locations.last?.horizontalAccuracy.description ??  "-1")")

        if(isFirstLocation){
            if clLocation.horizontalAccuracy < 100 {
                isFirstLocation = false
                HTLogger.shared.info("got location from location manager updates and first stop started")
                saveFirstLocationAsStop(clLocation: clLocation)
                return
            }
        }
        
        if (currentStopState == StopState.STOP_START_CONFIRMING || currentStopState == StopState.STOP_END){
            saveLocationChanged(location: clLocation)
        }
        
        if(currentStopState == StopState.STOP_END_CONFIRMING || currentStopState == StopState.STOP_START){
            guard let stopLocation = Settings.stopLocation else { return }
            let distance = clLocation.distance(from: stopLocation.clLocation)
            if (distance > 40 )  {
                if (clLocation.horizontalAccuracy < 100 ){
                    let stopId = Settings.getStopId() ?? "none"
                    HTLogger.shared.info("Ending stop due to location fallback, distance: \(String(describing: distance)) accuracy: \(String(describing: clLocation.horizontalAccuracy)) stop id: \(stopId)")
                    saveStopEndedWithSteps(location: clLocation, recordedAt: Date())
                    saveLocationChanged(location: clLocation)
                    Transmitter.sharedInstance.locationManager.locationManager.startUpdatingLocation()
                }
            }else{
                if false == Transmitter.sharedInstance.locationManager.isHeartbeatSetup {
                    Transmitter.sharedInstance.locationManager.setupHeartbeatMonitoring()
                }
            }
            return
        }
        // Handle location changes while at stop
        
        if (currentStopState == StopState.STOP_START_CONFIRMING){
            guard let lastLocation = self.lastStateLocation else { return }
            let distance = clLocation.distance(from: lastLocation)
            if (distance > 30 && clLocation.horizontalAccuracy < 100) {
                HTLogger.shared.info("Recieved a location update  with high accuracy when we are confirming start. So marking it to previous state which is Stop")
                currentStopState = StopState.STOP_END
            }
        }
        
        
    }
    func locationManager(_ manager: LocationManager,
                         didVisit visit: CLVisit){
        
        let clLocation = HTMapUtils.getCLLocationFromVisit(visit: visit)
        
        HTLogger.shared.info("recieved a visit callback with \(visit.arrivalDate.description) to \(visit.departureDate.description)")

        if (visit.arrivalDate != NSDate.distantPast && visit.departureDate != NSDate.distantFuture) {
            // The visit instance has both arrival and departure timestamps
            
        
        } else if (visit.arrivalDate != NSDate.distantPast && visit.departureDate == NSDate.distantFuture) {
            if (currentStopState == StopState.STOP_START_CONFIRMING){
                if let lastStateChangeTime = self.lastStateChangeTime{
                    if visit.arrivalDate.timeIntervalSince(lastStateChangeTime) > 0{
                        HTLogger.shared.info("since arrival date is greater than when we started tp confirm stop, So marking as stop startred")
                        saveStopStarted(location: clLocation, recordedAt: visit.arrivalDate)
                    }
                }
            }
        } else if (visit.arrivalDate == NSDate.distantPast && visit.departureDate != NSDate.distantFuture) {
            if (currentStopState == StopState.STOP_END_CONFIRMING){
                if let lastStateChangeTime = self.lastStateChangeTime{
                    if visit.departureDate.timeIntervalSince(lastStateChangeTime) > 0{
                        HTLogger.shared.info("since departure date is greater than when we started tp confirm stop end, So marking as stop end")
                        saveStopEndedWithSteps(location: Settings.stopLocation?.clLocation ?? clLocation, recordedAt: visit.departureDate)
                    }
                }
                
            }
        }
    }
    func locationManager(_ manager: LocationManager,
                         didChangeAuthorization status: CLAuthorizationStatus){
        
        
    }
    
}


extension EventsManager {
    
    func saveLocationChanged(location:CLLocation) {
        HTLogger.shared.info("Saving location.changed event")
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

    func saveFirstLocationAsStop(clLocation: CLLocation) {
        HTLogger.shared.info("Saving first location as stop.started event")
        saveStopStarted(location: clLocation, recordedAt: Date())
        isFirstLocation = false
    }
    
    
    func saveStopStarted(location:CLLocation, recordedAt:Date) {
       
        let stopId = UUID().uuidString
        let eventType = "stop.started"
        
        currentStopState = StopState.STOP_START
        Settings.setStopId(stopId: stopId)
        Settings.isAtStop = true
        let htLocation = HyperTrackLocation(clLocation:location, locationType:"Point")
        Settings.stopLocation = htLocation
        Settings.stopStartTime = recordedAt

        HTLogger.shared.info("Saving stop.started event recorded at: \(String(describing: recordedAt.iso8601))" + " stop id : \(stopId) ")

        Transmitter.sharedInstance.locationManager.startMonitoringExitForLocation(location:location,identifier: stopId)

        guard self.saveStop(
            eventType: eventType,
            location: location,
            recordedAt:recordedAt,
            data: [:],
            stopId: stopId
            ) != nil else { return }
        
        requestManager.postEvents(flush:true)
        
        Transmitter.sharedInstance.locationManager.locationManager.stopUpdatingLocation()
    }
    
    
    func saveDeviceInfoChangedEvent() {
        let eventType = "device.info.changed"
        guard let userId = Settings.getUserId() else { return }
        let event = HyperTrackEvent(
            userId:userId,
            recordedAt:Date(),
            eventType:eventType,
            location:nil,
            data:HTGenericUtils.getDeviceInfo()
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
        
        // MARK: - View Life Cycle
        
       

    }
    
    func saveStopEndedWithSteps(location:CLLocation, recordedAt:Date) {
        
        HTLogger.shared.info("recieved stop.ended event at: \(String(describing: recordedAt.iso8601))")
        
        if !Settings.isAtStop {
            HTLogger.shared.error("User not at stop, not saving stop.ended event")
            return
        }
        
        guard let stopId = Settings.getStopId() else {
            HTLogger.shared.error("Stop id not found in settings. Not saving stop.ended event")
            return
        }
       
        
        HTLogger.shared.info("Saving stop.ended event recorded at: \(String(describing: recordedAt.iso8601)) having stopId :  \(stopId)")
        currentStopState = StopState.STOP_END
        
        if let startTime = Settings.stopStartTime {
            Transmitter.sharedInstance.activityManager.pedometer.queryPedometerData(from: startTime, to: recordedAt) { (data, error) in
            
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
        Transmitter.sharedInstance.locationManager.updateLocationManager(filterDistance: Transmitter.sharedInstance.locationManager.kFilterDistance)
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

}



