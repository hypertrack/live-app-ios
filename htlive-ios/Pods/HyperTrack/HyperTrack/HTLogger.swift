//
//  HTLogger.swift
//  HyperTrack
//
//  Created by Piyush on 28/06/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import Foundation
import JustLog

public final class HTLogger {
    
    let logger:Logger
    
    static let shared = HTLogger()
    
    let timeStampKey = "timestamp"
    
    init() {
        self.logger = Logger.shared
        
        // file destination
        self.logger.logFilename = "HyperTrack_Log.txt"
        
        // logstash destination
        self.logger.logstashHost = "logs.hypertrack.io"
        self.logger.logstashPort = 19540
        self.logger.logLogstashSocketActivity = true
        
        // default info
        self.logger.defaultUserInfo = ["publishable_key": Settings.getPublishableKey() ?? "",
                                       "sdk_version": Settings.sdkVersion,
                                       "app_name": Bundle.main.bundleIdentifier!,
                                       "user_id": Settings.getUserId() ?? "",
                                       "device_id": Settings.uniqueInstallationID]
        self.logger.setup()
    }
    
    @objc public func postLogs() {
        self.logger.forceSend { (error) in
            if (error != nil) {
                print("Error in postLogs: \(String(describing: error))")
                return
            }
        }
    }
    
    public func verbose(_ message: String, error: NSError? = nil) {
        if let error = error {
            print("\(message), error: \(String(describing: error))")
            return
        }
        
        print("\(message)")
    }
    
    public func debug(_ message: String, error: NSError? = nil) {
        if let error = error {
            print("\(message), error: \(String(describing: error))")
            return
        }
        
        print("\(message)")
    }
    
    public func info(_ message: String, error: NSError? = nil, userInfo: [String : Any]? = nil, _ file: StaticString = #file, _ function: StaticString = #function, _ line: UInt = #line) {
        var updatedUserInfo = userInfo ?? [String : String]()
        updatedUserInfo[timeStampKey] = Date().iso8601
        self.logger.info(message, error: error, userInfo: updatedUserInfo, file, function, line)
    }
    
    public func warning(_ message: String, error: NSError? = nil, userInfo: [String : Any]? = nil, _ file: StaticString = #file, _ function: StaticString = #function, _ line: UInt = #line) {
        var updatedUserInfo = userInfo ?? [String : String]()
        updatedUserInfo[timeStampKey] = Date().iso8601
        self.logger.warning(message, error: error, userInfo: updatedUserInfo)
    }
    
    public func error(_ message: String, error: NSError? = nil, userInfo: [String : Any]? = nil, _ file: StaticString = #file, _ function: StaticString = #function, _ line: UInt = #line) {
        var updatedUserInfo = userInfo ?? [String : String]()
        updatedUserInfo[timeStampKey] = Date().iso8601
        self.logger.error(message, error: error, userInfo: updatedUserInfo, file, function, line)
    }
}
