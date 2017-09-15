//
//  HTPlace.swift
//  HyperTrack
//
//  Created by Tapan Pandita on 10/03/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import Foundation
import MapKit

/**
 Instances of HyperTrackPlace represent the place entity: https://docs.hypertrack.com/api/entities/place.html
 */
@objc public class HyperTrackPlace:NSObject {

    /**
     Unique (uuid4) identifier for the place
     */
    public var id: String?
    
    /**
     Name of the place
     */
    public var name: String? = ""
    
    /**
     Location coordinates of the place
     */
    public var location: HTGeoJSONLocation?
    
    /**
     Address string of the place
     */
    public var address: String? = ""
    
    /**
     Locality string of the place
     */
    public var locality: String? = ""
    
    /**
     Landmark of the place
     */
    public var landmark: String? = ""
    
    /**
     Zip code of the place
     */
    public var zipCode: String? = ""
    
    /**
     City of the place
     */
    public var city: String? = ""
    
    /**
     State of the place
     */
    public var state: String? = ""
    
    /**
     Country of the place
     */
    public var country: String? = ""
    
    /**
     Method to get new place object
     */
    public override init() {
    }
    
    internal init(id: String?,
                name: String = "",
                location: HTGeoJSONLocation?,
                address: String = "",
                locality: String = "",
                landmark: String = "",
                zipCode: String = "",
                city: String = "",
                state: String = "",
                country: String = "") {
        self.id = id
        self.name = name
        self.location = location
        self.address = address
        self.locality = locality
        self.landmark = landmark
        self.zipCode = zipCode
        self.city = city
        self.state = state
        self.country = country
    }
    
    
     internal init(
                  name: String = "",
                  location: HTGeoJSONLocation?,
                  address: String = ""
                  ) {
        self.name = name
        self.location = location
        self.address = address
    }

    
    /**
     Method to set the name on a place object
     
     - Parameter name: Name of the place
     - Returns: The place object
     */
    public func setName(name: String = "") -> HyperTrackPlace {
        self.name = name
        return self
    }
    
    /**
     Method to set the location coordinates on a place object
     
     - Parameter latitude: Latitude of the place
     - Parameter longitude: Longitude of the place
     - Returns: The place object
     */
    public func setLocation(latitude: CLLocationDegrees, longitude: CLLocationDegrees) -> HyperTrackPlace {
        let location = HTGeoJSONLocation(
            type: "point",
            coordinates: CLLocationCoordinate2DMake(latitude, longitude))
        self.location = location
        return self
    }
    
    /**
     Method to set the location coordinates on a place object
     
     - Parameter coordinates: Location coordinates of the place
     - Returns: The place object
     */
    public func setLocation(coordinates: CLLocationCoordinate2D) -> HyperTrackPlace {
        let location = HTGeoJSONLocation(type: "point", coordinates: coordinates)
        self.location = location
        return self
    }
    
    /**
     Method to set the address on a place object
     
     - Parameter address: Address of the place
     - Returns: The place object
     */
    public func setAddress(address: String = "") -> HyperTrackPlace {
        self.address = address
        return self
    }
    
    internal func toDict() -> [String:Any] {
        let dict = [
            "id": self.id as Any,
            "name": self.name as Any,
            "location": self.location?.toDict() as Any,
            "address": self.address as Any,
            "landmark": self.landmark as Any,
            "zip_code": self.zipCode as Any,
            "city": self.city as Any,
            "locality": self.locality as Any,
            "state": self.state as Any,
            "country": self.country as Any
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
    
    internal static func fromDict(dict:[String:Any]?) -> HyperTrackPlace? {
        guard let dict = dict else {
            return nil
        }

        guard let id = dict["id"] as? String,
            let location = dict["location"] as? [String:Any]?,
            let address = dict["address"] as? String?
            else {
                return nil
        }
        
        let htLocation = HTGeoJSONLocation.fromDict(dict: location!)
        let place = HyperTrackPlace(
            id: id,
            name: (dict["name"] as? String? ?? "")!,
            location: htLocation,
            address: address!,
            locality: (dict["locality"] as? String? ?? "")!,
            landmark: (dict["landmark"] as? String? ?? "")!,
            zipCode: (dict["zip_code"] as? String? ?? "")!,
            city: (dict["city"] as? String? ?? "")!,
            state: (dict["state"] as? String? ?? "")!,
            country: (dict["country"] as? String? ?? "")!)
        
        return place
    }
    
    internal static func fromJson(text:String) -> HyperTrackPlace? {
        if let data = text.data(using: .utf8) {
            do {
                let userDict = try JSONSerialization.jsonObject(with: data, options: [])
                
                guard let dict = userDict as? [String : Any] else {
                    return nil
                }
                
                return self.fromDict(dict:dict)
            } catch {
                HTLogger.shared.error("Error in getting place from json: " + error.localizedDescription)
            }
        }
        return nil
    }
    
    
    static func multiPlacesFromJson(data:Data?) -> [HyperTrackPlace]?{
        do {
            let jsonDict = try JSONSerialization.jsonObject(with: data!, options: [])
            
            guard let dict = jsonDict as? [String : Any] else {
                return nil
            }
            
            var places = [HyperTrackPlace]()
            let results = dict["results"] as! [Any]
            for  place in results{
                let dict = place as! [String : Any]
                
               
                var name = ""
                if let locationName =  dict["name"] as? String{
                    name = locationName
                }
                
                var htLocation :  HTGeoJSONLocation? = nil
                if let location = dict["location"] as? [String:Any]?{
                     htLocation = HTGeoJSONLocation.fromDict(dict: location!)
                }
             
                var address = ""
                if let locationAddress = dict["address"] as? String?{
                    address = locationAddress!
                }
                
                let htPlace = HyperTrackPlace(
                    name: name,
                    location: htLocation,
                    address: address)
               
                if let  id = dict["id"] as? String{
                    htPlace.id = id
                }
                htPlace.landmark = dict["landmark"] as? String? ?? ""
                htPlace.zipCode = dict["zip_code"] as? String? ?? ""
                htPlace.city = dict["city"] as? String? ?? ""
                htPlace.state = dict["state"] as? String? ?? ""
                htPlace.country = dict["country"] as? String? ?? ""
                places.append(htPlace)
            }
            return places
        } catch {
            HTLogger.shared.error("Error in getting actions from json: " + error.localizedDescription)
            return nil
        }
        
    }
    
    public func getIdentifier() -> String{
        if let id = self.id {
            return id
        }
        
        if let coordinates = self.location?.toCoordinate2d() {
            return coordinates.latitude.description + coordinates.longitude.description
        }
        
        return ""
    }

}
