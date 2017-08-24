//
//  HTAction.swift
//  HyperTrack
//
//  Created by Tapan Pandita on 10/03/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import Foundation

/**
 Instance of HyperTrackAction represent the action API entity. An Action is a pickup, delivery, visit or any other transaction event being performed by the User. For more information, visit https://docs.hypertrack.com/api/entities/action.html
 */
@objc public class HyperTrackAction:NSObject {
    
    /**
     Unique (uuid4) identifier for the action
     */
    public let id: String?
    
    /**
     User to whom the action is assigned
     */
    public let user: HyperTrackUser?
    
    /**
     Type of action; can be pickup, delivery, visit, stopover
     */
    public let type: String?
    
    /**
     Expected place for the action
     */
    public let expectedPlace: HyperTrackPlace?
    
    /**
     Expected time for the action
     */
    public let expectedAt: Date?
    
    /**
     Completion place of the action
     */
    public let completedPlace: HyperTrackPlace?
    
    /**
     Completion time of the action
     */
    public let completedAt: Date?
    
    /**
     End time of the action
     */
    public let endedAt: Date?
    
    /**
     Assignment time of the action
     */
    public let assignedAt: Date?
    
    /**
     Place where the action started tracking from
     */
    public let startedPlace: HyperTrackPlace?
    
    /**
     Time when the action started tracking from
     */
    public let startedAt: Date?
    
    /**
     Action status text
     */
    public let status: String?
    
    /**
     ETA of the action object
     */
    public let eta: Date?
    
    /**
     Initial ETA estimate for the action
     */
    public let initialEta: Date?
    
    /**
     Web tracking url for the action
     */
    public let trackingUrl: String?
    
    /**
     Action lookup id can be an internal identifier used to access this action object
     */
    public let lookupId: String?
    
    /**
     A set of display fields for the action object
     */
    public let display: HyperTrackActionDisplay?
    
    /**
     Encoded polyline for the action
     */
    public let encodedPolyline: String?
    
    /**
     Time aware polyline for the action
     */
    public let timeAwarePolyline: String?
    
    /**
     Distance traveled while completing the action
     */
    public let distance: Double?
    
    init(id: String?,
         user: HyperTrackUser?,
         type: String?,
         expectedPlace: HyperTrackPlace?,
         expectedAt: Date?,
         completedPlace: HyperTrackPlace?,
         completedAt: Date?,
         endedAt: Date?,
         assignedAt: Date?,
         startedPlace: HyperTrackPlace?,
         startedAt: Date?,
         status: String?,
         eta: Date?,
         initialEta: Date?,
         trackingUrl: String?,
         lookupId: String?,
         display: HyperTrackActionDisplay?,
         encodedPolyline: String?,
         timeAwarePolyline: String?,
         distance: Double?) {
        self.id = id
        self.user = user
        self.type = type
        self.expectedPlace = expectedPlace
        self.expectedAt = expectedAt
        self.completedPlace = completedPlace
        self.completedAt = completedAt
        self.endedAt = endedAt
        self.assignedAt = assignedAt
        self.startedPlace = startedPlace
        self.startedAt = startedAt
        self.status = status
        self.eta = eta
        self.initialEta = initialEta
        self.trackingUrl = trackingUrl
        self.lookupId = lookupId
        self.display = display
        self.encodedPolyline = encodedPolyline
        self.timeAwarePolyline = timeAwarePolyline
        self.distance = distance
    }
    
    internal func toDict() -> [String:Any] {
        let dict = [
            "id": self.id as Any,
            "user": self.user?.toDict() as Any,
            "type": self.type as Any,
            "expected_place": self.expectedPlace?.toDict() as Any,
            "expected_at": self.expectedAt?.iso8601 as Any,
            "completed_place": self.completedPlace?.toDict() as Any,
            "completed_at": self.completedAt?.iso8601 as Any,
            "ended_at": self.endedAt?.iso8601 as Any,
            "assigned_at": self.assignedAt?.iso8601 as Any,
            "started_place": self.startedPlace?.toDict() as Any,
            "stated_at": self.startedAt?.iso8601 as Any,
            "status": self.status as Any,
            "eta": self.eta?.iso8601 as Any,
            "initial_eta": self.initialEta?.iso8601 as Any,
            "tracking_url": self.trackingUrl as Any,
            "lookup_id": self.lookupId as Any,
            "display": self.display?.toDict() as Any,
            "encoded_polyline": self.encodedPolyline as Any,
            "time_aware_polyline": self.timeAwarePolyline as Any,
            "distance": self.distance as Any
            ] as [String:Any]
        return dict
    }
    
    public func toJson() -> String? {
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
    
    internal static func fromDict(dict:[String:Any]) -> HyperTrackAction? {
        
        let action = HyperTrackAction(
            id: dict["id"] as? String,
            user: HyperTrackUser.fromDict(dict: dict["user"] as? [String : Any]),
            type: dict["type"] as? String,
            expectedPlace: HyperTrackPlace.fromDict(dict: dict["expected_place"] as? [String:Any]),
            expectedAt: (dict["expected_at"] as? String)?.dateFromISO8601,
            completedPlace: HyperTrackPlace.fromDict(dict: dict["completed_place"] as? [String:Any]),
            completedAt: (dict["completed_at"] as? String)?.dateFromISO8601,
            endedAt: (dict["ended_at"] as? String)?.dateFromISO8601,
            assignedAt: (dict["assigned_at"] as? String)?.dateFromISO8601,
            startedPlace: HyperTrackPlace.fromDict(dict: dict["started_place"] as? [String:Any]),
            startedAt: (dict["started_at"] as? String)?.dateFromISO8601,
            status: dict["status"] as? String,
            eta: (dict["eta"] as? String)?.dateFromISO8601,
            initialEta: (dict["initial_eta"] as? String)?.dateFromISO8601,
            trackingUrl: dict["tracking_url"] as? String,
            lookupId: dict["lookup_id"] as? String,
            display: HyperTrackActionDisplay.fromDict(dict: dict["display"] as? [String: Any]),
            encodedPolyline: dict["encoded_polyline"] as? String,
            timeAwarePolyline: dict["time_aware_polyline"] as? String,
            distance: dict["distance"] as? Double)
        
        return action
    }
    
    
    internal static func multiActionsFromJSONData(data: Data?) -> [HyperTrackAction]? {
        do {
            let jsonDict = try JSONSerialization.jsonObject(with: data!, options: [])
            
            guard let dict = jsonDict as? [String : Any] else {
                return nil
            }
            
            var actionObjects = [HyperTrackAction]()
            
            let results = dict["results"] as! [Any]
            if let actionsDict = results.first {
                let acts = actionsDict as! [String: Any]
                if let actions = acts["actions"]{
                    let actionsDictionary = actions as! [Any]
                    for action in actionsDictionary{
                        let actionObject = self.fromDict(dict: action as! [String : Any])
                        if let actionObject = actionObject {
                            actionObjects.append(actionObject)
                        }
                    }
                } else{
            let actionObject = self.fromDict(dict: acts)
            if let actionObject = actionObject {
                actionObjects.append(actionObject)
            }
        }
            }
            return actionObjects
            
        } catch {
            HTLogger.shared.error("Error in getting actions from json: " + error.localizedDescription)
            return nil
        }
    }
    
    internal static func fromJson(data:Data?) -> HyperTrackAction? {
        do {
            let jsonDict = try JSONSerialization.jsonObject(with: data!, options: [])
            
            guard let dict = jsonDict as? [String : Any] else {
                return nil
            }
            
            return self.fromDict(dict:dict)
        } catch {
            HTLogger.shared.error("Error in getting action from json: " + error.localizedDescription)
            return nil
        }
    }
    
    public func isCompleted() -> Bool{
        if (self.display != nil), (self.display?.showSummary == true) {
            return true
        }
        return false
    }
    
    
    func isInternetAvailable() -> Bool? {
        return self.user?.isConnected
    }
    
    func isLocationAvailable() -> Bool?{
        if(self.user?.locationStatus == "location_available"){
            return true
        }
        return false
    }
    
    func isActionTrackable() -> Bool?{
        return isInternetAvailable()! && isLocationAvailable()!
    }
}
