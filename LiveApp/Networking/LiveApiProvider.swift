import Combine
import struct CoreLocation.CLLocationCoordinate2D
import HyperTrack
import Model
import SwiftUI

protocol LiveApiProviding {
  var apiSession: APISessionProviding { get }

  func authenticate(
    _ deviceId: DeviceId,
    _ publishableKey: PublishableKey
  ) -> AnyPublisher<
    AuthenticateResponse,
    Error
  >
  func createTrip(
    _ tripPayload: Payload,
    _ hyperTrack: HyperTrack,
    _ token: Token
  ) -> AnyPublisher<
    Trip,
    Error
  >
  func completeTrip(_ tripId: TripId, _ token: Token) -> AnyPublisher<
    [String: String],
    Error
  >
func createGeofence(_ payload: Payload, _ deviceId: DeviceId, _ token: Token) -> AnyPublisher<
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
  func startTracking(_ deviceId: DeviceId, _ token: Token) -> AnyPublisher<
    Void,
    Error
  >
  func stopTracking(_ deviceId: DeviceId, _ token: Token) -> AnyPublisher<
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
    _ deviceId: DeviceId,
    _ publishableKey: PublishableKey
  ) -> AnyPublisher<
    AuthenticateResponse,
    Error
  > {
    return self.apiSession.execute(ApiRequest(ApiRouter.authenticate(
      deviceId,
      publishableKey
    )))
      .eraseToAnyPublisher()
  }

  func createTrip(
    _ tripPayload: Payload,
    _ hyperTrack: HyperTrack,
    _ token: Token
  ) -> AnyPublisher<
    Trip,
    Error
  > {
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
      hyperTrack.syncDeviceSettings()
    }
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.5) {
      hyperTrack.syncDeviceSettings()
    }
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
      hyperTrack.syncDeviceSettings()
    }
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2.5) {
      hyperTrack.syncDeviceSettings()
    }
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

  func createGeofence(_ payload: Payload, _ deviceId: DeviceId, _ token: Token) -> AnyPublisher<
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
  
  func startTracking(_ deviceId: DeviceId, _ token: Token) -> AnyPublisher<Void, Error> {
    return self.apiSession.execute(ApiRequest(ApiRouter.startTracking(deviceId, token)))
      .eraseToAnyPublisher()
  }

  func stopTracking(_ deviceId: DeviceId, _ token: Token) -> AnyPublisher<Void, Error> {
    return self.apiSession.execute(ApiRequest(ApiRouter.stopTracking(deviceId, token)))
      .eraseToAnyPublisher()
  }
  
  func masterAccount(_ token: Token) -> AnyPublisher<String, Error> {
    return self.apiSession.execute(ApiRequest(ApiRouter.masterAccount(token)))
      .eraseToAnyPublisher()
  }
}
