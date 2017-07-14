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
    
    var mapInteractionDelegate: HTViewInteractionInternalDelegate? {get set}
    var mapViewDataSource: HTMapViewDataSource? {get set}
    
    func zoomTo(visibleRegion: MKCoordinateRegion, animated: Bool)
    func updateDestinationMarker(showDestination: Bool, destinationAnnotation: HTMapAnnotation?)
    func updateHeroMarker(userId: String, actionID: String, heroAnnotation: HTMapAnnotation, disableHeroMarkerRotation: Bool)
    func animateMarker(userId: String, locations: [CLLocationCoordinate2D], currentIndex: Int, duration: TimeInterval, disableHeroMarkerRotation: Bool)
    func reFocusMap(isInfoViewCardExpanded: Bool, isDestinationViewVisible: Bool)
    func updatePolyline(polyline: String)
    func updateViewFocus(isInfoViewCardExpanded: Bool, isDestinationViewVisible: Bool)
    func clearMap()
    func focusMapFor(userId : String?)
}
