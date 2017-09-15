//
//  HTTrackedUserDataSource.swift
//  Pods
//
//  Created by Ravi Jain on 03/06/17.
//
//

import UIKit

class HTTrackedUserDataSource: NSObject {
    
    var lookupId:String?
    var trackedActionsMap = [String:HyperTrackAction]()
    var trackedUsersMap = [String:HTTrackedUser]()
    
    func getUserIdsList() -> [String]{
        return [String](trackedUsersMap.keys)
    }
    
    func getActionIdsList() -> [String]{
        return [String](trackedActionsMap.keys)
    }
    
    func getActionIdsList(userId:String) -> [String]?{
        if let trackedUser = trackedUsersMap[userId] {
            return trackedUser.getActionIds() as? [String]
        }
        return nil
    }
    
    func getAction(actionId:String) -> HyperTrackAction?{
        return trackedActionsMap[actionId]
    }
    
    func getActionsList() -> [HyperTrackAction]{
        return [HyperTrackAction] (trackedActionsMap.values)
    }
    
    func getActions(userId : String) -> [HyperTrackAction]?{
        if let user = self.trackedUsersMap[userId] {
           return user.actions as? [HyperTrackAction]
        }
        return nil
    }
    
    func getActionIds(userId : String) -> [String]?{
        var actionIds = [String]()
        
        if let user = self.trackedUsersMap[userId] {
            let actions = user.actions
            if ((actions?.count)! > 0) {
                for action in actions! {
                    actionIds.append((action?.id)!)
                }
            }
        }
        return actionIds
    }
    
    func getTrackedUser(userId : String) -> HTTrackedUser? {
        return trackedUsersMap[userId]
    }
    
    func getActions(actionIds : [String]) -> [HyperTrackAction]?{
        var actions = [HyperTrackAction]()
        if (actionIds.count > 0) {
            for actionId in actionIds {
                let action = self.getAction(actionId: actionId)
                if let currentAction = action {
                    actions.append(currentAction)
                }
            }
        }
        return actions
    }
    
    func addTrackedUsers(users : [HTTrackedUser]?){
        if let users = users {
            if(users.count > 0){
                for user in users {
                    trackedUsersMap[(user.expandedUser?.id)!] = user
                    self.addActions(actions: user.actions as? [HyperTrackAction])
                }
            }
        }
    }
    
    func addActions(actions:[HyperTrackAction]?){
        if let actions = actions {
            if(actions.count > 0){
                for action in actions {
                    trackedActionsMap[(action.id)!] = action
                }
            }
        }
    }
    
    func getUnCompleteActionIdsList()->[String]{
        var actionIds = [String]()
        for actionId in self.getActionIdsList(){
            if let action = self.getAction(actionId: actionId){
                if !((action.isCompleted())){
                    actionIds.append(actionId)
                }
            }
        }
        return actionIds
    }
}
