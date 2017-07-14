//
//  HTTrackedUserStore.swift
//  HyperTrack
//
//  Created by Anil Giri on 28/04/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import Foundation
import CoreLocation

internal protocol TrackedUserStoreDelegate {
    func onActionsRemoved()
    func onTrackableUserFetch(userIds:[String])
    func onTrackableUserUpdate(userIds:[String])
}

struct TrackerConstants {
    static let minPollingFrequency = 5.0 //seconds
}

final class HTTrackedUserStore {
    var trackedUserDataSource = HTTrackedUserDataSource()
    var pollingTimer: Timer?
    var delegate : TrackedUserStoreDelegate?
    
    func getActionIds() -> [String]{
        return trackedUserDataSource.getActionIdsList()
    }
    
    func getAction(actionId : String) -> HyperTrackAction?{
        return trackedUserDataSource.getAction(actionId:actionId)
    }
    
    func getActions(actionIds : [String]) -> [HyperTrackAction]? {
        return trackedUserDataSource.getActions(actionIds: actionIds)
    }
    
    func getUserIds() ->[String]{
        return trackedUserDataSource.getUserIdsList()
    }
    
    func getActions(userId : String) -> [HyperTrackAction]?{
        return trackedUserDataSource.getActions(userId:userId)
    }
    
    func getActionIds(userId : String) -> [String]?{
        return trackedUserDataSource.getActionIds(userId:userId)
    }
    
    func getTrackedUser(userId : String) -> HTTrackedUser {
        return trackedUserDataSource.getTrackedUser(userId: userId);
    }
    
    func trackActionFor(_ actionID: String, completionHandler: ((_ actions: [HyperTrackAction]?,
        _ error: HyperTrackError?) -> Void)?) {
        
        self.fetchDetailsFor(actionID: actionID, completionHandler: { (users, error) in
            
            // Process trackAction response
            self.processTrackActionResponse(users, error, completionHandler: completionHandler)
        })
    }
    
    func trackActionFor(shortCode: String, completionHandler: ((_ actions: [HyperTrackAction]?,
        _ error: HyperTrackError?) -> Void)?) {
        
        RequestManager().fetchDetailsForActionsByShortCodes([shortCode], completionHandler: { (users, error) in
            
            // Process trackAction response
            self.processTrackActionResponse(users, error, completionHandler: completionHandler)
        })
    }
    
    func trackActionFor(lookUpId: String, completionHandler: ((_ actions: [HyperTrackAction]?,
        _ error: HyperTrackError?) -> Void)?) {
        
        if(lookUpId == trackedUserDataSource.lookupId){
            // LookupId is already being tracked
            if let completionHandler = completionHandler {
                completionHandler(self.trackedUserDataSource.getActionsList(), nil)
            }
            return
        }
        
        self.fetchDetailsFor(lookUpId: lookUpId, completionHandler: { (users, error) in
            // Process trackAction response
            self.trackedUserDataSource.lookupId = lookUpId
            self.processTrackActionResponse(users, error, completionHandler: completionHandler)
        })
    }
    
    func trackActionFor(actionIdsList: [String], completionHandler: ((_ actions: [HyperTrackAction]?,
        _ error: HyperTrackError?) -> Void)?) {
        var trackedActionList = [HyperTrackAction]()
        
        for (_, element) in actionIdsList.enumerated() {
            if((trackedUserDataSource.getAction(actionId: element)) != nil){
                let action = trackedUserDataSource.getAction(actionId: element)
                trackedActionList.append(action!)
            }
        }
        
        if(actionIdsList.count == trackedActionList.count){
            if let completionHandler = completionHandler {
                completionHandler(trackedActionList, nil)
            }
            return
        }
        
        self.fetchDetailsFor(actionIds: actionIdsList) { (users, error) in
            // Process trackAction response
            self.processTrackActionResponse(users, error, completionHandler: completionHandler)
        }
    }
    
    func removeActions(_ actionIds: [String]? = nil) {
        if (actionIds == nil) {
            self.clearAction()
            self.pollingTimer?.invalidate()
            self.delegate?.onActionsRemoved()
            return
        }
        
        // TODO - Add removeActions functionality for given set of actionIds
    }
    
    func getExpectedPlaceLocation(actionId:String) -> CLLocationCoordinate2D? {
        if let action = self.trackedUserDataSource.getAction(actionId: actionId){
            if let degrees = action.expectedPlace?.location?.coordinates {
                let destination = CLLocationCoordinate2DMake((degrees.last)!, (degrees.first)!)
                return destination
            }
        }
        return nil
    }
    
    func stopUpdatesTimer(){
        self.pollingTimer?.invalidate()
    }
    
    private func fetchDetailsFor(actionID: String,
                                 completionHandler: @escaping (_ users: [HTTrackedUser]?,
                                                               _ error: HyperTrackError?) -> Void) {
        RequestManager().fetchDetailsForActions([actionID]) { (users, error) in
            
            if let error = error {
                completionHandler(nil, error)
                return
            }
            
            if let users = users {
                completionHandler(users, nil)
            }
        }
    }
    
    private func fetchDetailsFor(actionIds: [String],
                                 completionHandler: @escaping (_ users: [HTTrackedUser]?,
                                                               _ error: HyperTrackError?) -> Void) {
        
        RequestManager().fetchUserDetailsForActions(actionIds) { (users, error) in
            if let error = error {
                completionHandler(nil, error)
                return
            }
            
            if let users = users {
                completionHandler(users, nil)
            }
        }
    }
    
    private func fetchDetailsFor(lookUpId: String,
                                 completionHandler: @escaping (_ users: [HTTrackedUser]?,
                                                               _ error: HyperTrackError?) -> Void) {
        RequestManager().fetchDetailsForActionsByLookUpId(lookUpId, completionHandler: { (users, error) in
            if let error = error {
                completionHandler(nil, error)
                return
            }
            
            if let users = users {
                completionHandler(users, nil)
            }
        })
    }
    
    private func processTrackActionResponse(_ users: [HTTrackedUser]?,
                                            _ error: HyperTrackError?,
                                            completionHandler: ((_ actions: [HyperTrackAction]?,
        _ error: HyperTrackError?) -> Void)?) {
        if (error != nil) {
            // Return error callback
            if let completionHandler = completionHandler {
                completionHandler(nil, error)
            }
            return
        }
        
        if let users = users {
            // Update Tracked Users and Actions
            self.clearAction()
            self.pollingTimer?.invalidate()
            self.trackedUserDataSource.addTrackedUsers(users: users)
            
            // Update data on the map
            self.delegate?.onTrackableUserFetch(userIds: self.trackedUserDataSource.getUserIdsList())
            
            // Start timer to poll for updates
            self.initializeTimer()
            
            // Return success callback
            if let completionHandler = completionHandler {
                completionHandler(self.trackedUserDataSource.getActionsList(), nil)
            }
        }
    }
    
    private func clearAction() {
        self.trackedUserDataSource.lookupId = nil
        self.trackedUserDataSource.trackedUsersMap.removeAll()
        self.trackedUserDataSource.trackedActionsMap.removeAll()
    }
    
    private func initializeTimer() {
        pollingTimer = Timer.scheduledTimer(timeInterval: TrackerConstants.minPollingFrequency,
                                            target: self, selector: #selector(updateLocations),
                                            userInfo: nil, repeats: true)
    }
    
    @objc private func updateLocations() {
        if let lookUpId = trackedUserDataSource.lookupId {
            fetchDetailsFor(lookUpId: lookUpId, completionHandler: { (users, error) in
                
                self.clearAction()
                self.trackedUserDataSource.lookupId = lookUpId
                self.trackedUserDataSource.addTrackedUsers(users: users)
                
                if (users != nil) {
                    self.delegate?.onTrackableUserUpdate(userIds: self.trackedUserDataSource.getUserIdsList())
                }
            })
            
        } else if trackedUserDataSource.getActionIdsList().count > 0  {
            fetchDetailsFor(actionIds: trackedUserDataSource.getActionIdsList(),
                            completionHandler: { (users, error) in
                
                self.clearAction()
                self.trackedUserDataSource.addTrackedUsers(users: users)
                
                if (users != nil) {
                    self.delegate?.onTrackableUserUpdate(userIds: self.trackedUserDataSource.getUserIdsList())
                }
            })
        }
    }
}
