//
//  HTSDKControls.swift
//  HyperTrack
//
//  Created by Tapan Pandita on 09/03/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import Foundation


class HyperTrackSDKControls {
    public static let defaultBatchDuration = 30.0 * 60.0 // seconds
    public static let defaultMinimumDuration = 5 // seconds
    public static let defaultMinimumDisplacement = 50.0 // meters
    
    public let userId: String?
    public let runCommand: String?
    public let ttl: Int?
    public let minimumDuration: Int?
    public let minimumDisplacement: Int?
    public let batchDuration: Int?
    
    public init(userId: String?,
                runCommand: String?,
                ttl: Int?,
                minimumDuration: Int?,
                minimumDisplacement: Int?,
                batchDuration: Int?) {
        self.userId = userId
        self.runCommand = runCommand
        self.ttl = ttl
        self.minimumDuration = minimumDuration
        self.minimumDisplacement = minimumDisplacement
        self.batchDuration = batchDuration
    }
    
    public static func fromDict(dict:[String:Any]?) -> HyperTrackSDKControls? {
        guard let dict = dict else {
            return nil
        }
        
        guard let userId = dict["user_id"] as? String,
            let runCommand = dict["run_command"] as? String?,
            let minimumDuration = dict["minimum_duration"] as? Int?,
            let minimumDisplacement = dict["minimum_displacement"] as? Int?,
            let batchDuration = dict["batch_duration"] as? Int?,
            let ttl = dict["ttl"] as? Int? else {
                return nil
        }

        let controls = HyperTrackSDKControls(
            userId: userId,
            runCommand: runCommand,
            ttl: ttl,
            minimumDuration: minimumDuration,
            minimumDisplacement: minimumDisplacement,
            batchDuration: batchDuration
        )
        
        return controls
    }
    
    internal func toDict() -> [String:Any] {
        let dict = [
            "user_id": self.userId as Any,
            "run_command": self.runCommand as Any,
            "minimum_duration": self.minimumDuration as Any,
            "minimum_displacement": self.minimumDisplacement as Any,
            "batch_duration": self.batchDuration as Any,
            "ttl": self.ttl as Any
            ] as [String:Any]
        return dict
    }

    public static func fromJson(data:Data?) -> HyperTrackSDKControls? {
        do {
            let jsonDict = try JSONSerialization.jsonObject(with: data!, options: [])
            
            guard let dict = jsonDict as? [String : Any] else {
                return nil
            }
            
            return self.fromDict(dict:dict)
        } catch {
            HTLogger.shared.error("Error in getting sdk controls from json: " + error.localizedDescription)
            return nil
        }
    }
    
    public static func saveControls(controls: HyperTrackSDKControls) {
        Settings.setControls(controls: controls)
    }
    
    public static func clearSavedControls() {
        Settings.clearSDKControls()
    }
    
    public static func getControls() -> (Double, Double) {
        var batchDuration = HyperTrackSDKControls.defaultBatchDuration
        var minimumDisplacement = HyperTrackSDKControls.defaultMinimumDisplacement
        // var minimumDuration = HyperTrackSDKControls.defaultMinimumDuration
        
        if let duration = Settings.getBatchDuration() {
            if duration > 0 {
                batchDuration = duration
            }
        }
        
        if let displacement = Settings.getMinimumDisplacement() {
            if displacement > 0 {
                minimumDisplacement = displacement
            }
        }
        
        // Method does not return the minimum duration as that is
        // not used in the location manager
        return (batchDuration, minimumDisplacement)
    }
}
