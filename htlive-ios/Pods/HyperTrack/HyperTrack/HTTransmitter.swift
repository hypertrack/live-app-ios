//
//  HTTransmitter.swift
//  HyperTrack
//
//  Created by Tapan Pandita on 23/02/17.
//  Copyright © 2017 HyperTrack, Inc. All rights reserved.
//

import Foundation
import Alamofire
import XCGLogger

let logger: XCGLogger = {
  
  let logger = XCGLogger(identifier: "HyperTrackLogger", includeDefaultDestinations: false)
  let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
  if let path = paths.first {
    let logPath = URL(fileURLWithPath: path.appending("/HyperTrack_Log.txt"), isDirectory: true)
    logger.setup(level: .debug, writeToFile: logPath, fileLevel: .debug)
  }
  let systemDestination = AppleSystemLogDestination(identifier: "HyperTrackLogger.systemDestination")
  systemDestination.outputLevel = .debug
  systemDestination.showLogIdentifier = false
  systemDestination.showFunctionName = true
  systemDestination.showThreadName = true
  systemDestination.showLevel = true
  systemDestination.showFileName = true
  systemDestination.showLineNumber = true
  systemDestination.showDate = true
  logger.add(destination: systemDestination)
  return logger
  
}()

final class Transmitter {
  static let sharedInstance = Transmitter()
  var delegate:HyperTrackDelegate? = nil
  let locationManager:LocationManager
  let eventsDatabaseManager: EventsDatabaseManager
  let requestManager: RequestManager
  

  var isTracking:Bool {
    get {
      return self.locationManager.isTracking
    }
  }

  init() {
    self.locationManager = LocationManager()
    self.eventsDatabaseManager = EventsDatabaseManager()
    self.eventsDatabaseManager.createEventsTable()
    self.requestManager = RequestManager()
  }

  func initialize() {
    if self.isTracking {
      self.startTracking(completionHandler: nil)
    } else {
      self.stopTracking(completionHandler: nil)
    }
  }

  func sync() {
    let isTracking = Settings.getTracking()
    if isTracking {
      self.startTracking(completionHandler: nil)
    }
  }

  func setUserId(userId:String) {
    Settings.setUserId(userId: userId)
  }

  func getUserId() -> String? {
    return Settings.getUserId()
  }

  func createUser(_ name:String, completionHandler: ((_ user: HyperTrackUser?, _ error: HyperTrackError?) -> Void)?) {
    self.requestManager.createUser(["name":name]) { user, error in

      if (user != nil) {
        Settings.setUserId(userId: (user?.id)!)
      } else if (error != nil) {
        debugPrint("Error creating user: ", error?.type.rawValue as Any)
      }

      if (completionHandler != nil) {
        completionHandler!(user, error)
      }
    }
  }
  
  func createUser(_ name: String, _ phone: String, _ photo: UIImage?, _ completionHandler: @escaping (_ user: HyperTrackUser?, _ error: HyperTrackError?) -> Void) {
    if let photo = photo {
      //Do image upload here, can't pass UIImage directly
    }
    
    if (name == nil || phone == nil) {
      completionHandler(nil, HyperTrackError.init(HyperTrackErrorType.invalidParamsError))
      return
    }

    self.requestManager.createUser(["name": name, "phone": phone]) { user, error in
      if (user != nil) {
        Settings.setUserId(userId: (user?.id)!)
      } else if (error != nil) {
        debugPrint("Error creating user: ", error?.type.rawValue as Any)
      }
      
      completionHandler(user, error)
    }
  }
  
  func createUser(_ name: String, _ phone: String, _ lookupID: String?, _ completionHandler: @escaping (_ user: HyperTrackUser?, _ error: HyperTrackError?) -> Void) {
    
    if (name == nil || phone == nil || lookupID == nil) {
      completionHandler(nil, HyperTrackError.init(HyperTrackErrorType.invalidParamsError))
      return
    }
    
    self.requestManager.createUser(["name": name, "phone": phone, "lookup_id": lookupID]) { user, error in
      if (user != nil) {
        Settings.setUserId(userId: (user?.id)!)
        Settings.setLookupId(lookupId: lookupID!)
      } else if (error != nil) {
        debugPrint("Error creating user: ", error?.type.rawValue as Any)
      }

      completionHandler(user, error)
    }
  }
  

  func setPublishableKey(publishableKey:String) {
    Settings.setPublishableKey(publishableKey: publishableKey)
  }
    
  func getPublishableKey() -> String? {
    return Settings.getPublishableKey()
  }

  func startTracking(completionHandler: ((_ error: HyperTrackError?) -> Void)?) {
    if (Settings.getUserId() == nil) {
      debugPrint("Can't start tracking. Need userId.")
      let error = HyperTrackError(HyperTrackErrorType.userIdError)
      delegate?.didFailWithError(error)

      guard let completionHandler = completionHandler else { return }
      completionHandler(error)
    } else if (Settings.getPublishableKey() == nil) {
      debugPrint("Can't start tracking. Need publishableKey.")
      let error = HyperTrackError(HyperTrackErrorType.publishableKeyError)
      delegate?.didFailWithError(error)

      guard let completionHandler = completionHandler else { return }
      completionHandler(error)
    } else {
      self.locationManager.startPassiveTrackingService()
      
      guard let completionHandler = completionHandler else { return }
      completionHandler(nil)
    }
  }

  func stopTracking(completionHandler: ((_ error: HyperTrackError?) -> Void)?) {
    self.locationManager.stopPassiveTrackingService()

    if (completionHandler != nil) {
      completionHandler!(nil)
    }
  }

  func getAction(_ actionId: String, _ completionHandler: @escaping (_ action: HyperTrackAction?, _ error: HyperTrackError?) -> Void) {
    self.requestManager.getAction(actionId) { action, error in
      if let action = action {
        completionHandler(action, nil)
      } else {
        completionHandler(nil, error)
      }
    }
  }

  func createAndAssignAction(_ expectedPlace: [String: Any], _ type: String, _ completionHandler: @escaping (_ action: HyperTrackAction?, _ error: HyperTrackError?) -> Void) {
    var action = [
      "user_id": Settings.getUserId() as Any,
      "type": type,
      "expected_place": expectedPlace,
    ] as [String: Any]

    if let currentLocation = Settings.getLastKnownLocation() {
      currentLocation.recordedAt = Date()
      action["current_location"] = currentLocation.toDict()
    }

    self.requestManager.assignAction(action) { action, error in
      if let action = action {
        completionHandler(action, nil)
      } else {
        completionHandler(nil, error)
      }
    }
  }

  func completeAction(actionId: String?) {
    guard let userId = self.getUserId() else { return }

    guard let actionId = actionId else {
      let event = HyperTrackEvent(userId: userId, recordedAt: Date(), eventType: "action.completed", location: Settings.getLastKnownLocation())
      event.save()
      self.requestManager.postEvents()
      return
    }

    let event = HyperTrackEvent(userId: userId, recordedAt: Date(), eventType: "action.completed", location: Settings.getLastKnownLocation(), data: ["action_id": actionId])
    event.save()
    self.requestManager.postEvents()
  }

  // Utility methods
  func requestWhenInUseAuthorization() {
    self.locationManager.requestWhenInUseAuthorization()
  }

  func requestAlwaysAuthorization() {
    self.locationManager.requestAlwaysAuthorization()
  }

  func callDelegateWithEvent(event: HyperTrackEvent) {
    delegate?.didReceiveEvent(event)
  }

  func callDelegateWithError(error: HyperTrackError) {
    delegate?.didFailWithError(error)
  }
}
