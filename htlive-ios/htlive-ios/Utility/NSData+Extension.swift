//
//  NSData+Extension.swift
//  Meta-iPhone
//
//  Created by Ulhas Mandrawadkar on 11/01/16.
//  Copyright © 2016 HyperTrack, Inc. All rights reserved.
//

import Foundation

extension Data {
    var tokenStringValue: String {
        
        var tokenString: String = ""
        
        for i in 0..<self.count {
            tokenString += String(format: "%02.2hhx", self[i] as CVarArg)
        }
        
        return tokenString
    }
}

extension NSData {
    
    var fileURLFromImage: NSURL {
        
        let directory = NSTemporaryDirectory()
        let temporaryDirectory = NSURL(fileURLWithPath: directory)
        let imagePath = temporaryDirectory.appendingPathComponent("\(randomStringWithLength(len: 10)).jpg")
        
        write(to: imagePath!, atomically: true)
        
        return imagePath! as NSURL
    }
}

func randomStringWithLength (len : Int) -> NSString {
    
    let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    
    let randomString : NSMutableString = NSMutableString(capacity: len)
    
    for _ in stride(from: 0, to: len, by: 1){
        let length = UInt32 (letters.length)
        let rand = arc4random_uniform(length)
        randomString.appendFormat("%C", letters.character(at: Int(rand)))
    }
    
    return randomString
}

extension NSDate {
    
    var shareFormat: String {
        
        let formatter = DateFormatter()
        formatter.locale = NSLocale(localeIdentifier: "en_US_POSIX") as Locale!
        formatter.dateFormat = "h:mm a"
        
        return formatter.string(from: self as Date)
    }
    
    var prefix: String {
        get {
            let calendar = NSCalendar.current
            
            let now = Date()
            let nowComponents = calendar.dateComponents([.day], from: now, to: self as Date)
//            let nowComponents = calendar.components([.day], fromDate: now, toDate: self, options: NSCalendar.Options(rawValue: UInt(0)))
            let dateFormatter = DateFormatter()
            
            var prefix = ""
            
            switch nowComponents.day ?? 0 {
            case 0:
                prefix = ""
            case 1:
                prefix =  "Tomorrow"
            case 2 ... 7:
                dateFormatter.dateFormat = "EEE"
                prefix = dateFormatter.string(from: self as Date)
            default:
                dateFormatter.dateStyle = .medium
                prefix = dateFormatter.string(from: self as Date)
            }
            
            return prefix
        }
    }
}

extension Dictionary {
    mutating func update(other:Dictionary) {
        for (key,value) in other {
            self.updateValue(value, forKey:key)
        }
    }
}
