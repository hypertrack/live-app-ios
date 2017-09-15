
//
//  HTMapUtils.swift
//  Pods
//
//  Created by Ravi Jain on 8/3/17.
//
//

import UIKit
import MapKit

class HTMapUtils: NSObject {

   public static func headingFrom(_ previous: CLLocationCoordinate2D, next: CLLocationCoordinate2D) -> CLLocationDegrees {
        
        let deltaX = next.latitude - previous.latitude
        let deltaY = next.longitude - previous.longitude
        
        return radiansToDegrees(radians: atan2(deltaY, deltaX)).truncatingRemainder(dividingBy: 360)
    }
    
    public static func radiansToDegrees(radians: Double) -> Double {
        return radians * 180 / Double.pi
    }
    
    
    public static func getCLLocationFromVisit(visit:CLVisit) -> CLLocation {
        let clLocation = CLLocation(
            coordinate:visit.coordinate,
            altitude:CLLocationDistance(0),
            horizontalAccuracy:visit.horizontalAccuracy,
            verticalAccuracy:CLLocationAccuracy(0),
            course:CLLocationDirection(0),
            speed:CLLocationSpeed(0),
            timestamp:visit.arrivalDate
        )
        return clLocation
    }
    
}
