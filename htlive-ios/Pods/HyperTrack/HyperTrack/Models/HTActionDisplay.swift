//
//  HTActionDisplay.swift
//  HyperTrack
//
//  Created by Arjun Attam on 25/05/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import Foundation

/**
 Instances of HyperTrackActionDisplay represent display fields of an action: https://docs.hypertrack.com/api/entities/action.html
 */
@objc public class HyperTrackActionDisplay:NSObject {
    
    /**
     Human readable status for the action
     */
    public let statusText: String?
    
    /**
     Human readable sub status for the action
     */
    public let subStatusText: String?
    
    /**
     Duration remaining (ETA) in seconds for action to be completed
     */
    public let durationRemaining: Int?
    
    /**
     Distance remaining in meters for action to be completed
     */
    public let distanceRemaining: Int?
    
    /**
     Distance unit (km or mi)
     */
    public let distanceUnit: String?
    
    /**
     Boolean indicating whether to show Action Summary or not
     */
    public var showSummary: Bool = false
    
    internal init(statusText: String?,
                subStatusText: String?,
                durationRemaining: Int?,
                distanceRemaining: Int?,
                distanceUnit: String?,
                showSummary: Bool?) {
        self.statusText = statusText
        self.subStatusText = subStatusText
        self.durationRemaining = durationRemaining
        self.distanceRemaining = distanceRemaining
        self.distanceUnit = distanceUnit
        if (showSummary != nil) {
            self.showSummary = showSummary!
        }
    }
    
    internal func toDict() -> [String:Any] {
        let dict = [
            "statusText": self.statusText as Any,
            "subStatusText": self.subStatusText as Any,
            "durationRemaining": self.durationRemaining as Any,
            "distanceRemaining": self.distanceRemaining as Any,
            "distanceMetric": self.distanceUnit as Any,
            "showSummary": self.showSummary as Any
            ] as [String:Any]
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
    
    internal static func fromDict(dict:[String:Any]?) -> HyperTrackActionDisplay? {
        
        if let dict = dict {
            let display = HyperTrackActionDisplay(
                statusText: dict["status_text"] as? String,
                subStatusText: dict["sub_status_text"] as? String,
                durationRemaining: dict["duration_remaining"] as? Int,
                distanceRemaining: dict["distance_remaining"] as? Int,
                distanceUnit: dict["distance_unit"] as? String,
                showSummary: dict["show_summary"] as? Bool
            )
            
            return display
        }
        
        return nil
    }
    
    internal static func fromJson(data:Data?) -> HyperTrackActionDisplay? {
        do {
            let jsonDict = try JSONSerialization.jsonObject(with: data!, options: [])
            
            guard let dict = jsonDict as? [String : Any] else {
                return nil
            }
            
            return self.fromDict(dict:dict)
        } catch {
            HTLogger.shared.error("Error in getting action display from json: " + error.localizedDescription)
            return nil
        }
    }
}
