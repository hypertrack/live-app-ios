import AWSMobileClient
import Combine
import HyperTrack
import Model
import Prelude

protocol ApiClientProvider {
  func signIn(
    _ username: String,
    _ password: String,
    _ completion: @escaping (Result<String, Error>) -> Void
  )
  func forgottenPassword(
    _ email: String,
    _ completion: @escaping (Result<Void, Error>) -> Void
  )
  func signUp(
    _ regModel: HyperTrackData,
    _ completion: @escaping (Result<Void, Error>) -> Void
  )
  func resendConfirmationCode(
    _ regModel: HyperTrackData,
    _ completion: @escaping (Result<Void, Error>) -> Void
  )
  func confirmSignUp(
    _ regModel: HyperTrackData,
    _ verifyCode: String,
    _ completion: @escaping (Result<Void, Error>) -> Void
  )
  func getDeepLink(
    _ regModel: HyperTrackData,
    _ email: String,
    _ completion: @escaping (Result<String, Error>) -> Void
  )
  func createTrip(
    _ destination: Place,
    _ regModel: HyperTrackData,
    _ completion: @escaping (Result<Trip, Error>) -> Void
  )
  func completeTrip(
    _ regModel: HyperTrackData,
    _ tripId: String,
    _ completion: @escaping (Result<Void, Error>) -> Void
  )
  func createGeofence(
    _ regModel: HyperTrackData,
    _ completion: @escaping (Result<Geofence, Error>) -> Void
  )
  func removeGeofence(
    _ regModel: HyperTrackData,
    _ completion: @escaping (Result<Void, Error>) -> Void
  )
  func startTracking(
    _ regModel: HyperTrackData,
    _ completion: @escaping (Result<Void, Error>) -> Void
  )
  func stopTracking(
    _ regModel: HyperTrackData,
    _ completion: @escaping (Result<Void, Error>) -> Void
  )
  func getMasterAccount(
    _ regModel: HyperTrackData,
    _ completion: @escaping (Result<String, Error>) -> Void
  )
  func signOut()
}

final class ApiClient: ApiClientProvider {
  let tripProvider: LiveApiProviding
  lazy var client: AWSMobileClient = AWSMobileClient(
    configuration: Constant.AWS.configuration
  )
  var cancellable: AnyCancellable?

  init() {
    logAuthentication.log("Initializing Cognito")
    tripProvider = LiveApiProvider(apiSession: ApiSession())
  }
}

extension ApiClient {
  func signIn(
    _ username: String,
    _ password: String,
    _ completion: @escaping (Result<String, Error>) -> Void
  ) {
    logAuthentication.log("Signing in")
    client.signOut()
    client
      .signIn(
        username: username.lowercased(),
        password: password
      ) { [weak self] result, error in
        guard let self = self else { return }
        if let result = result {
          logAuthentication
            .log("Signed in with current state: \(result.signInState)\nparameters: \(result.parameters)\ncode details: \(String(describing: result.codeDetails))")
          if case .signedIn = result.signInState {
            self.client.getTokens { tokens, error in

              logAuthentication.log(
                """
                Received response from Cognito
                tokens: \(String(describing: tokens))
                error: \(String(describing: error))
                """
              )
              if let tokens = tokens,
                let accessToken = tokens.idToken?.tokenString {
                logAuthentication
                  .log("AccessToken: \(String(describing: tokens.accessToken))\nidToken: \(String(describing: tokens.idToken))\nrefreshToken: \(String(describing: tokens.refreshToken))\nexpiration: \(String(describing: tokens.expiration))")
                let task = URLSession.shared.dataTask(
                  with: ApiRequest(ApiRouter.getHyperTrackToken(accessToken))
                    .urlRequest
                ) { data, _, error in
                  if let data = data,
                    let publishableKeyPair = convertToDictionary(
                      text: String(data: data, encoding: .utf8)!
                    ),
                    let publishableKey = publishableKeyPair[
                      Constant.ServerKeys.PublishableKey.key
                    ] {
                    logAuthentication
                      .log("Received publishable key: \(publishableKey)")
                    completion(.success(publishableKey))
                  } else if let error = error {
                    logAuthentication
                      .error("Failed to get publishable key with error: \(error)")
                    completion(.failure(error))
                  }
                }
                task.resume()
              } else {
                if let error = error {
                  logAuthentication
                    .error("Failed to get tokens from Cognito with error code: \(error) error: \(error.localizedDescription)")
                  completion(.failure(LiveError(error: error)))
                } else {
                  completion(.failure(LiveError.cognitoAuthNull))
                }
              }
            }
          }
        } else {
          if let error = error {
            logAuthentication
              .error("Failed to sign in using Cognito with error code: \(error) error: \(error.localizedDescription)")
            completion(.failure(LiveError(error: error)))
          } else {
            logAuthentication
              .error("Failed to obtain result or an error response from Cognito")
            completion(.failure(LiveError.cognitoAuthNull))
          }
        }
      }
  }

  func signUp(
    _ regModel: HyperTrackData,
    _ completion: @escaping (Result<Void, Error>) -> Void
  ) {
    guard let payload = regModel.convertToPayload() as? [String: String] else {
      completion(.failure(LiveError.unknown("Incorrect payload")))
      return
    }
    logAuthentication.log("Signing up")
    logAuthentication.log("Signing up payload: \(payload)")
    client.signUp(
      username: regModel.email.lowercased(),
      password: regModel.password,
      userAttributes: payload
    ) { signUpResult, error in
      if let signUpResult = signUpResult {
        logAuthentication.log("Signed up with result: \(signUpResult)")
        switch signUpResult.signUpConfirmationState {
          case .confirmed:
            logAuthentication.log("User is signed up and confirmed.")
            completion(.success(()))
          case .unconfirmed:
            logAuthentication
              .log("User is not confirmed and needs verification via \(signUpResult.codeDeliveryDetails!.deliveryMedium) sent at \(signUpResult.codeDeliveryDetails!.destination!)")
            completion(.success(()))
          case .unknown:
            logAuthentication.log("Sign up confirmation is in an unknown state")
            completion(.success(()))
        }
      } else {
        if let error = error {
          logAuthentication
            .error("Failed to sign up with error code: \(error) error: \(error.localizedDescription)")
          completion(.failure(error))
        } else {
          logAuthentication
            .error("Failed to obtain result or an error response from Cognito")
          completion(.failure(LiveError.cognitoAuthNull))
        }
      }
    }
  }

  func confirmSignUp(
    _ regModel: HyperTrackData,
    _ verifyCode: String,
    _ completion: @escaping (Result<Void, Error>) -> Void
  ) {
    logAuthentication.log("Confirming sign up")
    client.confirmSignUp(
      username: regModel.email,
      confirmationCode: verifyCode
    ) { signUpResult, error in
      if let signUpResult = signUpResult {
        logAuthentication
          .log("Confirmed signed up with result: \(signUpResult)")
        switch signUpResult.signUpConfirmationState {
          case .confirmed:
            logAuthentication.log("User is signed up and confirmed.")
          case .unconfirmed:
            logAuthentication
              .log("User is not confirmed and needs verification via \(signUpResult.codeDeliveryDetails!.deliveryMedium) sent at \(signUpResult.codeDeliveryDetails!.destination!)")
          case .unknown:
            logAuthentication.log("Sign up confirmation is in an unknown state")
        }
      } else {
        if let error = error {
          logAuthentication
            .error("Failed to confirm sign up with error code: \(error) error: \(error.localizedDescription)")
          completion(.failure(error))
        } else {
          logAuthentication
            .error("Failed to obtain signup confirmation or an error response from Cognito")
          completion(.failure(LiveError.cognitoAuthNull))
        }
      }
    }
  }

  func forgottenPassword(
    _ email: String,
    _ completion: @escaping (Result<Void, Error>) -> Void
  ) {
    logAuthentication.log("Sending forgot password request")
    client.forgotPassword(username: email.lowercased()) { forgotPasswordResult, error in
      if let result = forgotPasswordResult {
        logAuthentication
          .log("Successfuly sent confirm password request with result: \(result)")
        completion(.success(()))
      } else {
        if let error = error {
          logAuthentication
            .error("Failed to confirm password with error code: \(error) error: \(error.localizedDescription)")
          completion(.failure(error))
        } else {
          logAuthentication
            .error("Failed to obtain result or an error response from Cognito")
          completion(.failure(LiveError.cognitoAuthNull))
        }
      }
    }
  }

  func resendConfirmationCode(
    _ regModel: HyperTrackData,
    _ completion: @escaping (Result<Void, Error>) -> Void
  ) {
    logAuthentication.log("Re-sending forgot password request")
    client.resendSignUpCode(
      username: regModel.email,
      completionHandler: { result, error in
        if let signUpResult = result {
          logAuthentication
            .log("Successfuly re-sent confirm password request with result: \(signUpResult)")
          completion(.success(()))
        } else {
          if let error = error {
            logAuthentication
              .error("Failed to re-send confirm password request with error code: \(error) error: \(error.localizedDescription)")
            completion(.failure(error))
          } else {
            logAuthentication
              .error("Failed to obtain result or an error response from Cognito")
            completion(.failure(LiveError.cognitoAuthNull))
          }
        }
      }
    )
  }
  
  func createTrip(
    _ destination: Place,
    _ regModel: HyperTrackData,
    _ completion: @escaping (Result<Trip, Error>) -> Void
  ) {
    var payload = destination.convertToPayload()
    payload[Constant.ServerKeys.Trip.deviceId] = HyperTrack.deviceID
    logNetwork.log("Creating trip with payload: \(String(describing: payload as AnyObject))")
    guard let pk = regModel.publishableKey else {
      return completion(.failure(LiveError.unknown("Publishable key is empty")))
    }
    cancellable = tripProvider.authenticate(pk)
      .receive(on: RunLoop.main)
      .flatMap { self.tripProvider.createTrip(payload, $0.access_token) }
      .sink(
        receiveCompletion: {
        switch $0 {
          case .finished: break
          case let .failure(error):
            logNetwork.error("Failed to create trip with \(error)")
            completion(.failure(error))
        }
      }, receiveValue: {
        completion(.success($0))
      }
    )
  }


  func getDeepLink(
    _ regModel: HyperTrackData,
    _ email: String,
    _ completion: @escaping (Result<String, Error>) -> Void
  ) {
    logNetwork.log("Deep link")
    guard let pk = regModel.publishableKey else {
      return completion(.failure(LiveError.unknown("Publishable key is empty")))
    }
    cancellable = tripProvider.authenticate(pk)
      .receive(on: RunLoop.main)
      .flatMap { self.tripProvider.getDeepLink($0.access_token, email.lowercased()) }
      .sink(receiveCompletion: {
        switch $0 {
          case .finished: break
          case let .failure(error):
            logNetwork.error("Failed to inviteTeamMember with \(error)")
            completion(.failure(error))
        }
      }) {
        completion(.success(($0)))
      }
  }

  func completeTrip(
    _ regModel: HyperTrackData,
    _ tripId: String,
    _ completion: @escaping (Result<Void, Error>) -> Void
  ) {
    logNetwork.log("Completing trip with trip_id: \(tripId)")
    guard let pk = regModel.publishableKey else {
      return completion(.failure(LiveError.unknown("Publishable key is empty")))
    }
    cancellable = tripProvider.authenticate(pk)
      .receive(on: RunLoop.main)
      .flatMap { self.tripProvider.completeTrip(tripId, $0.access_token) }
      .sink(
        receiveCompletion: {
        switch $0 {
          case .finished: break
          case let .failure(error):
            logNetwork.error("Failed to completeTrip with \(error)")
            completion(.failure(error))
        }
      }, receiveValue: { _ in
        completion(.success(()))
      }
    )
  }
  
  func createGeofence(
    _ regModel: HyperTrackData,
    _ completion: @escaping (Result<Geofence, Error>) -> Void
  ) {
    
    guard let geofence = regModel.homeAddress else {
      return completion(.failure(LiveError.unknown("Geofence data is empty")))
    }
    
    var payload = geofence.convertToGeofencePayload()
    payload[Constant.ServerKeys.Geofence.deviceId] = HyperTrack.deviceID
    logNetwork.log("Create geofence with payload: \(String(describing: payload as AnyObject))")
    
    guard let pk = regModel.publishableKey else {
      return completion(.failure(LiveError.unknown("Publishable key is empty")))
    }
    cancellable = tripProvider.authenticate(pk)
      .receive(on: RunLoop.main)
      .flatMap { self.tripProvider.createGeofence(payload, $0.access_token) }
      .sink(
        receiveCompletion: {
        switch $0 {
          case .finished: break
          case let .failure(error):
            logNetwork.error("Failed to updateGeofence with \(error)")
            completion(.failure(error))
        }
      }, receiveValue: {
        completion(.success($0.first!))
      }
    )
  }
  
  func removeGeofence(_ regModel: HyperTrackData, _ completion: @escaping (Result<Void, Error>) -> Void) {
    logAuthentication.log("Remove geofence")
    guard let pk = regModel.publishableKey else {
      return completion(.failure(LiveError.unknown("Publishable key is empty")))
    }
    
    cancellable = tripProvider.authenticate(pk)
      .receive(on: RunLoop.main)
      .flatMap { self.tripProvider.removeGeofence(regModel.geofenceId, $0.access_token) }
      .sink(
        receiveCompletion: {
        switch $0 {
          case .finished: break
          case let .failure(error):
            logNetwork.error("Failed to updateGeofence with \(error)")
            completion(.failure(error))
        }
      }, receiveValue: { _ in completion(.success(())) }
    )
  }
  
  func startTracking(
    _ regModel: HyperTrackData,
    _ completion: @escaping (Result<Void, Error>) -> Void
  ) {
    logAuthentication.log("StartTracking")
    guard let pk = regModel.publishableKey else {
      return completion(.failure(LiveError.unknown("Publishable key is empty")))
    }
    cancellable = tripProvider.authenticate(pk)
      .receive(on: RunLoop.main)
      .flatMap { self.tripProvider.startTracking($0.access_token) }
      .sink(
        receiveCompletion: {
        switch $0 {
          case .finished: break
          case let .failure(error):
            logNetwork.error("Failed to startTracking with \(error)")
            completion(.failure(error))
        }
      }, receiveValue: { _ in
        completion(.success(()))
      }
    )
  }
  
  func stopTracking(
    _ regModel: HyperTrackData,
    _ completion: @escaping (Result<Void, Error>) -> Void
  ) {
    logAuthentication.log("StopTracking")
    guard let pk = regModel.publishableKey else {
      return completion(.failure(LiveError.unknown("Publishable key is empty")))
    }
    cancellable = tripProvider.authenticate(pk)
      .receive(on: RunLoop.main)
      .flatMap { self.tripProvider.stopTracking($0.access_token) }
      .sink(
        receiveCompletion: {
        switch $0 {
          case .finished: break
          case let .failure(error):
            logNetwork.error("Failed to stopTracking with \(error)")
            completion(.failure(error))
        }
      }, receiveValue: { _ in
        completion(.success(()))
      }
    )
  }
  
  func getMasterAccount(_ regModel: HyperTrackData, _ completion: @escaping (Result<String, Error>) -> Void) {
    logAuthentication.log("Get Master Account")
    guard let pk = regModel.publishableKey else {
      return completion(.failure(LiveError.unknown("Publishable key is empty")))
    }
    cancellable = tripProvider.authenticate(pk)
      .receive(on: RunLoop.main)
      .flatMap { self.tripProvider.masterAccount($0.access_token) }
      .sink(
        receiveCompletion: {
        switch $0 {
          case .finished: break
          case let .failure(error):
            logNetwork.error("Failed to getMasterAccount with \(error)")
            completion(.failure(error))
        }
      }, receiveValue: { completion(.success($0)) }
    )
  }
  
  func signOut() {
    client.signOut()
  }
}

