//
//  HTViewInteractionDelegate.swift
//  HyperTrack
//
//  Created by Piyush on 25/05/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import Foundation

@objc internal protocol HTViewInteractionInternalDelegate {

    @objc optional func didTapReFocusButton(_ sender: Any)
    @objc optional func didTapBackButton(_ sender: Any)
    @objc optional func didTapPhoneButton(_ sender: Any)
    @objc optional func didTapHeroMarkerFor(userID: String)
    @objc optional func didTapExpectedPlaceMarkerFor(actionID: String)
    @objc optional func didTapInfoViewFor(actionID: String)
    @objc optional func didTapMapView()
    @objc optional func didPanMapView()
   
    @objc optional func didTapStopLiveLocationSharing(actionId : String)
    @objc optional func didTapShareLiveLocationLink(action : HyperTrackAction)
    @objc optional func didSelectLocation(place : HyperTrackPlace?)
    @objc optional func willChooseLocationOnMap()
}

/**
 The delegate protocol that you can extend to receive interaction events on the map view
 */
@objc public protocol HTViewInteractionDelegate {
    // Duplicate protocol to the internal delegate, but this one is public

    /**
     Called when refocus button is tapped
     
     - Parameter sender: Sender object
     */
    @objc optional func didTapReFocusButton(_ sender: Any)
    
    /**
     Called when back button is tapped
     
     - Parameter sender: Sender object
     */
    @objc optional func didTapBackButton(_ sender: Any)
    
    /**
     Called when phone button is tapped
     
     - Parameter sender: Sender object
     */
    @objc optional func didTapPhoneButton(_ sender: Any)
    
    /**
     Called when hero marker is tapped for a user marker
     
     - Parameter userID: The userID for which marker was tapped
     */
    @objc optional func didTapHeroMarkerFor(userID: String)
    
    /**
     Called when expected place marker is tapped for an action
     
     - Parameter actionID: The actionID for which marker was tapped
     */
    @objc optional func didTapExpectedPlaceMarkerFor(actionID: String)
    
    /**
     Called when info view is tapped for an action marker
     
     - Parameter actionID: The actionID for which marker was tapped
     */
    @objc optional func didTapInfoViewFor(actionID: String)
    
    /**
     Called when map is tapped
     */
    @objc optional func didTapMapView()
    
    /**
     Called when map is panned
     */
    @objc optional func didPanMapView()

    
    @objc optional func didTapStopLiveLocationSharing(actionId : String)
    
    
    @objc optional func didTapShareLiveLocationLink(action : HyperTrackAction)
    
    @objc optional func didSelectLocation(place : HyperTrackPlace?)
   
    @objc optional func willChooseLocationOnMap()

}
