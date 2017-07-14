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
    /**
     Error for key not set
     */
    case publishableKeyError = "A publishable key has not been set"
    
    /**
     Error for user id not set
     */
    case userIdError = "A userId has not been set"
    
    /**
     Error for location permissions
     */
    case locationPermissionsError = "Location permissions are not enabled"
    
    /**
     Error for location enabled
     */
    case locationDisabledError = "Location services are not available"
    
    /**
     Invalid location error
     */
    case invalidLocationError = "Error fetching a valid Location"
    
    /**
     Error while fetching ETA
     */
    case invalidETAError = "Error while fetching eta. Please try again."
    
    /**
     Error for malformed json
     */
    case jsonError = "The server returned malformed json"
    
    /**
     Error for server errors
     */
    case serverError = "An error occurred communicating with the server"
    
    /**
     Error for invalid parameters
     */
    case invalidParamsError = "Invalid parameters supplied"
    
    /**
     Unknown error
     */
    case unknownError = "An unknown error occurred"
}


/**
 The HyperTrack Error object. Contains an error type.
 */
@objc public class HyperTrackError: NSObject {
    
    /**
     Enum for various error types
     */
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
