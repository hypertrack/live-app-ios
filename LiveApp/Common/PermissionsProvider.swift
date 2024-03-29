import Combine
import CoreLocation
import HyperTrack
import Model
import SwiftUI

final class PermissionsProvider: NSObject {
  private let locationManager: CLLocationManager = CLLocationManager()
  private var timer: Timer?

  @Published var isFullAccessGranted: Bool = false
  @Published var locationPermissionsStatus: PermissionsStatus = .notDetermined

  enum PermissionsStatus {
    case granted
    case denied
    case notDetermined
  }

  override init() {
    super.init()
    locationManager.delegate = self
    self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
      self?.checkPermissions()
    }
    NotificationCenter.default.addObserver(self, selector: #selector(appBecameActive), name: UIApplication.didBecomeActiveNotification, object: nil)
  }

  deinit {
      self.timer?.invalidate()
      self.timer = nil
  }

  @objc func appBecameActive() {
    checkPermissions()
  }

  public func requestPermissions() {
    requestLocationPermissions()
  }

  private func checkPermissions() {
    let locationAuthStatus = CLLocationManager.authorizationStatus()
    switch locationAuthStatus {
      case .authorizedAlways, .authorizedWhenInUse:
        DispatchQueue.main.async {
          self.isFullAccessGranted = true
          self.locationManager.requestAlwaysAuthorization()
          self.timer?.invalidate()
        }
      default:
        DispatchQueue.main.async { self.isFullAccessGranted = false }
    }
    logPermissions.log("All permissions granted: \(isFullAccessGranted)")
  }

  private func requestLocationPermissions() {
    locationManager.requestWhenInUseAuthorization()
  }
}

extension CLAuthorizationStatus: CustomStringConvertible {
  public var description: String {
    switch self {
      case .notDetermined:
        return "Not Determined"
      case .restricted:
        return "Restricted"
      case .denied:
        return "Denied"
      case .authorizedAlways:
        return "Authorized Always"
      case .authorizedWhenInUse:
        return "Authorized When In Use"
      @unknown default:
        return "Unknown"
    }
  }
}

extension PermissionsProvider: CLLocationManagerDelegate {
  public func locationManager(
    _: CLLocationManager,
    didChangeAuthorization status: CLAuthorizationStatus
  ) {
    logPermissions.log("Location authorization: \(status)")

    var updatedStatus: CLAuthorizationStatus = status
    if CLLocationManager.locationServicesEnabled() == false {
      updatedStatus = .restricted
    }
    switch updatedStatus {
      case .authorizedAlways, .authorizedWhenInUse:
        checkPermissions()
        locationPermissionsStatus = .granted
      case .denied:
        LiveEventPublisher.postError(
          error: LiveError.locationPermissionsDenied
        )
        checkPermissions()
        DispatchQueue.main.async { self.locationPermissionsStatus = .denied }
      case .restricted:
        LiveEventPublisher.postError(
          error: LiveError.locationServicesDisabled
        )
        checkPermissions()
        DispatchQueue.main.async { self.locationPermissionsStatus = .denied }
      case .notDetermined:
        LiveEventPublisher.postError(
          error: LiveError.locationPermissionsNotDetermined
        )
        checkPermissions()
        DispatchQueue.main
          .async { self.locationPermissionsStatus = .notDetermined }
      @unknown default: return
    }
  }
}
