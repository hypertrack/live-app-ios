//
//  HTUserService.swift
//  HyperTrack
//
//  Created by Ravi Jain on 8/5/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import UIKit

class HTUserService: NSObject {

    static let sharedInstance = HTUserService()
    
    let requestManager: RequestManager

    override init() {
        self.requestManager = RequestManager()
    }
    
    func setUserId(userId:String) {
        Settings.setUserId(userId: userId)
        PushNotificationService.registerDeviceToken()
        let nc = NotificationCenter.default
        nc.post(name:Notification.Name(rawValue:HTConstants.HTUserIdCreatedNotification),
                object: nil,
                userInfo: nil)
        
    }
    
     func getUserId() -> String? {
        return Settings.getUserId()
    }

    
    func createUser(_ name:String, completionHandler: ((_ user: HyperTrackUser?, _ error: HyperTrackError?) -> Void)?) {
        self.requestManager.createUser(["name":name]) { user, error in
            
            if (user != nil) {
                Settings.setUserId(userId: (user?.id)!)
                Settings.saveUser(user: user!)
            } else if (error != nil) {
                HTLogger.shared.error("Error creating user: \(String(describing: error?.type.rawValue))")
            }
            
            if (completionHandler != nil) {
                completionHandler!(user, error)
            }
        }
    }
    
    func createUser(_ name: String, _ phone: String, _ lookupID: String, _ photo: UIImage?, _ completionHandler: @escaping (_ user: HyperTrackUser?, _ error: HyperTrackError?) -> Void) {
        var requestBody = ["name": name, "phone": phone, "lookup_id": lookupID]
        
        if let photo = photo {
            // Convert image to base64 before upload
            if let imageData = UIImagePNGRepresentation(photo){
                let strBase64 = imageData.base64EncodedString(options: .lineLength64Characters)
                requestBody["photo"] = strBase64
            }
        }
        
        self.requestManager.createUser(requestBody) { user, error in
            if (user != nil) {
                Settings.setUserId(userId: (user?.id)!)
                Settings.saveUser(user: user!)
            } else if (error != nil) {
                HTLogger.shared.error("Error creating user: \(String(describing: error?.type.rawValue))")
            }
            
            completionHandler(user, error)
        }
    }
    
    func createUser(_ name: String, _ phone: String, _ lookupID: String, _ completionHandler: @escaping (_ user: HyperTrackUser?, _ error: HyperTrackError?) -> Void) {
        
        self.requestManager.createUser(["name": name, "phone": phone, "lookup_id": lookupID]) { user, error in
            if (user != nil) {
                
                Settings.setUserId(userId: (user?.id)!)
                Settings.setLookupId(lookupId: lookupID)
                Settings.saveUser(user: user!)
            } else if (error != nil) {
                HTLogger.shared.error("Error creating user: \(String(describing: error?.type.rawValue))")
            }
            
            completionHandler(user, error)
        }
    }
    
    
    func updateUser(_ name: String, _ phone: String? = nil, _ lookupID: String? = nil, _ photo: UIImage? = nil, _ completionHandler: @escaping (_ user: HyperTrackUser?, _ error: HyperTrackError?) -> Void) {
        
        var requestBody = ["name": name]
        if (phone != nil){
            requestBody["phone"] = phone
        }
        
        if(lookupID != nil){
            requestBody["lookup_id"] = lookupID
        }
        
        if let photo = photo {
            // Convert image to base64 before upload
            if let imageData = UIImagePNGRepresentation(photo){
                let strBase64 = imageData.base64EncodedString(options: .lineLength64Characters)
                requestBody["photo"] = strBase64
            }
        }
        
        self.requestManager.updateUser(requestBody) { user, error in
            if (user != nil) {
                Settings.setUserId(userId: (user?.id)!)
                Settings.saveUser(user: user!)
            } else if (error != nil) {
                HTLogger.shared.error("Error creating user: \(String(describing: error?.type.rawValue))")
            }
            
            completionHandler(user, error)
        }
    }
}
