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
    var imageCache = [String:UIImage]()
    weak var eventDelegate : HTEventsDelegate?
    
    private override init(){
        self.trackedUserStore = HTTrackedUserStore()
        super.init()
        self.trackedUserStore?.delegate = self
    }
    
    func getLookUpId() -> String?{
        return trackedUserStore?.trackedUserDataSource.lookupId
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
                
                let nc = NotificationCenter.default
                let userInfo = ["actions" : actions]
                nc.post(name:Notification.Name(rawValue:HTConstants.HTTrackingStartedForLookUpId),
                        object: nil,
                        userInfo: userInfo)

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
                        self.eventDelegate?.actionStatusChanged?(forAction: action!, toStatus: action?.status)
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
    
    func addImageToCache(image : UIImage , key : String){
        imageCache[key] = image
    }
    func removeImageFromCache(key: String){
        imageCache.removeValue(forKey: key)
    }
    
    func getImageFromCache(key:String) -> UIImage?{
        return imageCache[key]
    }
    func didUpdateActions(oldActions: [String:HyperTrackAction]?, newActions: [String:HyperTrackAction]?){
        if(oldActions != nil && newActions != nil){
            if let actionIds =  newActions?.keys{
                for actionId in actionIds{
                    if let oldAction = oldActions?[actionId]{
                        let newAction = newActions?[actionId]
                        
                        self.eventDelegate?.didRefreshData?(forAction: newAction!)
                        
                        if(oldAction.status?.caseInsensitiveCompare((newAction?.status)!) != ComparisonResult.orderedSame){
                            self.eventDelegate?.actionStatusChanged?(forAction: newAction!, toStatus: newAction?.status)
                        }
                        
                        if(oldAction.isInternetAvailable() != newAction?.isInternetAvailable()){
                            self.eventDelegate?.networkStatusChangedFor?(action: newAction!, isConnected: (newAction?.isInternetAvailable())!)
                        }
                        
                        if(oldAction.isLocationAvailable() != newAction?.isLocationAvailable()){
                            self.eventDelegate?.locationStatusChangedFor?(action: newAction!, isEnabled: (newAction?.isLocationAvailable())!)
                        }
                        
                        
                    }
                }
  
            }
        }
        
    }
    
    func isActionTrackable(actionId : String!) -> Bool{
        if let action = getAction(actionId: actionId){
            return action.isActionTrackable()!
        }
        return false
    }
 
    
}
