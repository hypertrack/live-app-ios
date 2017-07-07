//
//  HTPlace.swift
//  HyperTrack
//
//  Created by Tapan Pandita on 10/03/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import Foundation


@objc public class HyperTrackPlace:NSObject {

  public let id: String?
  public let name: String?
  public let location: HTGeoJSONLocation?
  public let address: String?
  public let landmark: String?
  public let zipCode: String?
  public let city: String?
  public let state: String?
  public let country: String?

  public init(id: String?,
              name: String?,
              location: HTGeoJSONLocation?,
              address: String?,
              landmark: String?,
              zipCode: String?,
              city: String?,
              state: String?,
              country: String?) {
    self.id = id
    self.name = name
    self.location = location
    self.address = address
    self.landmark = landmark
    self.zipCode = zipCode
    self.city = city
    self.state = state
    self.country = country
  }

  public func toDict() -> [String:Any] {
    let dict = [
      "id": self.id as Any,
      "name": self.name as Any,
      "location": self.location?.toDict() as Any,
      "address": self.address as Any,
      "landmark": self.landmark as Any,
      "zip_code": self.zipCode as Any,
      "city": self.city as Any,
      "state": self.state as Any,
      "country": self.country as Any
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
      debugPrint("Error serializing object to JSON: %@", error.localizedDescription)
      return nil
    }
  }

  public static func fromDict(dict:[String:Any]?) -> HyperTrackPlace? {
    guard let dict = dict else {
      return nil
    }

    guard let id = dict["id"] as? String,
      let name = dict["name"] as? String?,
      let location = dict["location"] as? [String:Any]?,
      let address = dict["address"] as? String?,
      let landmark = dict["landmark"] as? String?,
      let zipCode = dict["zip_code"] as? String?,
      let city = dict["city"] as? String?,
      let state = dict["state"] as? String?,
      let country = dict["country"] as? String? else {
        return nil
    }

    let htLocation = HTGeoJSONLocation.fromDict(dict: location!)

    let place = HyperTrackPlace(
      id: id,
      name: name,
      location: htLocation,
      address: address,
      landmark: landmark,
      zipCode: zipCode,
      city: city,
      state: state,
      country: country
    )

    return place
  }

  public static func fromJson(text:String) -> HyperTrackPlace? {
    if let data = text.data(using: .utf8) {
      do {
        let userDict = try JSONSerialization.jsonObject(with: data, options: [])

        guard let dict = userDict as? [String : Any] else {
          return nil
        }

        return self.fromDict(dict:dict)
      } catch {
        print(error.localizedDescription)
      }
    }
    return nil
  }
}
