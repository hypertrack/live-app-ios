import HyperTrack
import Foundation
import Model

typealias Payload = [String: Any]
typealias DeviceId = String
typealias GeofenceId = String
typealias PublishableKey = String
typealias Token = String
typealias TripId = String
typealias Email = String

enum HTTPMethod: String {
  case get = "GET"
  case post = "POST"
  case put = "PUT"
  case patch = "PATCH"
  case delete = "DELETE"
  case head = "HEAD"
}

protocol APIEndpoint {
  var body: Data? { get }
  var headers: [String: String] { get }
  var host: String { get }
  var method: HTTPMethod { get }
  var path: String { get }
  var params: Any? { get }
  var encoding: ParamEncoding { get }
}

extension APIEndpoint {
  var body: Data? { return nil }
  var params: Any? { return nil }
  var headers: [String: String] { return [:] }
  var baseURL: String { return host }
  var url: URL {
    var components = URLComponents(string: baseURL)
    components?.path = path
    if method == .get, let params = params as? Payload {
      components?.queryItems = params.map {
        URLQueryItem(name: $0.key, value: $0.value as? String)
      }
    }
    guard let url = components?.url else {
      let failureReason =
      "Failed to construct URL from components: \(String(describing: components))"
      preconditionFailure(failureReason)
    }
    return url
  }
}

enum ApiRouter {
  case authenticate(PublishableKey)
  case getHyperTrackToken(Token)
  case tripCreate(Payload, Token)
  case tripComplete(TripId, Token)
  case getDeepLink(Token, Email)
  case startTracking(Token)
  case stopTracking(Token)
  case masterAccount(Token)
  case createGeofence(Token, Payload)
  case removeGeofence(Token, GeofenceId)
}

enum ParamEncoding: Int {
  case url
  case json
}

extension ApiRouter: APIEndpoint {
  static var baseUrlString: String {
    return Constant.Network.baseURL
  }

  static var htBaseUrlString: String {
    return Constant.Network.htBaseUrl
  }

  var host: String {
    switch self {
      case .getHyperTrackToken, .authenticate:
        return ApiRouter.htBaseUrlString
    case .tripCreate, .tripComplete, .getDeepLink, .startTracking, .stopTracking, .masterAccount, .createGeofence, .removeGeofence:
        return ApiRouter.baseUrlString
    }
  }

  var path: String {
    switch self {
      case .getHyperTrackToken:
        return "\(Constant.Network.apiKey)"
      case .tripCreate:
        return "\(Constant.Network.trips)"
      case let .tripComplete(tripId, _):
        return "\(Constant.Network.trips)" + "/" + tripId +
          "\(Constant.Network.tripComplete)"
      case .createGeofence:
        return "\(Constant.Network.geofence)"
      case let .removeGeofence(_ , geofenceId):
        return "\(Constant.Network.geofence)" + "/" + geofenceId
      case .getDeepLink:
        return "\(Constant.Network.getDeepLink)"
      case .authenticate:
        return "\(Constant.Network.authenticate)"
      case .startTracking(_):
      return "\(Constant.Network.devices)" + "/" + HyperTrack.deviceID + "\(Constant.Network.start)"
      case .stopTracking(_):
        return "\(Constant.Network.devices)" + "/" + HyperTrack.deviceID + "\(Constant.Network.stop)"
      case .masterAccount:
        return "\(Constant.Network.masterAccount)"
    }
  }

  var params: Any? {
    switch self {
      case let .tripCreate(trip, _):
        return trip
      case let .createGeofence(_, payload):
        return payload
      case .authenticate(_):
        return ["device_id": HyperTrack.deviceID]
      default:
        return nil
    }
  }

  var body: Data? {
    guard let params = params, encoding != .url else { return nil }
    switch encoding {
      case .json:
        do {
          return try JSONSerialization.data(
            withJSONObject: params,
            options: JSONSerialization.WritingOptions(rawValue: 0)
          )
        } catch { return nil }
      default: return nil
    }
  }

  var encoding: ParamEncoding {
    switch self {
    case .tripCreate, .tripComplete, .getHyperTrackToken, .createGeofence, .removeGeofence, .getDeepLink, .authenticate, .startTracking, .stopTracking, .masterAccount:
        return .json
    }
  }

  var method: HTTPMethod {
    switch self {
      case .getHyperTrackToken, .getDeepLink, .masterAccount: return .get
      case .tripCreate, .tripComplete, .createGeofence, .authenticate, .startTracking, .stopTracking: return .post
      case .removeGeofence: return .delete
    }
  }

  var headers: [String: String] {
    switch self {
      case let .createGeofence(token, _),
           let .removeGeofence(token, _):
        return ["Content-Type": "application/json", "Authorization": "Bearer \(token)"]
      case let .getHyperTrackToken(token):
        return ["Authorization": "\(token)"]
      case let .tripComplete(_, token),
           let .tripCreate(_, token),
           let .getDeepLink(token, _),
           let .masterAccount(token),
           let .stopTracking(
             token
           ),
           let .startTracking(
             token
           ):
        return ["Authorization": "Bearer \(token)"]
      case let .authenticate(publishableKey):
        return [
          "Content-Type": "application/json",
          "Authorization":
            "Basic \(Data(publishableKey.utf8).base64EncodedString(options: []))"
        ]
    }
  }
}
