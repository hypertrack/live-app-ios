//
//  HTUserPreferences.swift
//  HyperTrack
//
//  Created by Tapan Pandita on 23/02/17.
//  Copyright © 2017 HyperTrack, Inc. All rights reserved.
//

import Foundation


class Settings {
  static let publishableKeyString = "HyperTrackPublishableKey"
  static let userIdString = "HyperTrackUserId"
  static let lookupIdString = "HyperTrackLookupId"
  static let trackingString = "HyperTrackIsTracking"
  static let stopIdString = "HyperTrackStopId"
  static let eventSavedAtString = "HyperTrackLastEventSavedAt"
  static let activityString = "HyperTrackActivityString"
  static let activityRecordedAtString = "HyperTrackActivityRecordedAt"
  static let activityConfidenceString = "HyperTrackActivityConfidence"
  static let lastKnownLocationString = "HyperTrackLastKnownLocation"
  static let isAtStopString = "HyperTrackIsAtStop"
  static let stopLocationString = "HyperTrackStopLocation"
  static let kUniqueInstallationID = "HyperTrackUniqueInstallationID"

  static var sdkVersion:String {
    get {
      //TODO: Always update this on SDK update, hack
      return "0.3.4"
    }
  }
  
  static var uniqueInstallationID: String {
    get {
      var uniqueID = ""
      let userDefaults = UserDefaults.standard
      var UUID = userDefaults.object(forKey: kUniqueInstallationID)
      if let UUID = UUID {
        uniqueID = UUID as! String
      } else {
        UUID = NSUUID().uuidString
        userDefaults.set(UUID, forKey: kUniqueInstallationID)
        userDefaults.synchronize()
      }
      return uniqueID
    }
  }

  static var isAtStop:Bool {
    get {
      return UserDefaults.standard.bool(forKey: isAtStopString)
    }

    set {
      UserDefaults.standard.set(newValue, forKey: isAtStopString)
      UserDefaults.standard.synchronize()
    }
  }

  static var stopLocation: HyperTrackLocation? {
    get {
      guard let htLocationString = UserDefaults.standard.string(forKey: stopLocationString) else { return nil }
      return HyperTrackLocation.fromJson(text: htLocationString)
    }

    set {
      let htLocationString = newValue?.toJson()
      UserDefaults.standard.set(htLocationString, forKey: stopLocationString)
      UserDefaults.standard.synchronize()
    }
  }

  static func clearTrackingState() {}

  static func setPublishableKey(publishableKey:String) {
    UserDefaults.standard.set(publishableKey, forKey: publishableKeyString)
    UserDefaults.standard.synchronize()
  }

  static func getPublishableKey() -> String? {
    return UserDefaults.standard.string(forKey: publishableKeyString)
  }

  static func setUserId(userId:String) {
    UserDefaults.standard.set(userId, forKey: userIdString)
    UserDefaults.standard.synchronize()
  }
  
  static func getUserId() -> String? {
    return UserDefaults.standard.string(forKey: userIdString)
  }

  static func setLookupId(lookupId:String) {
    UserDefaults.standard.set(lookupId, forKey: lookupIdString)
    UserDefaults.standard.synchronize()
  }
  
  static func getLookupId() -> String? {
    return UserDefaults.standard.string(forKey: lookupIdString)
  }

  static func setTracking(isTracking:Bool) {
    UserDefaults.standard.set(isTracking, forKey: trackingString)
    UserDefaults.standard.synchronize()
  }

  static func getTracking() -> Bool {
    return UserDefaults.standard.bool(forKey: trackingString)
  }

  static func setStopId(stopId:String) {
    UserDefaults.standard.set(stopId, forKey: stopIdString)
    UserDefaults.standard.synchronize()
  }

  static func getStopId() -> String? {
    return UserDefaults.standard.string(forKey: stopIdString)
  }

  static func setStopLocation() {
    // TODO
  }

  static func getStopLocation() {
    // TODO
  }

  static func setLastEventSavedAt(eventSavedAt:Date) {
    let eventSavedAtISO = eventSavedAt.iso8601
    UserDefaults.standard.set(eventSavedAtISO, forKey: eventSavedAtString)
    UserDefaults.standard.synchronize()
  }

  static func getLastEventSavedAt() -> Date? {
    let eventSavedAtISO = UserDefaults.standard.string(forKey: eventSavedAtString)
    return eventSavedAtISO?.dateFromISO8601
  }

  static func setActivity(activity: String) {
    UserDefaults.standard.set(activity, forKey: activityString)
    UserDefaults.standard.synchronize()
  }

  static func getActivity() -> String? {
    return UserDefaults.standard.string(forKey: activityString)
  }

  static func setActivityRecordedAt(activityRecordedAt: Date) {
    UserDefaults.standard.set(activityRecordedAt.iso8601, forKey: activityRecordedAtString)
    UserDefaults.standard.synchronize()
  }

  static func getActivityRecordedAt() -> Date? {
    return UserDefaults.standard.string(forKey: activityRecordedAtString)?.dateFromISO8601
  }

  static func setActivityConfidence(confidence:Int) {
    UserDefaults.standard.set(confidence, forKey: activityConfidenceString)
    UserDefaults.standard.synchronize()
  }

  static func getActivityConfidence() -> Int? {
    return UserDefaults.standard.integer(forKey: activityConfidenceString)
  }

  static func setLastKnownLocation(location:HyperTrackLocation) {
    let locationJSON = location.toJson()
    UserDefaults.standard.set(locationJSON, forKey: lastKnownLocationString)
    UserDefaults.standard.synchronize()
  }

  static func getLastKnownLocation() -> HyperTrackLocation? {
    guard let locationString = UserDefaults.standard.string(forKey: lastKnownLocationString) else { return nil}
    let htLocation = HyperTrackLocation.fromJson(text: locationString)
    return htLocation
  }
}
