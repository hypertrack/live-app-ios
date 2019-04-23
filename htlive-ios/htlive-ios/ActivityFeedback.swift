//
//  ActivityFeedback.swift
//  htlive-ios
//
//  Created by ravi on 9/5/17.
//  Copyright © 2017 PZRT. All rights reserved.
//

import UIKit

class ActivityFeedback: NSObject {
   
    let activityId : String
    var feedbackType : String?
    var userComments : String?
    var appVersion : String?
    var sdkVersion : String?
    var editedType : String?
    var editedStartLocation : String?
    var editedEndLocation : String?
    var editedStartTime : Date?
    var editedEndTime : Date?
    var editedIsAtStop : Bool?
    var editedNumOfSteps : Int?
    var editedDistance : Int?
    var isStartLocationAccurate : Bool?
    var isEndLocationAccurate : Bool?
    var isAtStopAccurate : Bool?
    var isStartTimeAccurate : Bool?
    var isEndTimeAccurate : Bool?
    var isNumOfStepsAccurate : Bool?
    var isDistanceAccurate : Bool?
    var isTypeAccurate : Bool?
    
    init(uuid : String) {
        self.activityId = uuid
        self.isStartLocationAccurate = true
        self.isEndLocationAccurate = true
        self.isAtStopAccurate = true
        self.isStartTimeAccurate = true
        self.isEndTimeAccurate = true
        self.isNumOfStepsAccurate = true
        self.isDistanceAccurate = true
        self.isTypeAccurate = true
    }
    
    func markAllInaccurate(){
        self.isStartLocationAccurate = false
        self.isEndLocationAccurate = false
        self.isAtStopAccurate = false
        self.isStartTimeAccurate = false
        self.isEndTimeAccurate = false
        self.isNumOfStepsAccurate = false
        self.isDistanceAccurate = false
        self.isTypeAccurate = false
    }
    
    func toDict() -> [String:Any] {
        var activityDict = [String:Any]()
        activityDict["activity"] = activityId
        activityDict["feedback_type"] = feedbackType
        if let comment = self.userComments {
            activityDict["user_comments"] = comment
        }
        
        if let editedType = self.editedType {
            activityDict["edited_type"] = editedType
        }

        if let startLocation = self.editedStartLocation{
            activityDict["edited_start_location"] = startLocation
        }
        
        if let endLocation = self.editedEndLocation{
            activityDict["edited_end_location"] = endLocation
        }
        
        if let editedNumOfSteps = self.editedNumOfSteps{
            activityDict["edited_num_of_steps"] = editedNumOfSteps
        }
        
        if let distance = self.editedDistance{
            activityDict["edited_distance"] = distance
        }
        
        if let startTime = self.editedStartTime{
            activityDict["edited_started_at"] = startTime.toString(dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX")

        }
        
        
        if let endTime = self.editedEndTime{
            activityDict["edited_ended_at"] = endTime.toString(dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX")
            
        }

        
        activityDict["is_type_accurate"] = self.isTypeAccurate
        activityDict["is_start_location_accurate"] = self.isTypeAccurate
        activityDict["is_end_location_accurate"] = self.isTypeAccurate
        activityDict["is_num_of_steps_accurate"] = self.isNumOfStepsAccurate
        activityDict["is_start_time_accurate"] = self.isStartTimeAccurate
        activityDict["is_end_time_accurate"] = self.isStartTimeAccurate
        activityDict["is_start_time_accurate"] = self.isStartTimeAccurate
        activityDict["is_distance_accurate"] = self.isDistanceAccurate

        return activityDict
    }
    
}
