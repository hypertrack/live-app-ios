//
//  HTConsumerClient.swift
//  Pods
//
//  Created by Ravi Jain on 03/06/17.
//
//

import UIKit
import MapKit

internal protocol HTConsumerClientDelegate {
    func onActionsRemoved()
    func onUserListUpdated()
    func onUserListChanged()
    func onActionStatusChanged(actionIds:[String],actions:[HyperTrackAction])
    func onActionStatusRefreshed(actionIds:[String],actions:[HyperTrackAction])
}

class HTConsumerClient: NSObject, TrackedUserStoreDelegate {
    
    static let sharedInstance = HTConsumerClient()
    let trackedUserStore : HTTrackedUserStore?
    var currentActionStatusList = [String:String]()
    var delegate : HTConsumerClientDelegate?
    
    private override init(){
        self.trackedUserStore = HTTrackedUserStore()
        super.init()
        self.trackedUserStore?.delegate = self
    }
    
    func getLastActionId(userId : String) -> String? {
        let actionIds = trackedUserStore?.getActionIds(userId: userId)
        if (actionIds != nil) {
            return actionIds!.last
        }
        return nil
    }
    
    func getAction(actionId:String) -> HyperTrackAction?{
        return self.trackedUserStore?.getAction(actionId:actionId)
    }
    
    func getUserIds() -> [String]{
        return (self.trackedUserStore?.getUserIds())!
    }
    
    func getActionIds() -> [String]{
        return (self.trackedUserStore?.getActionIds())!
    }

    func getActionIds(userId : String) ->  [String]?{
        return self.trackedUserStore?.getActionIds(userId: userId)
    }
    
    func getActions(userId : String) ->  [HyperTrackAction]?{
        return self.trackedUserStore?.getActions(userId: userId)
    }
    
    func getUser(userId:String) -> HTTrackedUser?{
        return self.trackedUserStore?.getTrackedUser(userId:userId)
    }
    
    func getExpectedPlaceLocation(actionId:String) -> CLLocationCoordinate2D? {
        return self.trackedUserStore?.getExpectedPlaceLocation(actionId:actionId)
    }
    
    func trackActionFor(_ actionID: String, delegate: HTConsumerClientDelegate,
                        completionHandler: ((_ actions: HyperTrackAction?, _ error: HyperTrackError?) -> Void)?) {
        self.delegate = delegate
        trackedUserStore?.trackActionFor(actionID, completionHandler: { (actions, error) in
            if (error != nil) {
                if let completionHandler = completionHandler {
                    completionHandler(nil, error)
                }
                return
            }
            
            if let actions = actions {
                if let completionHandler = completionHandler {
                    completionHandler(actions.first, error)
                }
            }
        })
    }
    
    func trackActionFor(shortCode: String, delegate: HTConsumerClientDelegate,
                        completionHandler: ((_ action: HyperTrackAction?, _ error: HyperTrackError?) -> Void)?) {
        self.delegate = delegate
        trackedUserStore?.trackActionFor(shortCode: shortCode, completionHandler: { (actions, error) in
            if (error != nil) {
                if let completionHandler = completionHandler {
                    completionHandler(nil, error)
                }
                return
            }
            
            if let actions = actions, let action = actions.first {
                self.currentActionStatusList = [String:String]()
                self.currentActionStatusList[action.id!] = action.status
                
                if let completionHandler = completionHandler {
                    completionHandler(action, nil)
                }
            }
        })
    }
    
    func trackActionFor(lookUpId: String, delegate: HTConsumerClientDelegate,
                        completionHandler: ((_ actions: [HyperTrackAction]?, _ error: HyperTrackError?) -> Void)?) {
        self.delegate = delegate
        trackedUserStore?.trackActionFor(lookUpId: lookUpId, completionHandler: { (actions, error) in
            if (error != nil) {
                if let completionHandler = completionHandler {
                    completionHandler(nil, error)
                }
                return
            }
            
             if let actions = actions {
                self.currentActionStatusList = [String:String]()
                for action in actions {
                    self.currentActionStatusList[action.id!] = action.status
                }
                
                if let completionHandler = completionHandler {
                    completionHandler(actions, nil)
                }
            }
        })
    }
    
    func removeActions(_ actionIds: [String]? = nil) {
        trackedUserStore?.removeActions(actionIds)
    }
    
    func stopPolling(){
        self.trackedUserStore?.stopUpdatesTimer()
    }
    
    private func refreshData(){
        var changesStatusActionIds = [String]()
        var refreshedActionIds = [String]()
        let currentActionIds = self.trackedUserStore?.getActionIds()
        
        for actionId in currentActionIds! {
            let action = self.trackedUserStore?.getAction(actionId: actionId)
            if let act = action {
                let status = self.currentActionStatusList[(action?.id)!]
                if let status = status {
                    if(act.status?.caseInsensitiveCompare(status) != ComparisonResult.orderedSame){
                        changesStatusActionIds.append(actionId)
                        self.currentActionStatusList[(action?.id)!] = action?.status
                        
                    }
                }
                refreshedActionIds.append(actionId)
            }
        }
        
        if(changesStatusActionIds.count > 0){
            let actions  = self.trackedUserStore?.getActions(actionIds: changesStatusActionIds)
            self.delegate?.onActionStatusChanged(actionIds: changesStatusActionIds, actions: actions!)
        }
        
        if(refreshedActionIds.count > 0){
            let actions  = self.trackedUserStore?.getActions(actionIds: refreshedActionIds)
            self.delegate?.onActionStatusRefreshed(actionIds: refreshedActionIds, actions: actions!)
        }
    }
    
    func onTrackableUserFetch(userIds:[String]){
        self.delegate?.onUserListUpdated()
    }
    
    func onTrackableUserUpdate(userIds:[String]){
        self.delegate?.onUserListChanged()
    }
    
    func onActionsRemoved(){
        self.delegate?.onActionsRemoved()
    }
}
