import Prelude
import SwiftUI

public struct TripResponse: Codable {
  public let data: [Trip]
  public let links: [String: String]
}

public struct AuthenticateResponse: Codable {
  public let token_type: String
  public let expires_in: Int
  public let access_token: String
}

public struct Trip: Codable, Identifiable {
  public let id: String
  public let startedAt: String
  public let destination: Destination?
  public let estimate: Estimate?
  public let views: Views

  public enum Keys: String, CodingKey {
    case id = "trip_id"
    case startedAt = "started_at"
    case views
    case destination
    case estimate
  }

  public init() {
    id = ""
    startedAt = ""
    destination = Destination()
    estimate = Estimate()
    views = Views()
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: Keys.self)
    id = try container.decode(String.self, forKey: .id)
    startedAt = try container.decode(String.self, forKey: .startedAt)
    destination = try container.decodeIfPresent(
      Destination.self,
      forKey: .destination
    )
    estimate = try container.decodeIfPresent(Estimate.self, forKey: .estimate)
    views = try container.decode(Views.self, forKey: .views)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: Keys.self)
    try container.encode(id, forKey: .id)
    try container.encode(startedAt, forKey: .startedAt)
    try container.encode(destination, forKey: .destination)
    try container.encode(estimate, forKey: .estimate)
    try container.encode(views, forKey: .views)
  }

  public struct Destination: Codable {
    public let address: String?

    public init() {
      address = ""
    }

    public enum Keys: String, CodingKey {
      case address
    }

    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: Keys.self)
      address = try container.decodeIfPresent(String.self, forKey: .address)
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: Keys.self)
      try container.encode(address, forKey: .address)
    }
  }

  public struct Estimate: Codable {
    public let arriveAt: String
    public let route: Route

    public init() {
      arriveAt = ""
      route = Route()
    }

    public enum Keys: String, CodingKey {
      case arriveAt = "arrive_at"
      case route
    }

    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: Keys.self)
      arriveAt = try container.decode(String.self, forKey: .arriveAt)
      route = try container.decode(Route.self, forKey: .route)
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: Keys.self)
      try container.encode(arriveAt, forKey: .arriveAt)
      try container.encode(route, forKey: .route)
    }

    public struct Route: Codable {
      public let startAddress: String
      public let endAddress: String

      public init() {
        startAddress = ""
        endAddress = ""
      }

      public enum Keys: String, CodingKey {
        case startAddress = "start_address"
        case endAddress = "end_address"
      }

      public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        startAddress = try container.decode(String.self, forKey: .startAddress)
        endAddress = try container.decode(String.self, forKey: .endAddress)
      }

      public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        try container.encode(startAddress, forKey: .startAddress)
        try container.encode(endAddress, forKey: .endAddress)
      }
    }
  }

  public struct Views: Codable {
    public let embedURL: URL
    public let shareURL: URL

    public init() {
      embedURL = URL(string: "")!
      shareURL = URL(string: "")!
    }

    public enum Keys: String, CodingKey {
      case embedURL = "embed_url"
      case shareURL = "share_url"
    }

    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: Keys.self)
      embedURL = try container.decode(URL.self, forKey: .embedURL)
      shareURL = try container.decode(URL.self, forKey: .shareURL)
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: Keys.self)
      try container.encode(embedURL, forKey: .embedURL)
      try container.encode(shareURL, forKey: .shareURL)
    }
  }
}

extension Trip: Hashable {
  public static func == (lhs: Trip, rhs: Trip) -> Bool {
    return lhs.id == rhs.id
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
