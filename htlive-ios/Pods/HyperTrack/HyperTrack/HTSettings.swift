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
    static let mockTrackingString = "HyperTrackIsMockTracking"
    static let stopIdString = "HyperTrackStopId"
    static let eventSavedAtString = "HyperTrackLastEventSavedAt"
    
    static let activityString = "HyperTrackActivityString"
    static let activityRecordedAtString = "HyperTrackActivityRecordedAt"
    static let activityConfidenceString = "HyperTrackActivityConfidence"
    static let activityLocationString = "HyperTrackActivityLocationString"

    static let lastKnownLocationString = "HyperTrackLastKnownLocation"
    static let isAtStopString = "HyperTrackIsAtStop"
    static let stopStartTimeString = "HyperTrackStopStartTime"
    static let stopLocationString = "HyperTrackStopLocation"
    
    static let pushNotificationTokenString = "HyperTrackDeviceToken"
    static let registeredTokenString = "HyperTrackDeviceTokenRegistered"
    static let kUniqueInstallationID = "HyperTrackUniqueInstallationID"
    
    static let minimumDurationString = "HyperTrackMinimumDuration"
    static let minimumDisplacementString = "HyperTrackMinimumDisplacement"
    static let batchDurationString = "HyperTrackBatchDuration"
    
    static let mockCoordinatesString = "HyperTrackMockCoordinates"
    static let savedPlacesString = "HyperTrackSavedPlaces"
    static let savedUser = "HyperTrackSavedUser"

    static func getBundle() -> Bundle? {
        let bundleRoot = Bundle(for: HyperTrack.self)
        return Bundle(path: "\(bundleRoot.bundlePath)/HyperTrack.bundle")
    }
    
    static var sdkVersion:String {
        get {
            if let bundle = Settings.getBundle() {
                let dictionary = bundle.infoDictionary!
                let version = dictionary["CFBundleShortVersionString"] as! String
                return version
            }
            
            return ""
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
    
    static var stopStartTime:Date? {
        get {
            let dateString = UserDefaults.standard.string(forKey: stopStartTimeString)
            return dateString?.dateFromISO8601
        }
        
        set {
            UserDefaults.standard.set(newValue?.iso8601, forKey: stopStartTimeString)
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
    
    static func setDeviceToken(deviceToken:String) {
        UserDefaults.standard.set(deviceToken, forKey: pushNotificationTokenString)
        UserDefaults.standard.synchronize()
    }
    
    static func getDeviceToken() -> String? {
        return UserDefaults.standard.string(forKey: pushNotificationTokenString)
    }
    
    static func setRegisteredToken(deviceToken:String) {
        UserDefaults.standard.set(deviceToken, forKey: registeredTokenString)
        UserDefaults.standard.synchronize()
    }
    
    static func getRegisteredToken() -> String? {
        return UserDefaults.standard.string(forKey: registeredTokenString)
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
    
    static func setMockTracking(isTracking:Bool) {
        UserDefaults.standard.set(isTracking, forKey: mockTrackingString)
        UserDefaults.standard.synchronize()
    }
    
    static func getMockTracking() -> Bool {
        return UserDefaults.standard.bool(forKey: mockTrackingString)
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
    
    static func setActivityLocation(location:HyperTrackLocation) {
        let locationJSON = location.toJson()
        UserDefaults.standard.set(locationJSON, forKey: activityLocationString)
        UserDefaults.standard.synchronize()
    }
    
    static func getActivityLocation() -> HyperTrackLocation? {
        guard let locationString = UserDefaults.standard.string(forKey: lastKnownLocationString) else { return nil}
        let htLocation = HyperTrackLocation.fromJson(text: locationString)
        return htLocation
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
    
    static func setControls(controls: HyperTrackSDKControls) {
        if let duration = controls.minimumDuration {
            UserDefaults.standard.set(duration, forKey: minimumDurationString)
        }
        
        if let displacement = controls.minimumDisplacement {
            UserDefaults.standard.set(displacement, forKey: minimumDisplacementString)
        }
        
        if let duration = controls.batchDuration {
            UserDefaults.standard.set(duration, forKey: batchDurationString)
        }
        
        UserDefaults.standard.synchronize()
    }
    
    static func getMinimumDuration() -> Double? {
        return UserDefaults.standard.double(forKey: minimumDurationString)
    }

    static func getMinimumDisplacement() -> Double? {
        return UserDefaults.standard.double(forKey: minimumDisplacementString)
    }
    
    static func getBatchDuration() -> Double? {
        return UserDefaults.standard.double(forKey: batchDurationString)
    }
    
    static func clearSDKControls() {
        UserDefaults.standard.removeObject(forKey: batchDurationString)
        UserDefaults.standard.removeObject(forKey: minimumDurationString)
        UserDefaults.standard.removeObject(forKey: minimumDisplacementString)
        UserDefaults.standard.synchronize()
    }
    
    static func setMockCoordinates(coordinates: [TimedCoordinates]) {
        UserDefaults.standard.set(timedCoordinatesToStringArray(coordinates: coordinates), forKey: mockCoordinatesString)
    }
    
    static func getMockCoordinates() -> [TimedCoordinates]? {
        if let object = UserDefaults.standard.string(forKey: mockCoordinatesString) {
            return timedCoordinatesFromStringArray(coordinatesString: object)
        }
        return nil
    }
    
    
    
    static func addPlaceToSavedPlaces(place : HyperTrackPlace){
            var savedPlaces = getAllSavedPlaces()
            if(savedPlaces != nil){
                if(!HTGenericUtils.checkIfContains(places: savedPlaces!, inputPlace: place)){
                    savedPlaces?.append(place)
                }
            }else{
                savedPlaces = [place]
            }
            
            var savedPlacesDictArray = [[String:Any]]()
            for htPlace in savedPlaces! {
                 let htPlaceDict = htPlace.toDict()
                savedPlacesDictArray.append(htPlaceDict)
                
            }
            
            var jsonDict = [String : Any]()
            jsonDict["results"] = savedPlacesDictArray
           
            do {
                    let jsonData = try JSONSerialization.data(withJSONObject: jsonDict, options: JSONSerialization.WritingOptions.prettyPrinted)
                    UserDefaults.standard.set(jsonData,forKey:savedPlacesString)
                    UserDefaults.standard.synchronize()
            } catch {
                HTLogger.shared.error("Error in getting actions from json: " + error.localizedDescription)
            }
    }
    
    
    static func getAllSavedPlaces() -> [HyperTrackPlace]?{
        if let jsonData = UserDefaults.standard.data(forKey: savedPlacesString){
                let htPlaces = HyperTrackPlace.multiPlacesFromJson(data: jsonData)
                return htPlaces
            }
            return []
    }
    
    static func saveUser(user: HyperTrackUser){
            let jsonData = user.toJson()
            UserDefaults.standard.set(jsonData,forKey:savedUser)
            UserDefaults.standard.synchronize()
    }
    
    static func getUser() -> HyperTrackUser? {
        if let jsonData = UserDefaults.standard.string(forKey: savedUser){
            return HyperTrackUser.fromJson(text: jsonData)
        }
        return nil
    }
}
