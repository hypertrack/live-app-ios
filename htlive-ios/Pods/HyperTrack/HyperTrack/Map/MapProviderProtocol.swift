//
//  MapProviderProtocol.swift
//  HyperTrack
//
//  Created by Anil Giri on 27/04/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import Foundation
import MapKit

protocol MapProviderProtocol {
  
  var mapInteractionDelegate: HTMapInteractionDelegate? {get set}
  
  func zoomTo(visibleRegion: MKCoordinateRegion, animated: Bool)
  func updateDestinationMarker(destinationAnnotation: MKPointAnnotation)
  func updateHeroMarker(heroAnnotation: MKPointAnnotation, actionID: String)
  func animateMarker(locations: [CLLocationCoordinate2D], currentIndex: Int, duration: TimeInterval)
  func reFocusMap()
  func updatePolyline(polyline: String)
  func updateViewFocus()
  func clearMap()
}
