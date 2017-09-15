//
//  HTGenericUtils.swift
//  Pods
//
//  Created by Ravi Jain on 7/27/17.
//
//

import UIKit

class HTGenericUtils: NSObject {

    public static func isCurrentUser(userId : String?) -> Bool{
        if let userId = userId {
            if let currentUserId = Settings.getUserId(){
            if(currentUserId == userId){
                return true
            }
            }
        }
        return false
    }
    
    public static func getPlaceName (place : HyperTrackPlace?) -> String!{
        var destinationText = ""
        if let place = place {
            if(place.name != nil && place.name != ""){
                destinationText = (place.name!)
            }
            else if(place.address != nil){
                destinationText = (place.address?.components(separatedBy: ",").first)!
            }
        }
    
        return destinationText;
    }
    
    public static func checkIfContains(places:[HyperTrackPlace], inputPlace: HyperTrackPlace) -> Bool{
        for place in places {
            if(place.location?.coordinates.first == inputPlace.location?.coordinates.first){
                if(place.location?.coordinates.last == inputPlace.location?.coordinates.last){
                    return true
                }
            }
        }
        
        return false
    }
    
    public static func getDeviceModel() -> String {
        // Helper method to return exact model number, eg iPhone8,1
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
    
   public static func getDeviceInfo() -> [String:String?] {
        let data = [
            "product": UIDevice.current.model,
            "brand": "apple",
            "time_zone": TimeZone.current.identifier,
            "os_version": UIDevice.current.systemVersion,
            "sdk_version": Settings.sdkVersion,
            "device": UIDevice.current.model,
            "model": getDeviceModel(),
            "manufacturer": "apple",
            "os": UIDevice.current.systemName,
            "custom_os_version": UIDevice.current.systemVersion,
            "device_id": UIDevice.current.identifierForVendor?.uuidString
        ]
        return data
    }
    
    
    public static func dateToString(date:Date,format  : String ) -> String
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        dateFormatter.locale = Locale.init(identifier: "en_US")
        return dateFormatter.string(from: date)
    }



}
