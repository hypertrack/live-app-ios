import Foundation
import MapKit
import Prelude

private let nameDefaultsKey = "com.LiveApp.nameDefaultsKey"
private let phoneDefaultsKey = "com.LiveApp.phoneDefaultsKey"
private let emailKeyDefaultsKey = "com.LiveApp.emailKeyDefaultsKey"
private let tripIdKeyDefaultsKey = "com.LiveApp.tripIdKeyDefaultsKey"
private let appGoalKeyDefaultsKey = "com.LiveApp.appGoalKeyDefaultsKey"
private let geofenceIdDefaultsKey = "com.LiveApp.geofenceIdDefaultsKey"
private let passwordKeyDefaultsKey = "com.LiveApp.passwordKeyDefaultsKey"
private let homeAddressDefaultsKey = "com.LiveApp.homeAddressDefaultsKey"
private let historyListDefaultsKey = "com.LiveApp.historyListDefaultsKey"
private let publishableKeyDefaultsKey = "com.LiveApp.publishableKeyDefaultsKey"
private let userRegDataKeyDefaultsKey = "com.LiveApp.userRegDataKeyDefaultsKey"
private let companyNameKeyDefaultsKey = "com.LiveApp.companyNameKeyDefaultsKey"
private let isSignedInFromDeeplinkDefaultsKey = "isSignedInFromDeeplinkDefaultsKey"
private let appDeviceCountKeyDefaultsKey = "com.LiveApp.appDeviceCountKeyDefaultsKey"
private let appProductStateKeyDefaultsKey = "com.LiveApp.appProductStateKeyDefaultsKey"
private let masterAccountEmailKeyDefaultsKey = "com.LiveApp.masterAccountEmailKeyDefaultsKey"
private let trackingMapViewShareVisibilityStatusDefaultsKey = "com.LiveApp.trackingMapViewShareVisibilityStatusDefaultsKey"

public final class HyperTrackData {
  public var publishableKey: String? {
    get { return liveUserDefaults.string(forKey: publishableKeyDefaultsKey) }
    set { newValue == nil ? liveUserDefaults.removeObject(
      forKey: publishableKeyDefaultsKey
    ) : liveUserDefaults.set(newValue, forKey: publishableKeyDefaultsKey) }
  }

  public var isSignedInFromDeeplink: Bool {
    get { return liveUserDefaults.bool(
      forKey: isSignedInFromDeeplinkDefaultsKey
    ) }
    set { liveUserDefaults.set(
      newValue,
      forKey: isSignedInFromDeeplinkDefaultsKey
    ) }
  }

  public var tripId: String? {
    get { return liveUserDefaults.string(forKey: tripIdKeyDefaultsKey) }
    set { newValue == nil ? liveUserDefaults.removeObject(
      forKey: tripIdKeyDefaultsKey
    ) : liveUserDefaults.set(newValue, forKey: tripIdKeyDefaultsKey) }
  }

  public var companyName: String {
    get { return liveUserDefaults.string(forKey: tripIdKeyDefaultsKey) ?? "" }
    set { liveUserDefaults.set(newValue, forKey: tripIdKeyDefaultsKey) }
  }
  
  public var geofenceId: String {
    get { return liveUserDefaults.string(forKey: geofenceIdDefaultsKey) ?? "" }
    set { liveUserDefaults.set(newValue, forKey: geofenceIdDefaultsKey) }
  }

  public var email: String {
    get { return liveUserDefaults.string(forKey: emailKeyDefaultsKey) ?? "" }
    set { liveUserDefaults.set(newValue, forKey: emailKeyDefaultsKey) }
  }
  
  public var masterAccountEmail: String {
    get { return liveUserDefaults.string(forKey: masterAccountEmailKeyDefaultsKey) ?? "" }
    set { liveUserDefaults.set(newValue, forKey: masterAccountEmailKeyDefaultsKey) }
  }

  public var password: String {
    get { return liveUserDefaults.string(forKey: passwordKeyDefaultsKey) ?? "" }
    set { liveUserDefaults.set(newValue, forKey: passwordKeyDefaultsKey) }
  }

  public var appGoal: String {
    get { return liveUserDefaults.string(forKey: appGoalKeyDefaultsKey) ?? "" }
    set { liveUserDefaults.set(newValue, forKey: appGoalKeyDefaultsKey) }
  }

  public var name: String {
    get { return liveUserDefaults.string(forKey: nameDefaultsKey) ?? "" }
    set { liveUserDefaults.set(newValue, forKey: nameDefaultsKey) }
  }

  public var phone: String {
    get { return liveUserDefaults.string(forKey: phoneDefaultsKey) ?? "" }
    set { liveUserDefaults.set(newValue, forKey: phoneDefaultsKey) }
  }

  public var homeAddress: Place? {
    get { return Place.retrievePlace(
      liveUserDefaults,
      forKey: homeAddressDefaultsKey
    ) }
    set { Place.savePlace(
      newValue,
      liveUserDefaults,
      forKey: homeAddressDefaultsKey
    ) }
  }

  public var historyList: [Place] {
    get { return Place.getArray(
      liveUserDefaults,
      forKey: historyListDefaultsKey
    ) }
    set { Place.setArray(
      liveUserDefaults,
      newValue,
      forKey: historyListDefaultsKey
    ) }
  }

  public var shareVisibilityStatus: Bool {
    get { return liveUserDefaults.bool(
      forKey: trackingMapViewShareVisibilityStatusDefaultsKey
    ) }
    set { liveUserDefaults.set(
      newValue,
      forKey: trackingMapViewShareVisibilityStatusDefaultsKey
    ) }
  }

  public var appProductState: String {
    get {
      return liveUserDefaults
        .string(forKey: appProductStateKeyDefaultsKey) ?? ""
    }
    set { liveUserDefaults.set(newValue, forKey: appProductStateKeyDefaultsKey)
    }
  }

  public var errorMessage: String = ""

  public init() {}

  public enum Action {
    case insertPublishableKey(String)
    case completedTrip
    case insertTripId(String)
    case updateEmail(String)
    case updatePass(String)
    case updateRegistrationData(
      companyName: String,
      email: String,
      password: String
    )
    case updateAppGoal(String)
    case updateAppProductState(String)
    case removeRegData
    case updateShareVisibilityStatus(Bool)
    case saveLocationResult(Place)
    case updateHomeAddress(Place)
    case updateName(String)
    case updatePhone(String)
    case updateSignedInFromDeeplink(Bool)
    case updateGeofenceId(String)
    case signOut
  }

  public func update(_ action: Action) {
    switch action {
      case let .insertPublishableKey(pk):
        publishableKey = pk
      case let .insertTripId(tripId):
        self.tripId = tripId
      case .completedTrip:
        tripId = nil
      case let .updateRegistrationData(companyName, email, password):
        self.companyName = companyName
        self.email = email
        self.password = password
      case let .updateAppGoal(goal):
        appGoal = goal
      case let .updateAppProductState(productState):
        appProductState = productState
      case .removeRegData:
        companyName = ""
        appProductState = ""
        appGoal = ""
        errorMessage = ""
      case let .updateShareVisibilityStatus(newValue):
        shareVisibilityStatus = newValue
      case let .saveLocationResult(newValue):
        historyList.insert(newValue, at: 0)
      case let .updateHomeAddress(address):
        homeAddress = address
      case .signOut:
        publishableKey = nil
        tripId = nil
        geofenceId = ""
        companyName = ""
        appProductState = ""
        appGoal = ""
        errorMessage = ""
        name = ""
        phone = ""
        homeAddress = nil
        historyList = []
        shareVisibilityStatus = false
      case let .updatePass(pass):
        password = pass
      case let .updateEmail(email):
        self.email = email
      case let .updateName(name):
        self.name = name
      case let .updatePhone(phone):
        self.phone = phone
      case let .updateSignedInFromDeeplink(state):
        isSignedInFromDeeplink = state
      case let .updateGeofenceId(id):
        geofenceId = id
    }
  }
}
