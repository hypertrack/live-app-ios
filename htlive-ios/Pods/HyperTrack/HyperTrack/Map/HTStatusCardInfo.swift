//
//  HTStatusCardInfo.swift
//  Pods
//
//  Created by Ravi Jain on 30/06/17.
//
//

import UIKit

class HTStatusCardInfo: HTStatusInfo {

    var isInfoViewShown = true
    var showActionPolylineSummary = false
    var showExpandedCardOnCompletion = true
    var markerUserName : String?
    var infoCardImage: UIImage?
    var isCurrentUser = false
    var isCompletedOrCanceled = false
    var progressCardImage : UIImage?
    var progressStrokeColor : UIColor?
    var eta : Double?

    static func getUserInfo(_ action: HyperTrackAction, _ userId : String? , useCase : HTConstants.UseCases, isCurrentUser : Bool) -> HTStatusCardInfo {
        
        let statusInfo = HTStatusCardInfo()
        let bundle = Bundle(for: HTMap.self)

        if let startedAt = action.startedAt {
            var timeElapsed: Double?
            
            if action.endedAt != nil {
                timeElapsed = startedAt.timeIntervalSince(action.endedAt!)
            } else {
                timeElapsed = startedAt.timeIntervalSinceNow
            }
            statusInfo.timeElapsedMinutes = -1 * Double(timeElapsed! / 60.0)
        }
        
        if isCurrentUser{
            statusInfo.progressCardImage =  UIImage.init(named: "purpleArrow", in: bundle, compatibleWith: nil)
            statusInfo.progressStrokeColor  = purple
        }else{
            statusInfo.progressCardImage =  UIImage.init(named: "triangle", in: bundle, compatibleWith: nil)
            statusInfo.progressStrokeColor  = pink
        }
        
        
        if let displayDistanceUnit = action.display?.distanceUnit {
           statusInfo.distanceUnit = displayDistanceUnit
        }
        
        if let distance = action.distance {
            // Convert distance (meters) to miles and round to one decimal
            if (statusInfo.distanceUnit == "mi") {
                statusInfo.distanceCovered =  ((distance * 0.000621371 * 10.0) / 10.0).roundTo(places: 1)
            } else {
                statusInfo.distanceCovered = (distance / 1000.0).roundTo(places: 1)
            }
        } else {
            statusInfo.distanceCovered  = 0.0
        }
        
        if let user = action.user as HyperTrackUser? {
            statusInfo.userName = ""
            if(user.name != nil){
                statusInfo.userName = user.name!
            }
            
            if (isCurrentUser) {
                statusInfo.markerUserName = "You"
                if (action.display?.showSummary )!{
                    statusInfo.infoCardImage =  UIImage.init(named: "play", in: bundle, compatibleWith: nil)
                    
                } else {
                    statusInfo.infoCardImage =  UIImage.init(named: "square", in: bundle, compatibleWith: nil)
                }
                
                statusInfo.isCurrentUser = true
            } else {
                let fullNameArr =  statusInfo.userName .components(separatedBy: " ")
                statusInfo.markerUserName = fullNameArr[0]
            }
            
            if let photo = user.photo {
                statusInfo.photoUrl = URL(string: photo)
            }
            
            if let batteryPercentage = user.lastBattery {
                statusInfo.battery = batteryPercentage
            }
            
            if let heartbeat = user.lastHeartbeatAt {
                statusInfo.lastUpdated = heartbeat
            }
            
            if let location = user.lastLocation, (location.speed >= 0) {
                if (statusInfo.distanceUnit == "mi") {
                    statusInfo.speed = Int(location.speed * 2.23693629)
                } else {
                    statusInfo.speed = Int(location.speed * 3.6)
                }
            }
        }
        
        let actionDisplay = action.display
        if (actionDisplay != nil) {
            if let duration = actionDisplay!.durationRemaining {
                let timeRemaining = duration
                statusInfo.etaMinutes = Double(timeRemaining / 60)
            }
            
            if let statusText = actionDisplay!.statusText {
                
                statusInfo.status =  statusText
                
                if (statusText.lowercased() == "on the way"  || statusText.lowercased() == "arriving" || statusText.lowercased() == "leaving now"){
                    statusInfo.status = statusInfo.markerUserName! + " is " + statusText.lowercased()
                    if(isCurrentUser){
                        statusInfo.status = statusInfo.markerUserName! + " are " + statusText.lowercased()
                    }
                    
                } else if (action.display?.showSummary )!{
                    statusInfo.status = statusInfo.markerUserName! + " has " + statusText.lowercased() + " trip"
                    
                    if(isCurrentUser){
                        statusInfo.status = statusInfo.markerUserName! + " have " + statusText.lowercased() + " trip"
                    }
                    
                    statusInfo.isCompletedOrCanceled = true
                }
            }
        
            
            if let distance = actionDisplay!.distanceRemaining {
                if (statusInfo.distanceUnit == "mi") {
                    // Convert distance (meters) to miles and round to one decimal
                    statusInfo.distanceLeft = ((Double(distance) * 0.000621371 * 10.0) / 10.0).roundTo(places: 1)
                } else {
                    statusInfo.distanceLeft = (Double(distance) / 1000.0).roundTo(places: 1)
                }
            }

            
            statusInfo.showActionDetailSummary = actionDisplay!.showSummary
            
            // Check if Action summary needs to be displayed on map or not
            if useCase == HTConstants.UseCases.TYPE_SINGLE_USER_SINGLE_ACTION {
                statusInfo.showActionPolylineSummary = actionDisplay!.showSummary
                statusInfo.showExpandedCardOnCompletion = actionDisplay!.showSummary
            }
        }
        
        if let address = action.startedPlace?.address {
            statusInfo.startAddress = address
        }
        
        if let address = action.completedPlace?.address {
            statusInfo.completeAddress = address
        }
        
        statusInfo.startTime = action.assignedAt
        statusInfo.endTime = action.endedAt
        statusInfo.display = action.display
        return statusInfo
    }
}
