//
//  HTDelegate.swift
//  HyperTrack
//
//  Created by Tapan Pandita on 02/03/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import Foundation


/**
 The HyperTrack Error type enum.
 */
public enum HyperTrackErrorType:String {
  case publishableKeyError = "A publishable key has not been set"
  case userIdError = "A userId has not been set"
  case locationPermissionsError = "Location permissions are not enabled"
  case locationDisabledError = "Location services are not available"
  case jsonError = "The server returned malformed json"
  case serverError = "An error occurred communicating with the server"
  case unknownError = "An unknown error occurred"
  case invalidParamsError = "Invalid parameters supplied"
}


/**
 The HyperTrack Error object. Contains an error type.
 */
@objc public class HyperTrackError: NSObject {
  public let type:HyperTrackErrorType

  init(_ type: HyperTrackErrorType) {
    self.type = type
  }
}


/**
 The delegate protocol that you can extend to receive events and errors as they occur
 */
@objc public protocol HyperTrackDelegate: class {
  /**
   Set this method to receive events on the delegate

   - Parameter event: The event that occurred
   */
  func didReceiveEvent(_ event: HyperTrackEvent)
  /**
   Set this method to receive errors on the delegate

   - Parameter error: The error that occurred
   */
  func didFailWithError(_ error:HyperTrackError)
}
