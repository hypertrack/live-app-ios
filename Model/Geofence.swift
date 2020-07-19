//
//  Geofence.swift
//  Model
//
//  Created by Dmytro Shapovalov on 17.07.2020.
//  Copyright © 2020 Dmytro Shapovalov. All rights reserved.
//

import Foundation

public struct Geofence: Codable {
  public let geofenceId: String
  
  public enum Keys: String, CodingKey {
    case geofenceId = "geofence_id"
  }

  public init() {
    geofenceId = ""
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: Keys.self)
    geofenceId = try container.decode(String.self, forKey: .geofenceId)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: Keys.self)
    try container.encode(geofenceId, forKey: .geofenceId)
  }
  
}
