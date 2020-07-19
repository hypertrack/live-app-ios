import AWSMobileClient
import HyperTrack
import Store

extension AWSMobileClientError {
  var message: String {
    switch self {
      case let .aliasExists(message),
           let .badRequest(message),
           let .codeDeliveryFailure(message),
           let .codeMismatch(message),
           let .cognitoIdentityPoolNotConfigured(message),
           let .deviceNotRemembered(message),
           let .errorLoadingPage(message),
           let .expiredCode(message),
           let .expiredRefreshToken(message),
           let .federationProviderExists(message),
           let .groupExists(message),
           let .guestAccessNotAllowed(message),
           let .idTokenAndAcceessTokenNotIssued(message),
           let .idTokenNotIssued(message),
           let .identityIdUnavailable(message),
           let .internalError(message),
           let .invalidConfiguration(message),
           let .invalidLambdaResponse(message),
           let .invalidOAuthFlow(message),
           let .invalidParameter(message),
           let .invalidPassword(message),
           let .invalidState(message),
           let .invalidUserPoolConfiguration(message),
           let .limitExceeded(message),
           let .mfaMethodNotFound(message),
           let .notAuthorized(message),
           let .notSignedIn(message),
           let .passwordResetRequired(message),
           let .resourceNotFound(message),
           let .scopeDoesNotExist(message),
           let .securityFailed(message),
           let .softwareTokenMFANotFound(message),
           let .tooManyFailedAttempts(message),
           let .tooManyRequests(message),
           let .unableToSignIn(message),
           let .unexpectedLambda(message),
           let .unknown(message),
           let .userCancelledSignIn(message),
           let .userLambdaValidation(message),
           let .userNotConfirmed(message),
           let .userNotFound(message),
           let .userPoolNotConfigured(message),
           let .usernameExists(message):
        return message
    }
  }
}

public struct APIErrorResponse: Decodable {
  public let message: String
}

public enum LiveError: Error {
  /// Network request error
  case badRequest
  case emptyResult
  case internalServerError
  case networkDisconnected
  case timedOutError
  case trialEnded
  case paymentDefault
  case authorizationFailed
  /// Permissions error
  case locationPermissionsDenied
  case locationPermissionsNotDetermined
  case locationServicesDisabled
  case locationServicesUnavalible
  case motionActivityServicesDisabled
  case motionActivityPermissionsDenied

  /// Other error
  case missingLocationUpdatesBackgroundModeCapability
  case runningOnSimulatorUnsupported
  case appSyncAuthError(String)
  case cognitoAuthNull
  case unknown(String)

  public init(trackingError: HyperTrack.TrackingError) {
    switch trackingError {
      case let .restorableError(restorableError):
        switch restorableError {
          case .locationPermissionsDenied,
               .locationPermissionsNotDetermined,
               .locationPermissionsRestricted,
               .locationPermissionsInsufficientForBackground,
               .locationPermissionsCantBeAskedInBackground,
               .motionActivityPermissionsCantBeAskedInBackground,
               .motionActivityPermissionsRestricted:
            self = .locationPermissionsDenied
          case .locationServicesDisabled:
            self = .locationServicesDisabled
          case .motionActivityServicesDisabled:
            self = .motionActivityServicesDisabled
          case .networkConnectionUnavailable:
            self = .networkDisconnected
          case .paymentDefault:
            self = .paymentDefault
          case .trialEnded:
            self = .trialEnded
        case .motionActivityPermissionsNotDetermined:
          self = .motionActivityPermissionsDenied
      }
      case let .unrestorableError(unrestorableError):
        switch unrestorableError {
          case .invalidPublishableKey:
            self = .authorizationFailed
          case .motionActivityPermissionsDenied:
            self = .motionActivityPermissionsDenied
        }
    }
  }

  public init(fatalError: HyperTrack.FatalError) {
    switch fatalError {
      case let .developmentError(devError):
        switch devError {
          case .missingLocationUpdatesBackgroundModeCapability:
            self = .missingLocationUpdatesBackgroundModeCapability
          case .runningOnSimulatorUnsupported:
            self = .runningOnSimulatorUnsupported
        }
      case let .productionError(prodError):
        switch prodError {
          case .locationServicesUnavalible:
            self = .locationServicesUnavalible
          case .motionActivityPermissionsDenied:
            self = .motionActivityPermissionsDenied
          case .motionActivityServicesUnavalible:
            self = .motionActivityServicesDisabled
        }
    }
  }

  public init(httpErrorCode: Int) {
    switch httpErrorCode {
      case 400:
        self = .badRequest
      case 401:
        self = .authorizationFailed
      case 403:
        self = .trialEnded
      case 500:
        self = .internalServerError
      case -1009:
        self = .networkDisconnected
      case -1001:
        self = .timedOutError
      default:
        self = .unknown("Can't identify http error code: \(httpErrorCode)")
    }
  }

  public init(message: String) {
    self = .unknown(message)
  }

  public init(error: Error) {
    if let error = error as? AWSMobileClientError {
      self = .appSyncAuthError(error.message)
    } else {
      self = .unknown(error.localizedDescription)
    }
  }
}

public func errorReducer(
  _ exceptionIdentifier: inout SheetIdentifier?,
  _ alertIdentifier: inout AlertIdentifier?,
  _ store: Store<AppState, Action>,
  _ error: LiveError
) {
  switch error {
    case .locationPermissionsDenied,
         .locationServicesDisabled,
         .motionActivityPermissionsDenied,
         .motionActivityServicesDisabled:
      if exceptionIdentifier == nil {
        exceptionIdentifier = SheetIdentifier(
          id: .permissionsSettings,
          content: error
        )
      } else {
        break
      }
    case .locationPermissionsNotDetermined:
      switch store.value.viewIndex {
        case .loginView, .onboardView, .permissionsView: break
        default:
          if exceptionIdentifier == nil {
            exceptionIdentifier = SheetIdentifier(
              id: .permissions,
              content: error
            )
          } else {
            break
          }
      }
    case .trialEnded:
      alertIdentifier = AlertIdentifier(id: .htError, content: error)
    default:
      alertIdentifier = AlertIdentifier(id: .htError, content: error)
  }
}

public func errorActionReducer(
  _ exceptionIdentifier: inout SheetIdentifier?,
  _ store: Store<AppState, Action>,
  _ error: LiveError
) {
  switch error {
    case .locationPermissionsDenied,
         .locationServicesDisabled,
         .motionActivityPermissionsDenied,
         .motionActivityServicesDisabled:
      if exceptionIdentifier == nil {
        exceptionIdentifier = SheetIdentifier(id: .permissions, content: error)
      } else {
        break
      }
    case .locationServicesUnavalible: break
    case .authorizationFailed:
      store.update(.updateFlow(.loginView))
    case .badRequest: break
    case .internalServerError: break
    case .missingLocationUpdatesBackgroundModeCapability: break
    case .networkDisconnected: break
    case .paymentDefault: break
    case .runningOnSimulatorUnsupported: break
    case .timedOutError: break
    case .trialEnded: break
    case .unknown: break
    case .emptyResult: break
    case .locationPermissionsNotDetermined: break
    case .appSyncAuthError,
         .cognitoAuthNull:
      store.update(.updateFlow(.loginView))
  }
}
