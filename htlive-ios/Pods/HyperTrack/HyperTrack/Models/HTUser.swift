//
//  HTUser.swift
//  HyperTrack
//
//  Created by Tapan Pandita on 06/03/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import Foundation


/**
 Instances of HyperTrackUser reprensent the user entity: https://docs.hypertrack.com/v3/api/entities/user.html
*/
@objc public class HyperTrackUser:NSObject {

  public let id: String
  public let name: String?
  public let phone: String?
  public let photo: String?

  init(id: String, name: String?, phone: String?, photo: String?) {
    self.id = id
    self.name = name
    self.phone = phone
    self.photo = photo
  }

  public func toDict() -> [String:Any] {
    let dict = [
      "id": self.id,
      "name": self.name!,
      "phone": self.phone!,
      "photo": self.photo!
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

  public static func fromDict(dict:[String:Any]) -> HyperTrackUser? {
    guard let id = dict["id"] as? String,
      let name = dict["name"] as? String?,
      let phone = dict["phone"] as? String?,
      let photo = dict["photo"] as? String?
        else {
        return nil
    }

    let user = HyperTrackUser(id: id, name: name, phone: phone, photo: photo)
    return user
  }

  public static func fromJson(text:String) -> HyperTrackUser? {
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
