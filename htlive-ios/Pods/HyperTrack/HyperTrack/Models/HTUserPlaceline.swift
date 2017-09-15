//
//  HTUserPlaceline.swift
//  HyperTrack
//
//  Created by Arjun Attam on 02/07/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

@objc public class HyperTrackActivity:NSObject {
    public let id: String?
    public let type: String?
    public let activity: String?
    public let startedAt: Date?
    public let endedAt: Date?
    
    // Properties for stops
    public let place: HyperTrackPlace?
    public let stepCount: Int?
    public let stepDistance: Int?
    
    // Properties for trips
    public let distance: Int?
    public let encodedPolyline: String?
    public let timeAwarePolyline: String?
    
    init(id: String?,
         type: String?,
         activity: String?,
         startedAt: Date?,
         endedAt: Date?,
         place: HyperTrackPlace?,
         distance: Int?,
         stepCount: Int?,
         stepDistance: Int?,
         encodedPolyline: String?,
         timeAwarePolyline: String?) {
        self.id = id
        self.type = type
        self.activity = activity
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.place = place
        self.distance = distance
        self.stepCount = stepCount
        self.stepDistance = stepDistance
        self.encodedPolyline = encodedPolyline
        self.timeAwarePolyline = timeAwarePolyline
    }
    
    internal static func fromDict(dict:[String:Any]) -> HyperTrackActivity {
        var copyDict = dict
        
        if let startTimeString = dict["started_at"] as? String {
            // Swift does not handle ISO datetime strings that do not have milliseconds
            // This code converts such strings to convertible types
            // eg, "2017-07-03T01:34:03Z" --> "2017-07-03T01:34:03.000000Z"
            if startTimeString.range(of: ".") == nil {
                copyDict["started_at"] = startTimeString.replacingOccurrences(of: "Z", with: ".000000Z")
            }
        }
        
        if let endTimeString = dict["ended_at"] as? String {
            if endTimeString.range(of: ".") == nil {
                copyDict["ended_at"] = endTimeString.replacingOccurrences(of: "Z", with: ".000000Z")
            }
        }
        
        let place = HyperTrackPlace.fromDict(dict: (copyDict["place"] as? [String:Any]?)!)
        
        let segment = HyperTrackActivity(
            id: copyDict["id"] as? String,
            type: copyDict["type"] as? String,
            activity: copyDict["activity"] as? String,
            startedAt: (copyDict["started_at"] as? String)?.dateFromISO8601,
            endedAt: (copyDict["ended_at"] as? String)?.dateFromISO8601,
            place: place,
            distance: copyDict["distance"] as? Int,
            stepCount: copyDict["step_count"] as? Int,
            stepDistance: copyDict["step_distance"] as? Int,
            encodedPolyline: copyDict["encoded_polyline"] as? String,
            timeAwarePolyline: copyDict["time_aware_polyline"] as? String)
        return segment
    }
}

@objc public class HyperTrackPlaceline:NSObject {
    // TODO: should inherit from HyperTrackUser?
    public let id: String?
    public let segments: [HyperTrackActivity]?
    
    init(id: String?,
         segments: [HyperTrackActivity]?) {
        self.id = id
        self.segments = segments
    }
    
    internal static func fromDict(dict:[String:Any]) -> HyperTrackPlaceline? {
        let segments = dict["segments"] as! [[String:Any]]
        var parsedSegments:[HyperTrackActivity] = []
        // Loop over segments and convert to an array of HyperTrackSegment
        
        for segment in segments {
            let newSegment = HyperTrackActivity.fromDict(dict: segment)
            parsedSegments.append(newSegment)
        }
        
        let placeline = HyperTrackPlaceline(
            id: dict["id"] as? String,
            segments: parsedSegments)
        
        return placeline
    }
    
    internal static func fromJson(data:Data) -> HyperTrackPlaceline? {
        do {
            let placelineDict = try JSONSerialization.jsonObject(with: data, options: [])
            
            guard let dict = placelineDict as? [String : Any] else {
                return nil
            }
            
            return self.fromDict(dict:dict)
        } catch {
            HTLogger.shared.error("Error in getting user from json: " + error.localizedDescription)
            return nil
        }
    }
}
