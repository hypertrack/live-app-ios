import Combine
import struct CoreLocation.CLLocationCoordinate2D
import HyperTrack
import Model
import SwiftUI

protocol LiveApiProviding {
  var apiSession: APISessionProviding { get }

  func authenticate(
    _ publishableKey: PublishableKey
  ) -> AnyPublisher<
    AuthenticateResponse,
    Error
  >
  func createTrip(
    _ tripPayload: Payload,
    _ token: Token
  ) -> AnyPublisher<
    Trip,
    Error
  >
  func completeTrip(
    _ tripId: TripId,
    _ token: Token
  ) -> AnyPublisher<
    [String: String],
    Error
  >
func createGeofence(_ payload: Payload, _ token: Token) -> AnyPublisher<
    [Geofence],
    Error
  >
  func removeGeofence(
    _ geofenceId: GeofenceId,
    _ token: Token
  ) -> AnyPublisher<
    Void,
    Error
  >
  func getDeepLink(
    _ token: String,
    _ email: String
  ) -> AnyPublisher<
    String,
    Error
  >
  func startTracking(_ token: Token) -> AnyPublisher<
    Void,
    Error
  >
  func stopTracking(_ token: Token) -> AnyPublisher<
    Void,
    Error
  >
  func masterAccount(_ token: Token) -> AnyPublisher<
    String,
    Error
  >
}

struct LiveApiProvider: LiveApiProviding {
  let apiSession: APISessionProviding

  func authenticate(
    _ publishableKey: PublishableKey
  ) -> AnyPublisher<
    AuthenticateResponse,
    Error
  > {
    return self.apiSession.execute(ApiRequest(ApiRouter.authenticate(
      publishableKey
    )))
      .eraseToAnyPublisher()
  }

  func createTrip(
    _ tripPayload: Payload,
    _ token: Token
  ) -> AnyPublisher<
    Trip,
    Error
  > {
    return self.apiSession.execute(ApiRequest(ApiRouter.tripCreate(
      tripPayload,
      token
    )))
      .eraseToAnyPublisher()
  }

  func completeTrip(_ tripId: TripId, _ token: Token) -> AnyPublisher<
    [String: String],
    Error
  > {
    return self.apiSession.execute(ApiRequest(ApiRouter.tripComplete(
      tripId,
      token
    )))
      .eraseToAnyPublisher()
  }

  func createGeofence(_ payload: Payload, _ token: Token) -> AnyPublisher<
    [Geofence],
    Error
  > {
    return self.apiSession.execute(ApiRequest(ApiRouter.createGeofence(token, payload)))
      .eraseToAnyPublisher()
  }
  
  func removeGeofence(_ geofenceId: GeofenceId, _ token: Token) -> AnyPublisher<
    Void,
    Error
  > {
    return self.apiSession.execute(ApiRequest(ApiRouter.removeGeofence(token, geofenceId)))
      .eraseToAnyPublisher()
  }

  func getDeepLink(_ token: String, _ email: String) -> AnyPublisher<
    String,
    Error
  > {
    return self.apiSession.execute(ApiRequest(ApiRouter.getDeepLink(token, email)))
      .eraseToAnyPublisher()
  }
  
  func startTracking(_ token: Token) -> AnyPublisher<Void, Error> {
    return self.apiSession.execute(ApiRequest(ApiRouter.startTracking(token)))
      .eraseToAnyPublisher()
  }

  func stopTracking(_ token: Token) -> AnyPublisher<Void, Error> {
    return self.apiSession.execute(ApiRequest(ApiRouter.stopTracking(token)))
      .eraseToAnyPublisher()
  }
  
  func masterAccount(_ token: Token) -> AnyPublisher<String, Error> {
    return self.apiSession.execute(ApiRequest(ApiRouter.masterAccount(token)))
      .eraseToAnyPublisher()
  }
}
