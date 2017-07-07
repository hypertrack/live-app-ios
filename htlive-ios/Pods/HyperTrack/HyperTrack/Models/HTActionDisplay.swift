//
//  HTActionDisplay.swift
//  HyperTrack
//
//  Created by Arjun Attam on 25/05/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import Foundation

@objc public class HyperTrackActionDisplay:NSObject {
  
  public let statusText: String?
  public let subStatusText: String?
  public let durationRemaining: Int?

  public init(statusText: String?,
              subStatusText: String?,
              durationRemaining: Int?) {
    self.statusText = statusText
    self.subStatusText = subStatusText
    self.durationRemaining = durationRemaining
  }
  
  public func toDict() -> [String:Any] {
    let dict = [
      "statusText": self.statusText as Any,
      "subStatusText": self.subStatusText as Any,
      "durationRemaining": self.durationRemaining as Any
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
  
  public static func fromDict(dict:[String:Any]) -> HyperTrackActionDisplay? {
    
    let display = HyperTrackActionDisplay(
      statusText: dict["status_text"] as? String,
      subStatusText: dict["sub_status_text"] as? String,
      durationRemaining: dict["duration_remaining"] as? Int
    )

    return display
  }
  
  public static func fromJson(data:Data?) -> HyperTrackActionDisplay? {
    do {
      let jsonDict = try JSONSerialization.jsonObject(with: data!, options: [])
      
      guard let dict = jsonDict as? [String : Any] else {
        return nil
      }
      
      return self.fromDict(dict:dict)
    } catch {
      print(error.localizedDescription)
      return nil
    }
  }
  
}
