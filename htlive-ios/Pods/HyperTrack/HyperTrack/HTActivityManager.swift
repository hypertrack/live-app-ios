
//
//  HTActivityManager.swift
//  Pods
//
//  Created by Ravi Jain on 8/4/17.
//
//

import UIKit
import CoreMotion
import MapKit

enum HTActivityType: String {
    case ActivityTypeWalking = "ActivityTypeWalking"
    case ActivityTypeRunning = "ActivityTypeRunning"
    case ActivityTypeDriving = "ActivityTypeDriving"
    case ActivityTypeMoving = "ActivityTypeMoving"
    case ActivityTypeStationary = "ActivityTypeStationary"
    case ActivityTypeNone = "ActivityTypeNone"
    case ActivityTypeCycling = "ActivityTypeCycling"

}


class HTActivity : NSObject{
     var confidence : Int
     var startDate: Date
     var activityType : HTActivityType
     var location : CLLocationCoordinate2D? = nil
    
    init(confidence: Int,startDate : Date , activityType:HTActivityType,location:CLLocationCoordinate2D?){
        self.confidence = confidence
        self.startDate = startDate
        self.activityType = activityType
        self.location  = location
        super.init()
    }
}


protocol HTActivityEventsDelegate : class {
    func didChangedActivityTo(activity:HTActivity, fromActivity:HTActivity?)
    func didRecieveActivityUpdateTo(activity:HTActivity)
}


class HTActivityManager: NSObject {
  
    var motionManager: CMMotionActivityManager
    let pedometer = CMPedometer()
    weak var activityEventDelegate : HTActivityEventsDelegate? = nil
    var deviceSensorDataHelper : HTDeviceSensorsDataHelper? = nil
    
    override init() {
        self.motionManager = CMMotionActivityManager()
        self.deviceSensorDataHelper = HTDeviceSensorsDataHelper()
    }
    
    var isTracking:Bool {
        get {
            return Settings.getTracking()
        }
        
        set {
            Settings.setTracking(isTracking: newValue)
        }
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
    
    lazy var activityQueue:OperationQueue = {
        var queue = OperationQueue()
        queue.name = "Activity queue"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    func startPassiveTrackingService() {
        self.motionManager.startActivityUpdates(to: self.activityQueue) { activity in
            guard let cmActivity = activity else { return }
            self.saveActivityChanged(activity: cmActivity)
        }
        
    }
    
    func stopPassiveTrackingService() {
        self.motionManager.stopActivityUpdates()
    }
    
    func saveActivityChanged(activity:CMMotionActivity) {
        let eventType = "activity.changed"
        var lastActivity:String
        
        var htLocation : HyperTrackLocation? = nil
        if let location = Transmitter.sharedInstance.locationManager.getLastKnownLocation(){
            htLocation = HyperTrackLocation.init(clLocation: location, locationType: "Point")
        }else{
            htLocation = Settings.getLastKnownLocation()
        }
        
        if let activityDelegate = self.activityEventDelegate {
            activityDelegate.didRecieveActivityUpdateTo(activity: self.getActivityFromMotionActivity(activity: activity,location: htLocation?.location.toCoordinate2d()))
        }
        
        guard let userId = HyperTrack.getUserId() else { return}
        let currentActivity = self.getActivity(activity: activity)
        
        if Settings.getActivity() != nil {
            lastActivity = Settings.getActivity()!
        } else {
            lastActivity = ""
        }
        
        if currentActivity == lastActivity {
            return
        }
        
       
        if (htLocation == nil){
            return
        }
            
        if currentActivity == "unknown" { return }
        
        htLocation?.activity = currentActivity
        htLocation?.activityConfidence = getActivityConfidence(activity: activity)
        HTLogger.shared.info("Saving activity changed event" + currentActivity)
        HTLogger.shared.info("Confidence : " + getActivityConfidence(activity: activity).description)

        if let activityDelegate = self.activityEventDelegate {
            activityDelegate.didChangedActivityTo(activity: self.getActivityFromMotionActivity(activity: activity,location: htLocation?.location.toCoordinate2d()), fromActivity: getOldActivity())
        }
        
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
    
    func getOldActivity()-> HTActivity? {
        if let oldActivity = Settings.getActivity() {
            let confidence = Settings.getActivityConfidence()
            let date = Settings.getActivityRecordedAt()
            let activityType = self.getActivityTypeFrom(oldActivity: oldActivity)
            var location = Settings.getActivityLocation()
            return HTActivity.init(confidence: confidence!, startDate: date!, activityType: activityType,location: location?.location.toCoordinate2d())
            
        }
        return nil
    }
    
    
    
    func getActivityFromMotionActivity(activity : CMMotionActivity,location:CLLocationCoordinate2D?) -> HTActivity{
        let activityStr = self.getActivity(activity: activity)
        let activityType = self.getActivityTypeFrom(oldActivity: activityStr)
        let confidence = self.getActivityConfidence(activity: activity)
        return HTActivity.init(confidence: confidence, startDate: activity.startDate, activityType: activityType,location: location)
    }
    
    func crossCheckActivityData(activity:CMMotionActivity) -> CMMotionActivity{
        
        
        return activity
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
    
    
    func getActivityTypeFrom(oldActivity:String) -> HTActivityType{
        var activity = HTActivityType.ActivityTypeNone
        if oldActivity ==  "walking" {
            activity = HTActivityType.ActivityTypeWalking
        } else if oldActivity ==  "running" {
            activity = HTActivityType.ActivityTypeRunning
        } else if oldActivity ==  "automotive" {
            activity = HTActivityType.ActivityTypeDriving
        } else if oldActivity ==  "cycling" {
            activity = HTActivityType.ActivityTypeCycling
        } else if oldActivity ==  "stationary" {
            activity = HTActivityType.ActivityTypeStationary
        } else if oldActivity ==  "unknown" {
            activity = HTActivityType.ActivityTypeNone
        }
        return activity
    }
    
    /*
     *  CMMotionActivity
     *
     *  Discussion:
     *    An estimate of the user's activity based on the motion of the device.
     *
     *    The activity is exposed as a set of properties, the properties are not
     *    mutually exclusive.
     *
     *    For example, if you're in a car stopped at a stop sign the state might
     *    look like:
     *       stationary = YES, walking = NO, running = NO, automotive = YES
     *
     *    Or a moving vehicle,
     *       stationary = NO, walking = NO, running = NO, automotive = YES
     *
     *    Or the device could be in motion but not walking or in a vehicle.
     *       stationary = NO, walking = NO, running = NO, automotive = NO.
     *    Note in this case all of the properties are NO.
     *
     */

    func getActivity(activity:CMMotionActivity) -> String {
    
        if activity.walking {
            return "walking"
        } else if activity.running {
            return "running"
        } else if activity.automotive {
            return "automotive"
        } else if activity.cycling {
            return "cycling"
        } else if activity.stationary {
            return "stationary"
        } else if activity.unknown {
            return "unknown"
        } else {
            return "unknown"
        }
    }

}
