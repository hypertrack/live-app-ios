//
//  HTActionParams.swift
//  HyperTrack
//
//  Created by Piyush on 08/06/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import Foundation
import MapKit

/**
 Instances of HyperTrackActionParams are used to build actions: https://docs.hypertrack.com/api/entities/action.html
 */
@objc public class HyperTrackActionParams: NSObject {
    
    /**
     Identifier of user to whom the action is assigned. Use setUserId to set this.
     */
    public var userId:String?
    
    /**
     Identifier of place where the action is to be completed. Use setExpectedPlaceId to set this.
     */
    public var expectedPlaceId : String?
    
    /**
     Expected place where the action is to be completed. Use setExpectedPlace to set this.
     */
    public var expectedPlace : HyperTrackPlace?
    
    /**
     Type of the action. Use setType to set this.
     */
    public var type:String = "visit"
    
    /**
     Lookup id (internal identifier) for the action. Use setLookupId to set this.
     */
    public var lookupId:String = ""
    
    /**
     Set Lookup id for the action as a unique Short Code (6-8 digit alphanumeric 
     string) automatically generated for the Action's tracking url.
     */
    public var lookupIdAsShortCode:Bool = false
    
    /**
     Expected time for the action. Use setExpectedAt to set this.
     */
    public var expectedAt:String?
    
    internal var currentLocation:HyperTrackLocation?
    
    /**
     Set user id for the action
     
     - Parameter userId: UUID identifier for the user
     */
    public func setUserId(userId: String) -> HyperTrackActionParams {
        self.userId = userId
        return self
    }
    
    /**
     Set expected place for the action
     
     - Parameter expectedPlace: Place object
     */
    public func setExpectedPlace(expectedPlace: HyperTrackPlace) -> HyperTrackActionParams {
        self.expectedPlace = expectedPlace
        return self
    }
    
    /**
     Set expected place for the action
     
     - Parameter expectedPlaceId: UUID identifier for the place
     */
    public func setExpectedPlaceId(expectedPlaceId: String) -> HyperTrackActionParams {
        self.expectedPlaceId = expectedPlaceId
        return self
    }
    
    /**
     Set type for the action
     
     - Parameter type: UUID identifier for the place
     */
    public func setType(type: String) -> HyperTrackActionParams {
        self.type = type
        return self
    }

    /**
     Set lookup id for the action
     
     - Parameter lookupId: lookup id for the action
     */
    public func setLookupId(lookupId: String) -> HyperTrackActionParams {
        self.lookupId = lookupId
        return self
    }
    
    /**
     Set Lookup id for the action as a unique Short Code (6-8 digit alphanumeric
     string) automatically generated for the Action's tracking url.
     */
    public func setLookupIdAsShortCode() -> HyperTrackActionParams {
        self.lookupIdAsShortCode = true
        return self
    }
    
    /**
     Set expected at for the action
     
     - Parameter expectedAt: expected timestamp as ISO datetime string
     */
    public func setExpectedAt(expectedAt: String) -> HyperTrackActionParams {
        self.expectedAt = expectedAt
        return self
    }
    
    internal func setCurrentLocation(latitude: CLLocationDegrees, longitude: CLLocationDegrees) -> HyperTrackActionParams {
        let currentLocation = HyperTrackLocation(
            clLocation: CLLocation(latitude: latitude, longitude: longitude),
            locationType: "point")
        self.currentLocation = currentLocation
        return self
    }
    
    internal func setLocation(coordinates: CLLocationCoordinate2D) -> HyperTrackActionParams {
        let currentLocation = HyperTrackLocation(
            clLocation: CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude),
            locationType: "point")
        self.currentLocation = currentLocation
        return self
    }
    
    internal func toDict() -> [String:Any] {
        let dict = [
            "user_id": self.userId as Any,
            "expected_place": self.expectedPlace?.toDict() as Any,
            "expected_place_id": self.expectedPlaceId as Any,
            "type": self.type as Any,
            "lookup_id": self.lookupId as Any,
            "expected_at": self.expectedAt as Any,
            "set_lookup_id_as_short_code": self.lookupIdAsShortCode as Any,
            "current_location": self.currentLocation?.toDict() as Any
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
}
