//
//  HTEvents.swift
//  HyperTrack
//
//  Created by Tapan Pandita on 21/02/17.
//  Copyright © 2017 HyperTrack, Inc. All rights reserved.
//

import Foundation


extension Date {
    static let iso8601Formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        return formatter
    }()
    var iso8601: String {
        return Date.iso8601Formatter.string(from: self)
    }
}

extension String {
    var dateFromISO8601: Date? {
        return Date.iso8601Formatter.date(from: self)
    }
}


/**
 The HyperTrackEvent type enum. Represents all the different types of events possible.
 */
@objc public enum HyperTrackEventType: Int, CustomStringConvertible {
    
    /**
     Event type for start tracking
     */
    case trackingStarted
    
    /**
     Event type for end tracking
     */
    case trackingEnded
    
    /**
     Event type for stop detected
     */
    case stopStarted
    
    /**
     Event type for stop ended
     */
    case stopEnded
    
    /**
     Event type for location changed
     */
    case locationChanged
    
    /**
     Event type for activity changed
     */
    case activityChanged
    
    /**
     Event type for device power status changed
     */
    case powerChanged
    
    /**
     Event type for device radio status changed
     */
    case radioChanged
    
    /**
     Event type for device location configuration changed
     */
    case locationConfigChanged
    
    /**
     Event type for device info changed
     */
    case infoChanged
    
    /**
     Event type for action completed
     */
    case actionCompleted
    
    init?(value: String) {
        switch value {
        case "tracking.started":
            self = .trackingStarted
        case "tracking.ended":
            self = .trackingEnded
        case "stop.started":
            self = .stopStarted
        case "stop.ended":
            self = .stopEnded
        case "location.changed":
            self = .locationChanged
        case "activity.changed":
            self = .activityChanged
        case "device.power.changed":
            self = .powerChanged
        case "device.radio.changed":
            self = .radioChanged
        case "device.location_config.changed":
            self = .locationConfigChanged
        case "device.info.changed":
            self = .infoChanged
        case "action.completed":
            self = .actionCompleted
        //TODO: fallback to something innocuous for default
        default:
            self = .infoChanged
        }
    }
    
    public var description: String {
        switch self {
        case .trackingStarted:
            return "tracking.started"
        case .trackingEnded:
            return "tracking.ended"
        case .stopStarted:
            return "stop.started"
        case .stopEnded:
            return "stop.ended"
        case .locationChanged:
            return "location.changed"
        case .activityChanged:
            return "activity.changed"
        case .powerChanged:
            return "device.power.changed"
        case .radioChanged:
            return "device.radio.changed"
        case .locationConfigChanged:
            return "device.location_config.changed"
        case .infoChanged:
            return "device.info.changed"
        case .actionCompleted:
            return "action.completed"
        }
    }
}


/**
 The HyperTrackEvent object that represents events as they happen in the lifetime of a tracking session
 */
@objc public class HyperTrackEvent:NSObject {
    
    /**
     Unique (uuid4) identifier for the event
     */
    public var id:Int64?
    
    /**
     Id of user for the event
     */
    public let userId: String
    
    /**
     Timestamp when the event was recorded
     */
    public var recordedAt: Date
    
    /**
     Type of the event
     */
    public let eventType: HyperTrackEventType
    
    /**
     Location of the event (optional)
     */
    public let location: HyperTrackLocation?
    
    /**
     Metadata for the event
     */
    public let data: [String:Any]
    
    init(userId: String, recordedAt: Date, eventType: String, location: HyperTrackLocation?, data: [String:Any] = [String: Any]()) {
        self.id = nil
        self.userId = userId
        self.recordedAt = recordedAt
        self.eventType = HyperTrackEventType(value: eventType)!
        self.location = location
        self.data = data
    }
    
    internal func toDict() -> [String: Any] {
        var dict = [
            "user_id": self.userId,
            "recorded_at": self.recordedAt.iso8601,
            "type": self.eventType.description,
            "data": self.data
            ] as [String: Any]
        
        guard let loc = location else {
            return dict
        }
        
        dict["location"] = loc.toDict()
        return dict
    }
    
    internal func toJson() -> String? {
        let dict = self.toDict()
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dict)
            let jsonString = String(data: jsonData, encoding: String.Encoding.utf8)
            return jsonString
        } catch {
            HTLogger.shared.error("Error serializing object to JSON: " + error.localizedDescription)
            return nil
        }
    }
    
    
    internal static func fromDict(dict:[String:Any]) -> HyperTrackEvent? {
        guard let userId = dict["user_id"] as? String,
            let recordedAt = dict["recorded_at"] as? String,
            let eventType = dict["type"] as? String,
            let data = dict["data"] as? [String:Any] else {
                return nil
        }
        
        guard let recordedAtDate = recordedAt.dateFromISO8601 else {
            return nil
        }
        
        guard let location = dict["location"] as? [String:Any] else {
            let event = HyperTrackEvent(
                userId:userId,
                recordedAt:recordedAtDate,
                eventType:eventType,
                location:nil,
                data:data
            )
            return event
        }
        
        let event = HyperTrackEvent(
            userId:userId,
            recordedAt:recordedAtDate,
            eventType:eventType,
            location:HyperTrackLocation.fromDict(dict:location),
            data:data
        )
        return event
    }
    
    internal static func fromJson(text:String) -> HyperTrackEvent? {
        if let data = text.data(using: .utf8) {
            do {
                let eventDict = try JSONSerialization.jsonObject(with: data, options: [])
                
                guard let dict = eventDict as? [String : Any] else {
                    return nil
                }
                
                return self.fromDict(dict:dict)
            } catch {
                HTLogger.shared.error("Error in getting event from json: " + error.localizedDescription)
            }
        }
        return nil
    }
    
    func save() {
        let id = EventsDatabaseManager.sharedInstance.insert(event:self)
        self.id = id
        Settings.setLastEventSavedAt(eventSavedAt: Date())
    }
}
