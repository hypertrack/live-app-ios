import Foundation
import Prelude

private let viewIndexUserDefaultsKey = "com.LiveApp.viewIndexUserDefaultsKey"

let liveUserDefaults: LiveUserDefaults = LiveUserDefaults()

public final class AppState {
  public var viewIndex: ViewIndex {
    get {
      return ViewIndex(
        rawValue: liveUserDefaults.integer(
          forKey: viewIndexUserDefaultsKey
        )
      ) ?? ViewIndex.onboardView
    }
    set {
      liveUserDefaults.set(
        newValue.rawValue,
        forKey: viewIndexUserDefaultsKey
      )
    }
  }

  public init() {}
}

public enum ViewIndex: Int {
  case onboardView
  case loginView
  case permissionsView
  case destinationInputListView
  case trackingMapView
  case primaryMapView
  case signUpView
  case tellusView
  case verifyView
  case forgotPasswordView
  case emailSentView
  case geofenceInputListView
  case editGeofenceView
  case deeplinkView
  case metadataView
  case homeAddressView
}
