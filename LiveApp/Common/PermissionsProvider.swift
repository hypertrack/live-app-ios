import Combine
import CoreLocation
import CoreMotion
import HyperTrack
import Model
import SwiftUI

final class PermissionsProvider: NSObject {
  private let locationManager: CLLocationManager = CLLocationManager()
  private let motionActivityManager = CMMotionActivityManager()
  private let motionActivityQueue = OperationQueue()

  @Published var isFullAccessGranted: Bool = false
  @Published var locationPermissionsStatus: PermissionsStatus = .notDetermined
  @Published var motionPermissionsStatus: PermissionsStatus = .notDetermined

  enum PermissionsStatus {
    case granted
    case denied
    case notDetermined
  }

  override init() {
    super.init()
    locationManager.delegate = self
    checkPermissions()
  }

  public func requestPermissions() {
    requestLocationPermissions()
  }

  private func checkPermissions() {
    let motionAuthStatus = CMMotionActivityManager.authorizationStatus()
    let locationAuthStatus = CLLocationManager.authorizationStatus()
    switch (motionAuthStatus, locationAuthStatus) {
      case (.authorized, .authorizedAlways),
           (.authorized, .authorizedWhenInUse):
        DispatchQueue.main.async {
          self.isFullAccessGranted = true
          self.locationManager.requestAlwaysAuthorization()
        }
      default:
        DispatchQueue.main.async { self.isFullAccessGranted = false }
    }
    logPermissions.log("All permissions granted: \(isFullAccessGranted)")
  }

  private func requestLocationPermissions() {
    locationManager.requestWhenInUseAuthorization()
  }

  private func requestMotionPermissions() {
    if CMMotionActivityManager.isActivityAvailable() {
      motionActivityManager.queryActivityStarting(
        from: Date.distantPast, to: Date(), to: motionActivityQueue
      ) { [weak self] _, error in
        guard let self = self else { return }
        if error != nil {
          logPermissions.error("Motion Activity permissions denied")
          LiveEventPublisher.postError(
            error: HyperTrack.UnrestorableError.motionActivityPermissionsDenied
          )
          self.checkPermissions()
          DispatchQueue.main.async { self.motionPermissionsStatus = .denied }
        } else {
          logPermissions.log("Motion Activity permissions granted")
          DispatchQueue.main.async {
            self.checkPermissions()
            DispatchQueue.main.async { self.motionPermissionsStatus = .granted }
          }
        }
      }
    } else {
      logPermissions
        .fault("This is not an iPhone, or it doesn't have Motion Activity hardware")
      checkPermissions()
      motionPermissionsStatus = .denied
    }
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
        requestMotionPermissions()
        locationPermissionsStatus = .granted
      case .denied:
        LiveEventPublisher.postError(
          error: LiveError.locationPermissionsDenied
        )
        checkPermissions()
        requestMotionPermissions()
        DispatchQueue.main.async { self.locationPermissionsStatus = .denied }
      case .restricted:
        LiveEventPublisher.postError(
          error: LiveError.locationServicesDisabled
        )
        checkPermissions()
        requestMotionPermissions()
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
