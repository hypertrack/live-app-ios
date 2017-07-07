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

class LocationManager: NSObject {

  let kFilterDistance: Double = 50
  let kHeartbeat: TimeInterval = 10
  var isHeartbeatSetup: Bool = false
  let locationManager = CLLocationManager()
  var requestManager: RequestManager
  var motionManager: CMMotionActivityManager
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
    if #available(iOS 9.0, *) {
      locationManager.allowsBackgroundLocationUpdates = true
    } else {
      // Fallback on earlier versions
    }
    locationManager.delegate = self
  }

  func updateLocationManager(filterDistance: CLLocationDistance, pausesLocationUpdatesAutomatically: Bool = false) {
    locationManager.distanceFilter = filterDistance
    locationManager.pausesLocationUpdatesAutomatically = pausesLocationUpdatesAutomatically
    if false == pausesLocationUpdatesAutomatically {
      startLocationTracking()
    }
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

    if self.isTracking {
      // Tracking stopped because it was running for the first time
      self.saveTrackingEnded()
      self.isFirstLocation = true
    }
  }
  
  func setupHeartbeatMonitoring() {
    logger.debug("Heartbeat monitoring setup fired")
    isHeartbeatSetup = true
    DispatchQueue.main.asyncAfter(deadline: .now() + kHeartbeat, execute: {
      self.isHeartbeatSetup = false
      self.locationManager.requestLocation()
    })
  }

  // Request location permissions
  func requestWhenInUseAuthorization() {
    self.locationManager.requestWhenInUseAuthorization()
  }

  func requestAlwaysAuthorization() {
    self.locationManager.requestAlwaysAuthorization()
  }

}

//MARK: - Events Handling

extension LocationManager {
  // Handle events

  func saveLocationChanged(location:CLLocation) {
    logger.debug("Saving location.changed event")
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

  func getDeviceInfo() -> [String:Any] {
    let data = [
      "product": UIDevice.current.model,
      "brand": "apple",
      "time_zone": TimeZone.current.identifier,
      "os_version": UIDevice.current.systemVersion,
      "sdk_version": Settings.sdkVersion,
      "device": UIDevice.current.model,
      "model": UIDevice.current.localizedModel,
      "manufacturer": "apple",
      "os": UIDevice.current.systemName,
      "custom_os_version": UIDevice.current.systemVersion,
      "device_id": UIDevice.current.identifierForVendor?.uuidString
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
      logger.debug("Same activity: \(lastActivity)")
      return
    }

    if currentActivity == "unknown" { return }

    htLocation.activity = currentActivity
    htLocation.activityConfidence = getActivityConfidence(activity: activity)

    logger.debug("Saving activity changed event")

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

  func saveStop(eventType:String, location:CLLocation, recordedAt:Date) -> HyperTrackEvent? {
    let htLocation = HyperTrackLocation(clLocation:location, locationType:"Point")

    guard let userId = Settings.getUserId(),
      let stopId = Settings.getStopId() else {
        return nil
    }

    let event = HyperTrackEvent(
      userId:userId,
      recordedAt:recordedAt,
      eventType:eventType,
      location:htLocation,
      data:["stop_id": stopId]
    )
    event.save()
    Settings.setLastKnownLocation(location: htLocation)
    Transmitter.sharedInstance.callDelegateWithEvent(event: event)
    return event
  }

  func saveStopStarted(location:CLLocation, recordedAt:Date) {
    logger.debug("Saving stop.started event")
    let eventType = "stop.started"
    Settings.setStopId(stopId: UUID().uuidString)

    guard let event = self.saveStop(
      eventType: eventType,
      location: location,
      recordedAt:recordedAt
      ) else { return }

    Settings.isAtStop = true
    Settings.stopLocation = event.location
    requestManager.postEvents(flush:true)
    
    // Setup location updates after every 10 secs since we're at a stop
    // and check that we don't fire it more than once
    locationManager.stopUpdatingLocation()
    if false == isHeartbeatSetup {
      setupHeartbeatMonitoring()
    }
  }

  func saveStopEnded(location:CLLocation, recordedAt:Date) {
    logger.debug("Saving stop.ended event")

    if !Settings.isAtStop {
      logger.debug("User not at stop, not saving stop.ended event")
      return
    }

    let eventType = "stop.ended"

    guard let event = self.saveStop(
      eventType: eventType,
      location: location,
      recordedAt: recordedAt
      ) else { return }

    Settings.isAtStop = false
    Settings.stopLocation = event.location
    requestManager.postEvents(flush:true)
    logger.debug("Adding distance filter")
    updateLocationManager(filterDistance: kFilterDistance)
  }

  func saveFirstLocationAsStop(clLocation: CLLocation) {
    logger.debug("Saving first location as stop.started event")
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
    logger.debug("Did change authorization: \(status)")
  }

  func locationManager(_ manager: CLLocationManager,
                       didVisit visit: CLVisit) {
    let clLocation = self.getCLLocationFromVisit(visit: visit)

    if (visit.departureDate == NSDate.distantFuture) {
      if Settings.isAtStop {
        saveStopEnded(location: Settings.stopLocation?.clLocation ?? clLocation, recordedAt: Date())
      }
      saveStopStarted(location: clLocation, recordedAt: visit.arrivalDate)
    } else {
      saveStopEnded(location: clLocation, recordedAt: visit.departureDate)
    }
  }

  func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
    logger.debug("Did pause location updates")
  }

  func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {
    logger.debug("Did resume location updates")
  }

  func locationManager(_ manager: CLLocationManager,
                       didUpdateLocations locations: [CLLocation]) {
    logger.debug("Did update locations \(locations)")
    if isFirstLocation && !Settings.isAtStop {
      guard let clLocation = locations.last else { return }
      // Check if the first location we're getting is at a good enough
      // accuracy before saving it as a stop
      if clLocation.horizontalAccuracy < 100 {
        logger.debug("First location fired and stop started")
        saveFirstLocationAsStop(clLocation: clLocation)
      }
    } else if Settings.isAtStop {
      logger.debug("We think we are at a stop")
      // Handle location changes while at stop
      guard let stopLocation = Settings.stopLocation else { return }
      guard let currentLocation = locations.last else { return }

      let distance = currentLocation.distance(from: stopLocation.clLocation)

      if (distance > kFilterDistance && currentLocation.horizontalAccuracy < 50.0) {
        logger.debug("Distance filter cleared, starting location updates and setting stop ended with distance \(distance)")
        saveStopEnded(location: currentLocation, recordedAt: Date())
        saveLocationChanged(location: currentLocation)
        locationManager.startUpdatingLocation()
      } else {
        // Setup location updates after every 10 secs since we're at a stop
        // and check that we don't fire it more than once
        logger.debug("Distance filter failed and we're still at a stop, setting up heartbeat \(distance)")
        locationManager.stopUpdatingLocation()
        if false == isHeartbeatSetup {
          setupHeartbeatMonitoring()
        }
      }
    } else {
      logger.debug("On a trip and tracking locations")
      for location in locations {
        if location.horizontalAccuracy < 100 {
          saveLocationChanged(location: location)
        }
      }
    }

  }

  func locationManager(_ manager: CLLocationManager,
                       didFailWithError error: Error) {
    logger.debug("Did fail with error: \(error.localizedDescription)")
  }

}
