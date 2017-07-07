//
//  MapAdapterDelegate.swift
//  HyperTrack
//
//  Created by Piyush on 24/05/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import Foundation
import MapKit

@objc protocol MapAdapterDelegate {
  @objc optional
  
  /**
   *  Call this method to provide a image to the hero marker. This image should be oriented to the north so that bearing of marker is perfect.
   *
   *  @param mapView  The map view where hero marker is placed
   *  @param taskID   The taskID for which image is to be provided
   *
   *  @return Image for the hero marker
   */
  func heroMarkerImageForActionID(map: HTMap, actionID: String) -> UIImage
  
  /**
   *  Call this method to provide a view to the hero marker. This view should be oriented to the north so that bearing of marker is perfect.
   *
   *  @param mapView  The map view where hero marker is placed
   *  @param taskID   The taskID for which view is to be provided
   *
   *  @return MKAnnotationView for the hero marker
   */
  func heroMarkerViewForActionID(map: HTMap, actionID: String) -> MKAnnotationView
  
  /**
   *  Call this method to set or unset rotation for the hero marker
   *
   *  @param mapView  The map view where hero marker is placed
   *  @param  taskID  The hypertrack taskID
   *
   *  @return Bool for the rotation of hero marker
   */
  func disableHeroMarkerRotationForActionID(map: HTMap, actionID: String) -> Bool
  
  /**
   *  Call this method to provide a image to the start marker. This image should be oriented to the north so that bearing of marker is perfect.
   *
   *  @param mapView  The map view where start marker is placed
   *  @param taskID   The taskID for which image is to be provided
   *
   *  @return Image for the start marker
   */
  func startMarkerImageForActionID(map: HTMap, actionID: String) -> UIImage
  
  /**
   *  Call this method to provide a view to the start marker. This view should be oriented to the north so that bearing of marker is perfect.
   *
   *  @param mapView  The map view where start marker is placed
   *  @param taskID   The taskID for which view is to be provided
   *
   *  @return MKAnnotationView for the start marker
   */
  func startMarkerViewForActionID(map: HTMap, actionID: String) -> MKAnnotationView
  
  /**
   *  Call this method to provide a image to the destination marker. This image should be oriented to the north so that bearing of marker is perfect.
   *
   *  @param mapView  The map view where destination marker is placed
   *  @param taskID   The taskID for which image is to be provided
   *
   *  @return Image for the destination marker
   */
  func expectedPlaceMarkerImageForActionID(map: HTMap, actionID: String) -> UIImage
  
  /**
   *  Call this method to provide a view to the destination marker. This view should be oriented to the north so that bearing of marker is perfect.
   *
   *  @param mapView  The map view where destination marker is placed
   *  @param taskID   The taskID for which view is to be provided
   *
   *  @return MKAnnotationView for the destination marker
   */
  func expectedPlaceMarkerViewForActionID(map: HTMap, actionID: String) -> MKAnnotationView
  
  /**
   *  Call this method to show/hide the driver info view, which has the photo, name and call button.
   *
   *  @param mapView  The map view where info view is visible
   *  @param taskID   The taskID for which driver info is to be hidden
   *
   *  @return Bool to show/hide driver info view
   */
  func showInfoViewForActionID(map: HTMap, actionID: String) -> Bool
  
  /**
   *  Call this method to show/hide the call button
   *
   *  @param mapView  The map view where info view is visible
   *  @param taskID   The taskID for which call is to be hidden
   *
   *  @return Bool to show/hide call button
   */
  func showCallButtonInInfoViewForActionID(map: HTMap, actionID: String) -> Bool

  /**
   *  Call this method to show/hide the call to source marker
   *
   *  @param mapView  The map view where source marker is visible
   *  @param taskID   The taskID for which source marker is to be hidden
   *
   *  @return Bool to show/hide source marker
   */
  func showStartMarker(map: HTMap, actionID: String) -> Bool
  
  /**
   *  Call this method to disable action summary on completion
   *
   *  @param mapView  The map view where action summary is visible
   *
   *  @return Bool to disable action summary
   */
  func showActionSummaryOnCompletion(map: HTMap, actionID: String) -> Bool
  
  /**
   *  Call this method to set/unset traffic layer on mapview
   *
   *  @param mapView  The map view where traffic is visible
   *
   *  @return Bool to show/hide traffic layer
   */
  func showTrafficLayer(map: HTMap, actionID: String) -> Bool
}
