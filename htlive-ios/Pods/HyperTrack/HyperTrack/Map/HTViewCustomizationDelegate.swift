//
//  HTViewCustomizationDelegate.swift
//  HyperTrack
//
//  Created by Piyush on 24/05/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import Foundation
import MapKit


@objc internal protocol HTViewCustomizationInternalDelegate {

    @objc optional func heroMarkerImageForActionID( actionID: String) -> UIImage?
    @objc optional func heroMarkerViewForActionID(actionID: String) -> MKAnnotationView?
    @objc optional func disableHeroMarkerRotationForActionID( actionID: String) -> Bool
    @objc optional func showStartMarker( actionID: String) -> Bool
    @objc optional func startMarkerImageForActionID( actionID: String) -> UIImage?
    @objc optional func startMarkerViewForActionID( actionID: String) -> MKAnnotationView?
    @objc optional func showExpectedPlaceMarker( actionID: String) -> Bool
    @objc optional func expectedPlaceMarkerImageForActionID( actionID: String) -> UIImage?
    @objc optional func expectedPlaceMarkerViewForActionID( actionID: String) -> MKAnnotationView?
    @objc optional func showAddressViewForActionID( actionID: String) -> Bool
    @objc optional func showInfoViewForActionID( actionID: String) -> Bool
    @objc optional func showCallButtonInInfoViewForActionID( actionID: String) -> Bool
    @objc optional func showActionSummaryOnCompletion(actionID: String) -> Bool
}

/**
 Delegate protocol for map customizations. Use the given methods to customize your map view.
 */
@objc public protocol HTViewCustomizationDelegate {
    
    
    /**
     Call this method to set/unset traffic layer on mapview.
     
     Note: Traffic layer is enabled by default.
     
     - Parameter mapView: The map view where hero marker is placed
     - Returns: Bool to show/hide traffic layer.
     */
    @objc optional func showTrafficForMapView(map: HTMap) -> Bool
    
    /**
     Call this method to show/hide refocus button.
     
     Note: ReFocus button is enabled by default.
     
     - Parameter mapView: The map view where hero marker is placed
     - Returns: Bool to show/hide refocus button.
     */
    @objc optional func showReFocusButton(map: HTMap) -> Bool
    
    /**
     Call this method to show/hide back button alongside the address view.
     
     Note: Back button is enabled by default.
     
     - Parameter mapView: The map view where hero marker is placed
     - Returns: Bool to show/hide back button.
     */
    @objc optional func showBackButton(map: HTMap) -> Bool

 
    /**
     Call this method to provide a image to the hero marker. This image should
     be oriented to the north so that bearing of marker is perfect.
     
     - Parameter mapView: The map view where hero marker is placed
     - Parameter actionID: The actionID for which image is to be provided
     - Returns: UIImage for the hero marker
     */
    @objc optional func heroMarkerImageForActionID(map: HTMap, actionID: String) -> UIImage
    
    /**
     Call this method to provide a view to the hero marker. This view should
     be oriented to the north so that bearing of marker is perfect.
     
     - Parameter mapView: The map view where hero marker is placed
     - Parameter actionID: The actionID for which image is to be provided
     - Returns: MKAnnotationView for the hero marker
     */
    @objc optional func heroMarkerViewForActionID(map: HTMap, actionID: String) -> MKAnnotationView
    
    /**
     Call this method to set or unset rotation for the hero marker.
     Note: Hero Marker rotation is enabled by default.
     
     - Parameter mapView: The map view where hero marker is placed
     - Parameter actionID: The actionID for which image is to be provided
     - Returns: Bool for the disabling rotation of hero marker
     */
    @objc optional func disableHeroMarkerRotationForActionID(map: HTMap, actionID: String) -> Bool
    
    /**
     Call this method to show/hide the start marker.
     Note: Start marker is shown by default.
       
     - Parameter mapView: The map view where hero marker is placed
     - Parameter actionID: The actionID for which image is to be provided
     - Returns: Bool to show/hide start marker
     */
    @objc optional func showStartMarker(map: HTMap, actionID: String) -> Bool
    
    /**
     Call this method to provide a image to the start marker. This image should
     be oriented to the north so that bearing of marker is perfect.
     
     - Parameter mapView: The map view where hero marker is placed
     - Parameter actionID: The actionID for which image is to be provided
     - Returns: Image for the start marker
     */
    @objc optional func startMarkerImageForActionID(map: HTMap, actionID: String) -> UIImage
    
    /**
     Call this method to provide a view to the start marker. This image should
     be oriented to the north so that bearing of marker is perfect.
     
     - Parameter mapView: The map view where hero marker is placed
     - Parameter actionID: The actionID for which image is to be provided
     - Returns: MKAnnotationView for the start marker
     */
    @objc optional func startMarkerViewForActionID(map: HTMap, actionID: String) -> MKAnnotationView
    
    /**
     Call this method to show/hide the expectedPlace marker.
     Note: Expected Place marker is shown by default.
     
     - Parameter mapView: The map view where hero marker is placed
     - Parameter actionID: The actionID for which image is to be provided
     - Returns: Bool to show/hide expectedPlace marker
     */
    @objc optional func showExpectedPlaceMarker(map: HTMap, actionID: String) -> Bool
    
    /**
     Call this method to provide a image to the expectedPlace marker.
     
     - Parameter mapView: The map view where hero marker is placed
     - Parameter actionID: The actionID for which image is to be provided
     - Returns: Image for the expectedPlace marker
     */
    @objc optional func expectedPlaceMarkerImageForActionID(map: HTMap, actionID: String) -> UIImage
    
    /**
     Call this method to provide a view to the expectedPlace marker.
     
     - Parameter mapView: The map view where hero marker is placed
     - Parameter actionID: The actionID for which image is to be provided
     - Returns: MKAnnotationView for the expectedPlace marker
     */
    @objc optional func expectedPlaceMarkerViewForActionID(map: HTMap, actionID: String) -> MKAnnotationView
    
    /**
     Call this method to show/hide the address view on the top, which has the
     information regarding address of current Action's expectedPlace.
     
     Note: Address view is shown by default.
     
     - Parameter mapView: The map view where hero marker is placed
     - Parameter actionID: The actionID for which image is to be provided
     - Returns: Bool to show/hide address view
     */
    @objc optional func showAddressViewForActionID(map: HTMap, actionID: String) -> Bool
    
    /**
     Call this method to show/hide the info view on the bottom, which has the
     information regarding the Action being tracked such as Action details,
     User's photo, name and call button.
     
     Note: Info view is shown by default.
     
     - Parameter mapView: The map view where hero marker is placed
     - Parameter actionID: The actionID for which image is to be provided
     - Returns: Bool to show/hide driver info view
     */
    @objc optional func showInfoViewForActionID(map: HTMap, actionID: String) -> Bool
    
    /**
     Call this method to show/hide the call the user button in the info view.
     
     Note: Call Button in the info view is enabled by default in case user's
     contact details were provided while creating user.
     
     - Parameter mapView: The map view where hero marker is placed
     - Parameter actionID: The actionID for which image is to be provided
     - Returns: Bool to show/hide call button
     */
    @objc optional func showCallButtonInInfoViewForActionID(map: HTMap, actionID: String) -> Bool
    
    /**
     Call this method to disable action summary in the info view.
     Action Summary includes an overview summary of an Action and this is shown
     only on successful completion of an Action.
     
     Note: Action Summary in the info view is enabled by default.
     
     - Parameter mapView: The map view where hero marker is placed
     - Parameter actionID: The actionID for which image is to be provided
     - Returns: Bool to disable action summary
     */
    @objc optional func showActionSummaryOnCompletion(map: HTMap, actionID: String) -> Bool
    
    /**
     Call this method to show/hide call button to the user on the info card of an action.
     
     Note: Call button is enabled by default.
     
     - Parameter mapView: The map view where hero marker is placed
     - Returns: Bool to show/hide call button.
     */
    @objc optional func showCallButton(map: HTMap) -> Bool
    

    
}
