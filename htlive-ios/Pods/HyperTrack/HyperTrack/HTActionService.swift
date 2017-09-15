//
//  HTActionService.swift
//  HyperTrack
//
//  Created by Ravi Jain on 8/5/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import UIKit

class HTActionService: NSObject {

    static let sharedInstance = HTActionService()
    
    let requestManager: RequestManager

    override init() {
        self.requestManager = RequestManager()
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
    
    func getActionFromShortCode(_ shortCode:String,_ completionHandler: @escaping (_ action: [HyperTrackAction]?, _ error: HyperTrackError?) -> Void) {
        self.requestManager.getActionFromShortCode(shortCode) { action, error in
            if let action = action {
                completionHandler(action, nil)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    func createAndAssignAction(_ actionParams:HyperTrackActionParams, _ completionHandler: @escaping (_ action: HyperTrackAction?, _ error: HyperTrackError?) -> Void) {
        
        var action = [
            "user_id": Settings.getUserId() as Any,
            "type": actionParams.type as Any,
            "expected_at": actionParams.expectedAt as Any,
            "lookup_id":actionParams.lookupId as Any
            ] as [String: Any]
        
        if let expectedPlace = actionParams.expectedPlace {
            action["expected_place"] = expectedPlace.toDict() as Any
        } else if let expectedPlaceID = actionParams.expectedPlaceId {
            action["expected_place_id"] = expectedPlaceID as Any
        } else {
            completionHandler(nil, HyperTrackError(HyperTrackErrorType.invalidParamsError))
            return
        }
        
        Transmitter.sharedInstance.getCurrentLocation(completionHandler: { (currentLocation, error) in
            if (currentLocation != nil) {
                action["current_location"] = HyperTrackLocation.init(locationCoordinate: currentLocation!.coordinate,
                                                                     timeStamp: Date()).toDict()
            }
        })
        
        self.requestManager.createAndAssignAction(action, completionHandler: completionHandler)
    }
    
    func assignActions(_ actionIds: [String], _ completionHandler: @escaping (_ action: HyperTrackUser?,
        _ error: HyperTrackError?) -> Void) {
        if (actionIds.isEmpty) {
            completionHandler(nil, HyperTrackError(HyperTrackErrorType.invalidParamsError))
            return
        }
        
        guard let userId = Settings.getUserId() else {
            completionHandler(nil, HyperTrackError(HyperTrackErrorType.userIdError))
            return
        }
        
        var params = [
            "action_ids":actionIds as Any
            ] as [String: Any]
        
        Transmitter.sharedInstance.getCurrentLocation(completionHandler: { (currentLocation, error) in
            if (currentLocation != nil) {
                params["current_location"] = HyperTrackLocation.init(locationCoordinate: currentLocation!.coordinate,
                                                                     timeStamp: Date()).toDict()
            }
        })
        
        self.requestManager.assignActions(userId: userId, params, completionHandler: completionHandler)
    }
    
    func completeAction(actionId: String?) {
        guard let userId = Settings.getUserId() else { return }
        if(actionId != nil){
            let nc = NotificationCenter.default
            let userInfo = ["actionId" : actionId]
            nc.post(name:Notification.Name(rawValue:HTConstants.HTTrackingStopedForAction),
                    object: nil,
                    userInfo: userInfo)
        }
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
    
    func cancelPendingActions(completionHandler: ((_ user: HyperTrackUser?, _ error: HyperTrackError?) -> Void)?) {
        guard let userId = Settings.getUserId() else {
            if let completion = completionHandler {
                completion(nil, HyperTrackError.init(HyperTrackErrorType.invalidParamsError))
            }
            return
        }
        
        self.requestManager.cancelActions(userId: userId, completionHandler: completionHandler)
    }
    
    /**
     Method to track Action for an ActionID
     */
    func trackActionFor(actionID: String, completionHandler: ((_ action: HyperTrackAction?, _ error: HyperTrackError?) -> Void)?) {
        HTMap.sharedInstance.trackActionFor(actionID: actionID, completionHandler: completionHandler)
    }
    
    /**
     Method to track Action for an action's Short code
     */
    func trackActionFor(shortCode: String, completionHandler: ((_ action: HyperTrackAction?, _ error: HyperTrackError?) -> Void)?) {
        HTMap.sharedInstance.trackActionFor(shortCode: shortCode, completionHandler: completionHandler)
    }
    
    /**
     Method to track Action for an action's LookupId
     */
    func trackActionFor(lookUpId: String, completionHandler: ((_ actions: [HyperTrackAction]?, _ error: HyperTrackError?) -> Void)?) {
        HTMap.sharedInstance.trackActionFor(lookUpId: lookUpId, completionHandler: completionHandler)
    }
    
    
    public func removeActions(_ actionIds: [String]? = nil) {
        // Clear action, which would clear the marker and
        // HTView UI elements
        HTMap.sharedInstance.removeActions()
    }
    
    func removeActionForLookUpId(lookUpId : String){
        HTMap.sharedInstance.removeActions()
        if (lookUpId == HTConsumerClient.sharedInstance.trackedUserStore?.trackedUserDataSource.lookupId){
            HTConsumerClient.sharedInstance.trackedUserStore?.trackedUserDataSource.lookupId = nil
        }
    }
    
    func isActionTrackable(actionId : String!,completionHandler: @escaping (_ isTrackable: Bool, _ error: HyperTrackError?) -> Void ) {
        
        self.getAction(actionId) { (action, error) in
            if(action != nil){
                completionHandler((action?.isActionTrackable())!,nil)
                return
            }
            
            completionHandler(false,error)
            return
            
        }
    }


}
