//
//  HTTrackedUser.swift
//  Pods
//
//  Created by Ravi Jain on 03/06/17.
//
//

import UIKit

class HTTrackedUser: NSObject {
    
    var actions : [HyperTrackAction?]?
    var expandedUser: HTExpandedUser?
    
    func getActionIds() -> [String?]{
        var actionIds = [String?]()
        for (_, element) in actions!.enumerated() {
            actionIds.append(element?.id)
        }
        return actionIds
    }
    
    func removeAction(action : HyperTrackAction? ){
        if var actions = actions {
            actions = actions.filter() { $0 !== action }
        }
    }
    
    public static func userFromDict(userDict : [String:Any]) -> HTTrackedUser?{
        
        let trackedUser = HTTrackedUser()
        var actionObjects = [HyperTrackAction]()

        if let actions = userDict["actions"]{
            let actionsDictionary = actions as! [Any]
            for action in actionsDictionary{
                let actionObject = HyperTrackAction.fromDict(dict: action as! [String : Any])
                if let actionObject = actionObject {
                    actionObjects.append(actionObject)
                }
            }
        }
        
        let expandedUser =  HTExpandedUser.userFromDict(dict: userDict["user"] as! [String : Any])
        trackedUser.expandedUser = expandedUser
        trackedUser.actions = actionObjects
        return trackedUser
    }
    
    public static func usersFromJSONData(data: Data?) -> [HTTrackedUser]? {
        do {
        
            let jsonDict = try JSONSerialization.jsonObject(with: data!, options: [])
            
            guard let dict = jsonDict as? [String : Any] else {
                return nil
            }
            
            var userObjects = [HTTrackedUser]()
            let results = dict["results"] as! [Any]
            
            for user in results {
                let trackedUser = self.userFromDict(userDict: user as! [String : Any])
                userObjects.append(trackedUser!)
            }
            
            return userObjects
            
        } catch {
            HTLogger.shared.error("Error in getting users from json: " + error.localizedDescription)
            return nil
        }
    }
}
