//
//  HTMap.swift
//  HyperTrack
//
//  Created by Anil Giri on 26/04/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import Foundation
import MapKit

public enum HTMapProvider {
    case appleMaps
    case googleMaps
    case openStreetMaps
}

// Enables the thirdy party to receive map interaction events
// Should be implemented by the Object that wants to know if the user interacts with the map
public protocol HTMapInteractionDelegate {
    func didTapRouteFor(userID: String)
    func didTapMarkerFor(userID: String)
    func didTapUserInfoPanelFor(activeUserID: String)
    func didTapMapView()
    func didPanMapView()
}

public protocol HTBackButtonDelegate {
    func backButtonClicked(_ sender: Any)
}

@objc public final class  HTMap: NSObject, HTMapInteractionDelegate, ActionStoreDelegate, HTViewInteractionDelegate {
    
    static let sharedInstance = HTMap()
    var baseMapProvider: HTMapProvider
    var mapProvider: MapProviderProtocol?
    var mapView: MKMapView!
    
    var view: HTView!
    var interactionDelegate: HTMapInteractionDelegate?
    var backButtonDelegate: HTBackButtonDelegate?
    
    var lastPlottedTime = Date.distantPast
    var lastPosition: CLLocationCoordinate2D?
    var destination: CLLocationCoordinate2D?
    
    convenience public override init() {
        // Default map is Apple Maps
        self.init(baseMap: HTMapProvider.appleMaps,
                  initialRegion: MKCoordinateRegionMake(CLLocationCoordinate2DMake(28.5621352, 77.1604902),
                                                        MKCoordinateSpanMake(0.005, 0.005)))
    }
    
    public init(baseMap: HTMapProvider, initialRegion: MKCoordinateRegion) {
        baseMapProvider = baseMap
        super.init()
        setupViewForProvider(baseMap: self.baseMapProvider, initialRegion: initialRegion)
    }
    
    public func embedIn(_ parentView: UIView) {
        self.view.frame = CGRect(x: 0, y: 0, width: parentView.frame.width, height: parentView.frame.height)
        // translate to fix height of the mapView
        parentView.translatesAutoresizingMaskIntoConstraints = true
        
        self.mapView.frame = CGRect(x: 0, y: 0, width: parentView.frame.width, height: parentView.frame.size.height)
        parentView.addSubview(self.view)
    }
    
    public func setBackButtonDelegate(backButtonDelegate: HTBackButtonDelegate) {
        self.backButtonDelegate = backButtonDelegate
    }
    
    public func removeFromView(_ parentView:UIView) {
        
        if (self.view.isDescendant(of: parentView)) {
            self.view.removeFromSuperview()
        } else {
            print("Failed::Tried to remove mapview from a view that it is not a child of.")
        }
    }
    
    func trackActionFor(actionID: String) {
        ActionStore.sharedInstance.trackActionFor(actionID, delegate: self)
    }
    
    func trackActionFor(shortCode: String) {
        ActionStore.sharedInstance.trackActionFor(shortCode: shortCode, delegate: self)
    }
    
    // MARK: Map interaction delegate
    
    public func didTapRouteFor(userID: String) {
        self.interactionDelegate?.didTapRouteFor(userID: userID)
    }
    
    public func didTapMarkerFor(userID: String) {
        self.interactionDelegate?.didTapRouteFor(userID: userID)
    }
    
    public func didTapUserInfoPanelFor(activeUserID: String) {
        self.interactionDelegate?.didTapUserInfoPanelFor(activeUserID: activeUserID)
    }
    
    public func didTapMapView() {
        self.interactionDelegate?.didTapMapView()
    }
    
    public func didPanMapView() {
        self.interactionDelegate?.didPanMapView()
    }
    
    // MARK Private
    func setupViewForProvider(baseMap: HTMapProvider, initialRegion: MKCoordinateRegion) {
        self.mapView = getMapView()
        initHTView(mapView: mapView)
        
        self.mapProvider = self.providerFor(baseMap)
        self.mapProvider?.zoomTo(visibleRegion: initialRegion, animated: true)
        self.mapProvider?.mapInteractionDelegate = self
    }
    
    func getMapView() -> MKMapView {
        let mapView = MKMapView()
        mapView.mapType = MKMapType.standard
        mapView.isZoomEnabled = true
        mapView.isRotateEnabled = false
        mapView.isScrollEnabled = true
        return mapView
    }
    
    func initHTView(mapView: UIView) {
        let bundleRoot = Bundle(for: HyperTrack.self)
        let bundle = Bundle(path: "\(bundleRoot.bundlePath)/HyperTrack.bundle")
        let htView: HTView = bundle!.loadNibNamed("HTView", owner: self, options: nil)?.first as! HTView
        htView.initMapView(mapSubView: self.mapView, delegate: self)
        self.view = htView
    }
    
    func refocusButtonClicked(_ sender: Any) {
        self.mapProvider?.reFocusMap()
    }
    
    func backButtonClicked(_ sender: Any) {
        self.backButtonDelegate?.backButtonClicked(sender)
    }
    
    func viewFor(_ mapType: HTMapProvider) -> MKMapView {
        var mapView: MKMapView
        
        switch mapType {
        case .appleMaps:
            mapView = MKMapView()
            (mapView as! MKMapView).isRotateEnabled = false
            (mapView as! MKMapView).isZoomEnabled = false
            (mapView as! MKMapView).camera.heading = 0.0
            break
            
        case .googleMaps:
            mapView = MKMapView() // TODO: Instantiate GoogleMaps view
            break
            
        case .openStreetMaps:
            mapView = MKMapView() // TODO: Instantiate OSM view
            break
        }
        
        return mapView
    }
    
    func providerFor(_ mapType: HTMapProvider) -> MapProviderProtocol {
        
        var provider: MapProviderProtocol
        
        switch mapType {
        case .appleMaps:
            provider = AppleMapsProvider(mapView:self.mapView as! MKMapView)
            break
            
        case .googleMaps:
            provider = AppleMapsProvider(mapView:self.mapView as! MKMapView) // TODO: Instantiate GoogleMaps Adapter
            break
            
        case .openStreetMaps:
            provider = AppleMapsProvider(mapView:self.mapView as! MKMapView) // TODO: Instantiate OSM Maps Adapter
            break
        }
        
        return provider
    }
    
    public func didReceiveLocationUpdates(_ locations: [TimedCoordinates], action: HyperTrackAction?) {
        
        let newLocations = locations.filter{$0.timeStamp > self.lastPlottedTime}
        let coordinates = newLocations.map{$0.location}
        
        if let action = action {
            updateMapForAction(action, locations: coordinates)
        }
        
        if let lastPoint = newLocations.last {
            self.lastPlottedTime = lastPoint.timeStamp
        }
    }
    
    public func clearAction() {
        // Clear action, which would clear the marker and
        // HTView UI elements
        self.mapProvider?.clearMap()
    }
    
    func updateMapForAction(_ action: HyperTrackAction, locations: [CLLocationCoordinate2D]) {
        
        print("\(Date()): Received \(locations.count) points for entityID: \(String(describing: action.id))")
        
        var coordinates = locations
        if locations.count > 50 { // MARK TODO- temporary check
            coordinates = Array(locations.suffix(from: locations.count - 50))
        }
        
        if self.lastPosition == nil {
            self.lastPosition = coordinates.first
        }
        
        updateDestinationForAction(action: action)
        updateHeroMarkerForAction(action: action, locations: coordinates)
        updateActionData(action: action)
        
        if let action = action as HyperTrackAction?, let actionStatus = action.status {
            if actionStatus != "completed" {
                let unitAnimationDuration = 5.0 / Double(coordinates.count)
                self.mapProvider?.animateMarker(locations: coordinates, currentIndex: 0, duration: unitAnimationDuration)
            } else {
                self.mapProvider?.clearMap()
                self.mapProvider?.updatePolyline(polyline: action.encodedPolyline!)
            }
        }
        
        self.mapProvider?.updateViewFocus()
    }
    
    func updateDestinationForAction(action: HyperTrackAction) {
        var destination = self.lastPosition
        if let degrees = action.expectedPlace?.location?.coordinates {
            destination = CLLocationCoordinate2DMake((degrees.last)!, (degrees.first)!)
            self.destination = destination
        }
        
        if let destination = self.destination {
            let destinationAnnotation = MKPointAnnotation()
            destinationAnnotation.coordinate = destination
            self.mapProvider?.updateDestinationMarker(destinationAnnotation: destinationAnnotation)
        }
    }
    
    func updateHeroMarkerForAction(action: HyperTrackAction, locations: [CLLocationCoordinate2D]) {
        let annotation = MKPointAnnotation()
        if let coordinate = locations.first as CLLocationCoordinate2D? {
            annotation.coordinate = coordinate
            self.mapProvider?.updateHeroMarker(heroAnnotation: annotation, actionID: action.id!)
        }
    }
    
    func updateActionData(action: HyperTrackAction) {
        if let action = action as HyperTrackAction! {
            var destinationString: String
            var etaMinutes: Double
            var distanceCovered: Double
            var status: String
            var timeElapsedMinutes: Double
            var isCompleted = true
            
            if let startedAt = action.startedAt {
                
                var timeElapsed: Double?
                
                if action.completedAt != nil {
                    timeElapsed = action.startedAt?.timeIntervalSince(action.completedAt!)
                } else {
                    timeElapsed = action.startedAt?.timeIntervalSinceNow
                }
                
                timeElapsedMinutes = -1 * Double(timeElapsed! / 60)
            } else {
                timeElapsedMinutes = 0
            }
            
            if let place = action.expectedPlace {
                destinationString = place.address!
            } else {
                destinationString = ""
            }
            
            if let actionDisplay = action.display {
              
                if let duration = actionDisplay.durationRemaining {
                    let timeRemaining = duration
                    etaMinutes = Double(timeRemaining / 60)
                } else {
                    etaMinutes = 0
                }
                
                if let statusText = actionDisplay.statusText {
                    status = statusText
                } else {
                    status = ""
                }

            } else {
                status = ""
                etaMinutes = 0
            }
            
            if let distance = action.distance {
                // Convert distance (meters) to miles and round to one decimal
                distanceCovered = round(distance * 0.000621371 * 10) / 10
            } else {
                distanceCovered = 0
            }
            
            if let action = action as HyperTrackAction?, let actionStatus = action.status {
                if actionStatus != "completed" {
                    isCompleted = false
                }
            }
            
            self.view.updateStats(destination: destinationString, eta: etaMinutes, distanceCovered: distanceCovered, status: status, timeElapsed: timeElapsedMinutes, isCompleted: isCompleted)
        }
    }
}
