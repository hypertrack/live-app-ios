//
//  HTUser.swift
//  HyperTrack
//
//  Created by Tapan Pandita on 06/03/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import Foundation


/**
 Instances of HyperTrackUser represent the user entity: https://docs.hypertrack.com/api/entities/user.html
 */
@objc public class HyperTrackUser:NSObject {
    /**
     Unique (uuid4) identifier for the user
     */
    public let id: String?
    
    /**
     Name of the user (optional)
     */
    public let name: String?
    
    /**
     Phone number for the user (optional)
     */
    public let phone: String?
    
    /**
     Photo url for the user (optional)
     */
    public let photo: String?
    
    /**
     Last heartbeat timestamp for the user (read-only)
     */
    public let lastHeartbeatAt: Date?
    
    /**
     Last location for the user (read-only)
     */
    public let lastLocation: HyperTrackLocation?
    
    /**
     Last battery level for the user (read-only)
     */
    public let lastBattery: Int?
    
    /** 
    Last internet connection status of user 
    */
    public let isConnected : Bool?
    
    /**
    Last location availability status 
    */
    public let locationStatus : String?
    
    init(id: String?,
         name: String?,
         phone: String?,
         photo: String?,
         lastHeartbeatAt: Date?,
         lastLocation: HyperTrackLocation?,
         lastBattery: Int?,
         isConnected: Bool?,
         locationStatus: String?) {
        self.id = id
        self.name = name
        self.phone = phone
        self.photo = photo
        self.lastHeartbeatAt = lastHeartbeatAt
        self.lastLocation = lastLocation
        self.lastBattery = lastBattery
        self.isConnected = isConnected
        self.locationStatus = locationStatus
    }
    
    internal func toDict() -> [String:Any] {
        // TODO: add heartbeat and location field
        let dict = [
            "id": self.id ?? "",
            "name": self.name!,
            "phone": self.phone,
            "photo": self.photo
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
    
    internal static func fromDict(dict:[String:Any]?) -> HyperTrackUser? {
        if let dict = dict {
            let user = HyperTrackUser(
                id: dict["id"] as? String,
                name: dict["name"] as? String,
                phone: dict["phone"] as? String,
                photo: dict["photo"] as? String,
                lastHeartbeatAt: (dict["last_heartbeat_at"] as? String)?.dateFromISO8601,
                lastLocation: HyperTrackLocation.fromDict(dict: dict["last_location"] as?  [String:Any]),
                lastBattery: dict["last_battery"] as? Int,
                isConnected: dict["is_connected"] as? Bool,
                locationStatus:dict["location_status"] as? String)
            
            return user
        }
       return nil
    }
    
    internal static func fromJson(text:String) -> HyperTrackUser? {
        if let data = text.data(using: .utf8) {
            do {
                let userDict = try JSONSerialization.jsonObject(with: data, options: [])
                
                guard let dict = userDict as? [String : Any] else {
                    return nil
                }
                
                return self.fromDict(dict:dict)
            } catch {
                HTLogger.shared.error("Error in getting user from json: " + error.localizedDescription)
            }
        }
        return nil
    }
    
}
