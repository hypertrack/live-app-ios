//
//  HTStatusInfo.swift
//  Pods
//
//  Created by ravi on 9/7/17.
//
//

import UIKit

@objc public class HTStatusInfo: NSObject {
    /**
    Username of user to whom the action is assigned
     */
    var userName: String = ""
    
    /**
    Date at which action was updated
     */
    var lastUpdated: Date = Date()
    
    /**
    Speed of the user to whom the action is assigned
    */
    var speed: Int?
    
    /**
    Battery of user
    */
    var battery: Int?
    
    /**
    Url of the user's photo
    */
    var photoUrl: URL?
    
    /**
    eta of user for completing the action
    */
    var etaMinutes: Double? = nil
    
    /**
    distance unit used while giving distance info
     */
    var distanceUnit = "mi"
    
    /**
    distance left for completing the action, it is given in the distance unit which is decided based on user's location
    */
    var distanceLeft: Double? = nil
    
    /**
     distance covered while completing the action, it is given in the distance unit which is decided based on user's location
     */
    var distanceCovered: Double = 0
    
    /**
     Human readable status for the action
    */
    var status: String = ""
    
    /**
    time elapsed while completing the action
    */
    var timeElapsedMinutes: Double = 0
    
    /**
    address where the action is started
    */
    var startAddress: String?
    
    /**
     address where the action is completed
     */
    var completeAddress: String?
    
    /**
     time when the action is started
     */
    var startTime: Date?

    /**
     time when the action is ended
     */
    var endTime: Date?
    
    /**
     display fields of action
     */
    var display: HyperTrackActionDisplay?
    
    /**
     specifies wether you can show details of action 
    */
    var showActionDetailSummary = false

}
