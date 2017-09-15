//
//  HTExpandedUser.swift
//  Pods
//
//  Created by Ravi Jain on 03/06/17.
//
//

import UIKit

class HTExpandedUser: HyperTrackUser  {
    
    var timeAwarePolyline : String?
    var encodedPolyline  : String?
    
    public static func userFromDict(dict:[String:Any]) -> HTExpandedUser? {
        let user = HTExpandedUser(
            id: dict["id"] as? String,
            name: dict["name"] as? String,
            phone: dict["phone"] as? String,
            photo: dict["photo"] as? String,
            lastHeartbeatAt: (dict["last_heartbeat_at"] as? String)?.dateFromISO8601,
            lastLocation: HyperTrackLocation.fromDict(dict: dict["last_location"] as!  [String:Any]),
            lastBattery: dict["last_battery"] as? Int,
            isConnected: dict["is_connected"] as? Bool,
            locationStatus: dict["location_status"] as? String)
        
        user.timeAwarePolyline = dict["time_aware_polyline"] as? String
        user.encodedPolyline = dict["encoded_polyline"] as? String
        
        return user
    }
}
