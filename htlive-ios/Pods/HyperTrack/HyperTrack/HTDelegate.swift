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
 The HyperTrack Error type enum.
 */
@objc public enum HyperTrackErrorCode: NSInteger {
    /**
     Error for key not set
     */
    case publishableKeyError = 100
    
    /**
     Error for user id not set
     */
    case userIdError = 102
    
    /**
     Error for location permissions
     */
    case locationPermissionsError = 104
    
    /**
     Error for location enabled
     */
    case locationDisabledError = 105
    
    /**
     Invalid location error
     */
    case invalidLocationError = 121
    
    /**
     Error while fetching ETA
     */
    case invalidETAError = 123
    
    /**
     Error for invalid parameters
     */
    case invalidParamsError = 131
    
    /**
     Error for malformed json
     */
    case jsonError = 142
    
    /**
     Error for server errors
     */
    case serverError = 141
    
    /**
     Unknown error
     */
    case unknownError = 151
}


/**
 The HyperTrack Error object. Contains an error type.
 */
@objc public class HyperTrackError: NSObject {
    
    /**
     Enum for various error types
     */
    @available(*, deprecated, message: "use HyperTrackError.errorCode and HyperTrackError.errorMessage")
    public let type: HyperTrackErrorType
    
    @objc public let errorCode: HyperTrackErrorCode
    @objc public let errorMessage: String
    
    init(_ type: HyperTrackErrorType) {
        self.type = type
        self.errorCode = HyperTrackError.getErrorCode(type)
        self.errorMessage = HyperTrackError.getErrorMessage(type)
    }
    
    internal func toDict() -> [String:Any] {
        let dict = [
            "code": self.errorCode.rawValue as Any,
            "message": self.errorMessage as Any
            ] as [String:Any]
        return dict
    }
    
    public func toJson() -> String {
        let dict = self.toDict()
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dict)
            let jsonString = String(data: jsonData, encoding: String.Encoding.utf8)
            return jsonString ?? ""
        } catch {
            HTLogger.shared.error("Error serializing object to JSON: " + error.localizedDescription)
            return ""
        }
    }
    
    static func getErrorCode(_ type: HyperTrackErrorType) -> HyperTrackErrorCode {
        switch type {
            /**
             Error for key not set
             */
        case HyperTrackErrorType.publishableKeyError:
            return HyperTrackErrorCode.publishableKeyError
            
            /**
             Error for user id not set
             */
        case HyperTrackErrorType.userIdError:
            return HyperTrackErrorCode.userIdError
            
            /**
             Error for location permissions
             */
        case HyperTrackErrorType.locationPermissionsError:
            return HyperTrackErrorCode.locationPermissionsError
            
            /**
             Error for location enabled
             */
        case HyperTrackErrorType.locationDisabledError:
            return HyperTrackErrorCode.locationDisabledError
            
            /**
             Invalid location error
             */
        case HyperTrackErrorType.invalidLocationError:
            return HyperTrackErrorCode.invalidLocationError
            
            /**
             Error while fetching ETA
             */
        case HyperTrackErrorType.invalidETAError:
            return HyperTrackErrorCode.invalidETAError
            
            /**
             Error for malformed json
             */
        case HyperTrackErrorType.jsonError:
            return HyperTrackErrorCode.jsonError
            
            /**
             Error for server errors
             */
        case HyperTrackErrorType.serverError:
            return HyperTrackErrorCode.serverError
            
            /**
             Error for invalid parameters
             */
        case HyperTrackErrorType.invalidParamsError:
            return HyperTrackErrorCode.invalidParamsError
            
            /**
             Unknown error
             */
        case HyperTrackErrorType.unknownError:
            return HyperTrackErrorCode.unknownError
        }
    }
    
    static func getErrorMessage(_ type: HyperTrackErrorType) -> String {
        switch type {
            /**
             Error for key not set
             */
        case HyperTrackErrorType.publishableKeyError:
            return "A publishable key has not been set"
            
            /**
             Error for user id not set
             */
        case HyperTrackErrorType.userIdError:
            return "A userId has not been set"
            
            /**
             Error for location permissions
             */
        case HyperTrackErrorType.locationPermissionsError:
            return "Location permissions are not enabled"
            
            /**
             Error for location enabled
             */
        case HyperTrackErrorType.locationDisabledError:
            return "Location services are not available"
            
            /**
             Invalid location error
             */
        case HyperTrackErrorType.invalidLocationError:
            return "Error fetching a valid Location"
            
            /**
             Error while fetching ETA
             */
        case HyperTrackErrorType.invalidETAError:
            return "Error while fetching eta. Please try again."
            
            /**
             Error for malformed json
             */
        case HyperTrackErrorType.jsonError:
            return "The server returned malformed json"
            
            /**
             Error for server errors
             */
        case HyperTrackErrorType.serverError:
            return "An error occurred communicating with the server"
            
            /**
             Error for invalid parameters
             */
        case HyperTrackErrorType.invalidParamsError:
            return "Invalid parameters supplied"
            
            /**
             Unknown error
             */
        case HyperTrackErrorType.unknownError:
            return "An unknown error occurred"
        }
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
