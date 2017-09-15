//
//  HTLocation.swift
//  HyperTrack
//
//  Created by Tapan Pandita on 23/02/17.
//  Copyright © 2017 HyperTrack, Inc. All rights reserved.
//

import Foundation
import CoreLocation


/**
 GeoJSON to represent geographic coordinates as documented here: http://geojson.org/
 */
@objc public class HTGeoJSONLocation:NSObject {
    /**
     The geographic geometry type
     */
    public let type: String
    
    /**
     The coordinates of the point expressed as [longitude, latitude]
     */
    public let coordinates: [CLLocationDegrees]
    
    /**
     Method to create geojson object from type and coordinates
     */
    public init(type: String, coordinates: CLLocationCoordinate2D) {
        self.type = type
        self.coordinates = [coordinates.longitude, coordinates.latitude]
    }
    
    /**
     Get a dictionary represenation of the GeoJSONLocation
     */
    public func toDict() -> [String: Any] {
        let dict = [
            "type": self.type,
            "coordinates": self.coordinates,
            ] as [String : Any]
        return dict
    }
    
    /**
     Get a json string represenation of the GeoJSONLocation
     */
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
    
    /**
     Convert a json string representation to a HTGeoJSONLocation object
     */
    public static func fromDict(dict: [String:Any]) -> HTGeoJSONLocation? {
        guard let geoJSONCoordinates = dict["coordinates"] as? [CLLocationDegrees],
            let locationType = dict["type"] as? String else {
                return nil
        }
        
        let coordinates = CLLocationCoordinate2D(latitude: geoJSONCoordinates[1], longitude: geoJSONCoordinates[0])
        return HTGeoJSONLocation(type:locationType, coordinates:coordinates)
    }
    
    public func toCoordinate2d() -> CLLocationCoordinate2D {
       return CLLocationCoordinate2DMake(self.coordinates.last!, self.coordinates.first!)
    }
}


/**
 The HyperTrackLocation object that defines all the parameters of a Location fix
 */
@objc public class HyperTrackLocation:NSObject {
    
    /**
     Geojson location object which stores coordinates
     */
    public let location:HTGeoJSONLocation
    
    /**
     Related CLLocation object
     */
    public let clLocation: CLLocation
    
    /**
     Horizontal accuracy (in meters) of the location
     */
    public let horizontalAccuracy: CLLocationAccuracy

    /**
     Vertical accuracy (in meters) of the location
     */
    public let verticalAccuracy: CLLocationAccuracy
    
    /**
     Recorded speed (in meters) of the location
     */
    public let speed: CLLocationSpeed
    
    /**
     Recorded bearing (in degrees) of the location
     */
    public let bearing: CLLocationDirection
    
    /**
     Altitude level (in meters) of the location
     */
    public let altitude: CLLocationDistance
    
    /**
     Activity when the location was recorded
     */
    public var activity: String
    
    /**
     Confidence level for activity when the location was recorded
     */
    public var activityConfidence: Int

    /**
     Provider for the location
     */
    public let provider: String
    
    /**
     Timestamp when the location was recorded
     */
    public var recordedAt: Date
    
    init(clLocation: CLLocation,
         locationType: String,
         activity: String = "",
         activityConfidence: Int = 0,
         provider: String = "") {
        
        let location = HTGeoJSONLocation(type: locationType,
                                         coordinates: clLocation.coordinate)
        self.location = location
        self.clLocation = clLocation
        self.horizontalAccuracy = clLocation.horizontalAccuracy
        self.verticalAccuracy = clLocation.verticalAccuracy
        self.speed = clLocation.speed
        self.bearing = clLocation.course
        self.altitude = clLocation.altitude
        self.activity = activity
        self.activityConfidence = activityConfidence
        self.provider = provider
        self.recordedAt = clLocation.timestamp
    }
    
    init(locationCoordinate: CLLocationCoordinate2D,
         timeStamp: Date,
         provider:String = "gps") {
        // Used only by mock location manager at this point
        self.location = HTGeoJSONLocation(type: "Point", coordinates: locationCoordinate)
        self.provider = provider // TODO: supported?
        self.recordedAt = timeStamp
        
        self.horizontalAccuracy = -1
        self.verticalAccuracy = -1
        self.speed = -1
        self.altitude = -1
        self.bearing = 0
        self.activity = ""
        self.activityConfidence = 0
        self.clLocation = CLLocation(coordinate: locationCoordinate, altitude: self.altitude, horizontalAccuracy: self.horizontalAccuracy, verticalAccuracy: self.verticalAccuracy, timestamp: timeStamp)
    }
    
    internal func toDict() -> [String: Any] {
        let dict = [
            "geojson": self.location.toDict(),
            "accuracy": self.horizontalAccuracy,
            "speed": self.speed,
            "bearing": self.bearing,
            "altitude": self.altitude,
            "activity": self.activity,
            "activity_confidence": self.activityConfidence,
            "provider": self.provider,
            "recorded_at": self.recordedAt.iso8601,
            ] as [String: Any]
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
    
    internal static func fromDict(dict:[String:Any]?) -> HyperTrackLocation? {
        
        if let dict = dict {
            guard let geojsonDict = dict["geojson"] as? [String:Any],
                let activity = dict["activity"] as? String,
                let activityConfidence = dict["activity_confidence"] as? Int,
                let provider = dict["provider"] as? String,
                let altitude = dict["altitude"] as? CLLocationDistance,
                let horizontalAccuracy = dict["accuracy"] as? CLLocationAccuracy,
                let speed = dict["speed"] as? CLLocationSpeed,
                let bearing = dict["bearing"] as? CLLocationDirection,
                let timestamp = dict["recorded_at"] as? String else {
                    return nil
            }
            
            guard let geojson = HTGeoJSONLocation.fromDict(dict:geojsonDict) else {
                return nil
            }
            
            guard let recordedAt = timestamp.dateFromISO8601 else {
                return nil
            }
            
            let verticalAccuracy = CLLocationAccuracy(0)
            let coordinate = CLLocationCoordinate2D(latitude: geojson.coordinates[1], longitude: geojson.coordinates[0])
            
            let clLocation = CLLocation(coordinate: coordinate, altitude: altitude, horizontalAccuracy: horizontalAccuracy, verticalAccuracy: verticalAccuracy, course: bearing, speed: speed, timestamp: recordedAt)
            return HyperTrackLocation(clLocation:clLocation, locationType:geojson.type, activity:activity, activityConfidence:activityConfidence, provider:provider)

        }

        return nil
    }
    
    internal static func fromJson(text:String) -> HyperTrackLocation? {
        if let data = text.data(using: .utf8) {
            do {
                let locationDict = try JSONSerialization.jsonObject(with: data, options: [])
                
                guard let dict = locationDict as? [String : Any] else {
                    return nil
                }
                
                return self.fromDict(dict:dict)
            } catch {
                HTLogger.shared.error("Error in getting location from json: " + error.localizedDescription)
            }
        }
        return nil
    }
}
