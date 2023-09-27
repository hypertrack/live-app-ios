import Foundation
import HyperTrack
import UIKit

public struct ContentModel {
  public let title: String
  public let subTitle: String
  public let controlTitle: String
  public let deepLink: String?

  public init(_ createContent: ContentType) {
    switch createContent {
      case .default:
        title = "Welcome to HyperTrack Live!"
        subTitle =
          "We need your permission to access your Location to track and share your live location."
        controlTitle = "Allow access"
        deepLink = "\(UIApplication.openSettingsURLString)"
      case let .custom(title, subTitle, controlTitle, deepLink):
        self.title = title
        self.subTitle = subTitle
        self.controlTitle = controlTitle
        self.deepLink = deepLink
    }
  }
}

public enum ContentType {
  case `default`
  case custom(
    title: String,
    subTitle: String,
    controlTitle: String,
    deepLink: String? = nil
  )
}

extension ContentModel {
  public static func getContentForLiveError(
    _ error: LiveError
  ) -> ContentModel {
    let title: String
    let subTitle: String
    let controlTitle: String
    let deepLink: String?

    switch error {
      case .locationPermissionsDenied:
        title = "Welcome to HyperTrack Live!"
        subTitle =
          "We need your permission to access your Location to track and share your live location."
        controlTitle = "Allow access"
        deepLink = "\(UIApplication.openSettingsURLString)"
      case .locationServicesDisabled:
        title = "Welcome to HyperTrack Live!"
        subTitle =
          "We need your permission to access your Location to track and share your live location."
        controlTitle = "Allow access"
        deepLink = "\(UIApplication.openSettingsURLString)"
      case .authorizationFailed:
        title = "Invalid Publishable Key"
        subTitle = "Publishable Key wan't found in HyperTrack's database."
        controlTitle = ""
        deepLink = nil
      case .networkDisconnected:
        title = "Network Connection Unavailable"
        subTitle = "The Internet connection appears to be offline."
        controlTitle = ""
        deepLink = nil
      case .paymentDefault:
        title = "Payment Default"
        subTitle = "There was an error processing your payment."
        controlTitle = ""
        deepLink = nil
      case .trialEnded:
        title = "Free events expired this month"
        subTitle = "Upgrade to production plan."
        controlTitle = ""
        deepLink = nil
      case .badRequest:
        title = "Network error"
        subTitle = "Bad request"
        controlTitle = ""
        deepLink = nil
      case .internalServerError:
        title = "Network error"
        subTitle = "Internal server error"
        controlTitle = ""
        deepLink = nil
      case .missingLocationUpdatesBackgroundModeCapability:
        title = "Capability error"
        subTitle = "Please, turn on background mode capability"
        controlTitle = ""
        deepLink = nil
      case .locationServicesUnavalible:
        title = "Location error"
        subTitle = "HyperTrack can't run on device without GPS module"
        controlTitle = ""
        deepLink = nil
      case .emptyResult:
        title = "Empty result"
        subTitle = "The result of this operation is empty."
        controlTitle = ""
        deepLink = nil
      case let .unknown(errorMessage):
        title = "Unexpected error"
        subTitle = errorMessage
        controlTitle = ""
        deepLink = nil
      case let .networkError(errorMessage):
        title = "Unexpected connection error"
        subTitle =  "Check your network connection and try again." + "\n\n" + errorMessage
        controlTitle = ""
        deepLink = nil
      case .locationPermissionsNotDetermined:
        title = "Welcome to HyperTrack Live!"
        subTitle =
          "We need your permission to access your Location to track and share your live location."
        controlTitle = "Allow access"
        deepLink = "\(UIApplication.openSettingsURLString)"
      case let .appSyncAuthError(errorMessage):
        title = "Authorization expired"
        subTitle = errorMessage
        controlTitle = ""
        deepLink = nil
      case .cognitoAuthNull:
        title = "Authorization expired"
        subTitle =
          "Your authentication expired, please sign-in again to continue using the app."
        controlTitle = ""
        deepLink = nil
    }
    return ContentModel(.custom(
      title: title,
      subTitle: subTitle,
      controlTitle: controlTitle,
      deepLink: deepLink
    ))
  }
}
