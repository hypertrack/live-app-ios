//
//  HTEventsDelegate.swift
//  Pods
//
//  Created by Ravi Jain on 7/26/17.
//
//

import UIKit
import MapKit
import CoreLocation

@objc public protocol HTEventsDelegate {

    /**
     Implement this delegate method to get location status update for tracked action
     */
    @objc optional func locationStatusChangedFor(action:HyperTrackAction ,isEnabled:Bool)
    
    /**
     Implement this delegate method to get network status update for tracked action
     */
    @objc optional func networkStatusChangedFor(action:HyperTrackAction, isConnected:Bool)
    
    /**
     Implement this delegate method to get action status update for tracked action like completed,assigned
     */
    @objc optional func actionStatusChanged(forAction: HyperTrackAction, toStatus:String?)
    
    /**
     Implement this delegate method to get a callback when action details are refreshed
     */
    @objc optional func didRefreshData(forAction: HyperTrackAction)
    
    
    
    @objc optional func didEnterMonitoredRegion(region:CLRegion)

    
    @objc optional func didShowSummary(forAction : HyperTrackAction)

}
