//
//  HTMap.swift
//  HyperTrack
//
//  Created by Anil Giri on 26/04/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import Foundation
import MapKit
import UIKit

/**
 Enum for multiple map providers.
 */
public enum HTMapProvider {
    /**
     Apple maps
     */
    case appleMaps
    
    /**
     Google maps
     */
    case googleMaps
    
    /**
     Open street maps
     */
    case openStreetMaps
}

/**
 The HyperTrack map object. Use the shared instance of this to set interaction and customization delegates, and embed your view object.
 */
@objc public final class HTMap: NSObject, HTConsumerClientDelegate, HTViewInteractionInternalDelegate {
    
    static let sharedInstance = HTMap()
    var interactionDelegate: HTViewInteractionDelegate?
    var customizationDelegate: HTViewCustomizationDelegate?
    var useCase = HTConstants.UseCases.TYPE_SINGLE_USER_SINGLE_ACTION
    var baseMapProvider: HTMapProvider
    var mapProvider: MapProviderProtocol?
    var mapView: MKMapView!
    var view: HTView!

    var phoneNumber: String? = nil
    var lastPlottedTime = Date.distantPast
    var mapViewDataSource = HTMapViewDataSource()
    var isAddressViewShown: Bool = true
    var isInfoViewShown: Bool = true
    var isRefocusButtonShown: Bool = true
    var isBackButtonShown: Bool = true
    var isDestinationMarkerShown: Bool = true
    
    var initialCoordinates: CLLocationCoordinate2D =
        CLLocationCoordinate2DMake(28.5621352, 77.1604902)
    
    var previousCount = 0
    var carouselHeightConstraint : NSLayoutConstraint?
    var isCarouselExpanded = false
    var enableCarouselView = false
    
    convenience override init() {
        // Default map is Apple Maps
        self.init(baseMap: HTMapProvider.appleMaps,initialRegion: MKCoordinateRegionMake(
            CLLocationCoordinate2DMake(28.5621352, 77.1604902),
            MKCoordinateSpanMake(0.005, 0.005)))
    }
    
    init(baseMap: HTMapProvider, initialRegion: MKCoordinateRegion) {
        baseMapProvider = baseMap
        super.init()
        setupViewForProvider(baseMap: self.baseMapProvider, initialRegion: initialRegion)
    }
    

    /**
     Use this method on the shared instance of the Map object, to embed the map inside your UIView object.
     
     - Parameter parentView: The UIView object that embeds the map.
     */
    public func embedIn(_ parentView: UIView) {
        self.view.frame = CGRect(x: 0, y: 0, width: parentView.frame.width, height: parentView.frame.height)
        // translate to fix height of the mapView
        parentView.translatesAutoresizingMaskIntoConstraints = true
        self.mapView.frame = CGRect(x: 0, y: 0, width: parentView.frame.width, height: parentView.frame.size.height)
        parentView.addSubview(self.view)
        addCarousel()
    }
    
    
    private func addCarousel() {
        
        var shouldShowCarouselView = false
        if customizationDelegate != nil{
            
            if #available(iOS 9.0, *) {
                if (self.customizationDelegate?.enableLiveLocationSharingView?(map: self) == true) {
                    shouldShowCarouselView = enableCarouselView
                }
            }
            self.view.isLiveLocationSharingEnabled = shouldShowCarouselView
        }
        
        if(shouldShowCarouselView){
            self.view.mapProvider = mapProvider
            self.view.addCarousel()
        }
    }
    
    /**
     Method to set the customization delegate
     
     - Parameter customizationDelegate: Object conforming to HTViewCustomizationDelegate
     */
    public func setHTViewCustomizationDelegate(customizationDelegate: HTViewCustomizationDelegate) {
        self.customizationDelegate = customizationDelegate
        
        if let initialCoordinates: CLLocationCoordinate2D = self.customizationDelegate?.initialCoordinatesFor?(map: self) {
            self.initialCoordinates = initialCoordinates
        }
        
        // HACK to enable map reload after setHTViewCustomizationDelegate()
        self.setupViewForProvider(baseMap: self.baseMapProvider, initialRegion:
            MKCoordinateRegionMake(self.initialCoordinates,
                                   MKCoordinateSpanMake(0.005, 0.005)))
    }
    
    /**
     Method to set the interaction delegate
     
     - Parameter interactionDelegate: Object conforming to HTViewInteractionDelegate
     */
    public func setHTViewInteractionDelegate(interactionDelegate: HTViewInteractionDelegate) {
        self.interactionDelegate = interactionDelegate
    }
    
    /**
     Method to remove the map from the parent view
     
     - Parameter parentView: UIView where map has been embedded
     */
    public func removeFromView(_ parentView:UIView) {
        
        if (self.view.isDescendant(of: parentView)) {
            self.view.removeFromSuperview()
        } else {
            HTLogger.shared.error("Failed::Tried to remove mapview from a view that it is not a child of.")
        }
    }
    
    /**
     Method to remove actions from the map
     */
    public func removeActions(_ actionIds: [String]? = nil) {
        // Clear action, which would clear the marker and
        // HTView UI elements
        self.mapProvider?.clearMap()
        self.lastPlottedTime = Date.distantPast
        self.mapViewDataSource.clearAllMapViewModels()
        HTConsumerClient.sharedInstance.removeActions(actionIds)
    }
    
    /**
     Method to track Action for an ActionID
     */
    func trackActionFor(actionID: String, completionHandler: ((_ action: HyperTrackAction?, _ error: HyperTrackError?) -> Void)?) {
        HTConsumerClient.sharedInstance.trackActionFor(actionID, delegate: self, completionHandler: completionHandler)
    }
    
    /**
     Method to track Action for an action's Short code
     */
    func trackActionFor(shortCode: String, completionHandler: ((_ action: HyperTrackAction?, _ error: HyperTrackError?) -> Void)?) {
        HTConsumerClient.sharedInstance.trackActionFor(shortCode: shortCode, delegate: self, completionHandler: completionHandler)
    }
    
    /**
     Method to track Action for an action's LookupId
     */
    func trackActionFor(lookUpId: String, completionHandler: ((_ actions: [HyperTrackAction]?, _ error: HyperTrackError?) -> Void)?) {
        HTConsumerClient.sharedInstance.trackActionFor(lookUpId: lookUpId, delegate: self, completionHandler: completionHandler)
    }
    
    // ViewInteractionDelegate Methods
    
    internal func didTapReFocusButton(_ sender: Any) {
        self.mapProvider?.reFocusMap(isInfoViewCardExpanded: self.view.isCardExpanded,
                                     isDestinationViewVisible: !self.view.destinationView.isHidden)
        self.interactionDelegate?.didTapReFocusButton?(sender)
    }
    
    internal func didTapBackButton(_ sender: Any) {
        self.interactionDelegate?.didTapBackButton?(sender)
        
        // Remove actions on closing HTMap screen
        // TODO - Find a better way for this (notifications like applicationDidEnterForeground etc.)
        if (self.interactionDelegate != nil), (self.interactionDelegate?.didTapBackButton != nil) {
            removeActions()
        }
    }
    
    internal func didTapPhoneButton(_ sender: Any) {
        if (self.phoneNumber != nil) {
            let cleanNumber:String = self.phoneNumber!.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "")
            if let url = URL(string: "tel://\(cleanNumber)"), UIApplication.shared.canOpenURL(url) {
                if #available(iOS 10, *) {
                    UIApplication.shared.open(url)
                } else {
                    UIApplication.shared.openURL(url)
                }
            }
        }
        self.interactionDelegate?.didTapPhoneButton?(sender)
    }
    
    internal func didTapHeroMarkerFor(userID: String) {
        self.interactionDelegate?.didTapHeroMarkerFor?(userID: userID)
    }
    
    internal func didTapExpectedPlaceMarkerFor(actionID: String) {
        self.interactionDelegate?.didTapExpectedPlaceMarkerFor?(actionID: actionID)
    }
    
    internal func didTapInfoViewFor(actionID: String) {
        self.interactionDelegate?.didTapInfoViewFor?(actionID: actionID)
    }
    
    internal func didTapMapView() {
        self.interactionDelegate?.didTapMapView?()
    }
    
    internal func didPanMapView() {
        self.interactionDelegate?.didPanMapView?()
    }
    
    // MARK Private
    func setupViewForProvider(baseMap: HTMapProvider, initialRegion: MKCoordinateRegion) {
        self.mapView = getMapView()
        initHTView(mapView: mapView)
        
        self.mapProvider = self.providerFor(baseMap)
        self.mapProvider?.zoomTo(visibleRegion: initialRegion, animated: true)
        self.mapProvider?.mapInteractionDelegate = self
        self.mapProvider?.mapViewDataSource = self.mapViewDataSource
    }
    
    func getMapView() -> MKMapView {
        let mapView = MKMapView()
        mapView.mapType = MKMapType.standard
        mapView.isZoomEnabled = true
        mapView.isRotateEnabled = false
        mapView.isScrollEnabled = true
        
        // Handle Traffic layer customization, for iOS 9 and above
        if #available(iOS 9.0, *) {
            if let showsTraffic = self.customizationDelegate?.showTrafficForMapView?(map: self) {
                mapView.showsTraffic = showsTraffic
                
            } else {
                mapView.showsTraffic = false
            }
        }
        
        return mapView
    }
    
    func initHTView(mapView: UIView) {
        let bundleRoot = Bundle(for: HyperTrack.self)
        let bundle = Bundle(path: "\(bundleRoot.bundlePath)/HyperTrack.bundle")
        let htView: HTView = bundle!.loadNibNamed("HTView", owner: self, options: nil)?.first as! HTView
        htView.initMapView(mapSubView: self.mapView, interactionViewDelegate: self)
        self.view = htView
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
        
        provider.mapViewDataSource = self.mapViewDataSource
        return provider
    }
    
    func computeUseCase(){
        let userIds = HTConsumerClient.sharedInstance.getUserIds()
        if (userIds.count > 0) {
            if (userIds.count == 1) {
                if (HTConsumerClient.sharedInstance.getActions(userId:userIds.first!)?.count == 1) {
                    self.useCase = HTConstants.UseCases.TYPE_SINGLE_USER_SINGLE_ACTION
                    
                } else {
                    self.useCase = HTConstants.UseCases.TYPE_SINGLE_USER_MULTIPLE_ACTION
                }
            } else {
                self.useCase =  HTConstants.UseCases.TYPE_MULTIPLE_USER_MULTIPLE_ACTION_SAME_PLACE
            }
        }
    }
    
    func onUpdateAllUsers(){
        let userIds = HTConsumerClient.sharedInstance.getUserIds()
        if (userIds.count > 0) {
            // Compute use-case for tracking experience
            computeUseCase()
            
            // Update data for all users being tracked currently
            for userId in userIds {
                onUpdateUser(userId: userId)
            }
            
            // Reset UserInfo View
            self.reloadView()
        }
    }
    
    func onUpdateUser(userId : String){
        let trackedUser = HTConsumerClient.sharedInstance.getUser(userId:userId)
        let actionIds = HTConsumerClient.sharedInstance.getActionIds(userId: userId)
        onUpdateAllActions(userId: userId, actions: actionIds!)
        
        // Process time aware polyline for updating hero marker
        processTimeAwarePolyline(userId: (trackedUser?.expandedUser?.id)!,
                                 timeAwarePolyline: trackedUser?.expandedUser?.timeAwarePolyline)
    }
    
    func onUpdateAllActions(userId : String, actions : [String]){
        if(actions.count > 0){
            for actionId in actions {
                onUpdateAction(userId: userId, actionId: actionId)
            }
        }
    }
    
    func onUpdateAction(userId:String, actionId:String){
        // add action specific logic here
        if (self.useCase == HTConstants.UseCases.TYPE_SINGLE_USER_SINGLE_ACTION) {
            let action: HyperTrackAction = HTConsumerClient.sharedInstance.getAction(actionId: actionId)!
            
            // Stop Polling on action completed for order tracking use-case
            if (action.display != nil), (action.display?.showSummary == true) {
                
                // Stop polling inside Action Store
                HTConsumerClient.sharedInstance.stopPolling()
            }
        }
    }
    
    func reloadView(){
        // Reset common views
        resetUserInfo(nil)
        resetAddressInfo(nil)
        
        // Reset destinationMarker for multiple action to same place
        resetDestinationMarker(nil)
        
        // Reset other views
        resetReFocusButton()
        resetBackButton()
        
        // Reset view focus
        self.mapProvider?.updateViewFocus(isInfoViewCardExpanded: self.view.isCardExpanded,
                                          isDestinationViewVisible: !(self.view.destinationView.isHidden))
    }
    
    func resetUserInfo(_ actionIdToBeUpdated: String?){
        var actionId = actionIdToBeUpdated
        if (actionId == nil) {
            actionId = HTConsumerClient.sharedInstance.getActionIds().first
        }
        
        // Expanded card
        var userName: String = ""
        var lastUpdated: Date = Date()
        var speed: Int?
        var battery: Int?
        var photoUrl: URL?
        var etaMinutes: Double? = nil
        var distanceLeft: Double? = nil
        var distanceCovered: Double = 0
        var status: String = ""
        var timeElapsedMinutes: Double = 0
        var showActionDetailSummary = false
        var showActionPolylineSummary = false
        var showExpandedCardOnCompletion = true
        
        let action: HyperTrackAction = HTConsumerClient.sharedInstance.getAction(actionId: actionId!)!
        
        if let startedAt = action.startedAt {
            var timeElapsed: Double?
            
            if action.endedAt != nil {
                timeElapsed = startedAt.timeIntervalSince(action.endedAt!)
            } else {
                timeElapsed = startedAt.timeIntervalSinceNow
            }
            
            timeElapsedMinutes = -1 * Double(timeElapsed! / 60)
        }
        
        if let distance = action.distance {
            // Convert distance (meters) to miles and round to one decimal
            distanceCovered = round(distance * 0.000621371 * 10) / 10
        }
        
        if let user = action.user as HyperTrackUser? {
            userName = user.name!
            if let photo = user.photo {
                photoUrl = URL(string: photo)
            }
            
            if let batteryPercentage = user.lastBattery {
                battery = batteryPercentage
            }
            
            if let heartbeat = user.lastHeartbeatAt {
                lastUpdated = heartbeat
            }
            
            if let location = user.lastLocation {
                if location.speed >= 0 {
                    speed = Int(location.speed * 2.23693629)
                }
            }
        }
        
        let actionDisplay = action.display
        if (actionDisplay != nil) {
            if let duration = actionDisplay!.durationRemaining {
                let timeRemaining = duration
                etaMinutes = Double(timeRemaining / 60)
            }
            
            if let statusText = actionDisplay!.statusText {
                status = statusText
            }
            
            if let distance = actionDisplay!.distanceRemaining {
                // Convert distance (meters) to miles and round to one decimal
                distanceLeft = round(Double(distance) * 0.000621371 * 10) / 10
            }
            
            showActionDetailSummary = actionDisplay!.showSummary
            
            // Check if Action summary needs to be displayed on map or not
            if self.useCase == HTConstants.UseCases.TYPE_SINGLE_USER_SINGLE_ACTION {
                showActionPolylineSummary = actionDisplay!.showSummary
                showExpandedCardOnCompletion = actionDisplay!.showSummary
            }
        }
        
        // Check if info view has been customized and update accordingly
        if let isInfoViewShown = self.customizationDelegate?.showInfoViewForActionID?(map: self, actionID: action.id!) {
            self.isInfoViewShown = isInfoViewShown
        }
        
        var startAddress: String?
        var completeAddress: String?
        
        if let address = action.startedPlace?.address {
            startAddress = address
        }
        
        if let address = action.completedPlace?.address {
            completeAddress = address
        }
        
        self.view.updateInfoView(isInfoViewShown: self.isInfoViewShown,
                                 showActionDetailSummary: showActionDetailSummary,
                                 eta: etaMinutes, distanceLeft: distanceLeft,
                                 status: status, userName: userName,
                                 lastUpdated: lastUpdated, timeElapsed: timeElapsedMinutes,
                                 distanceCovered: distanceCovered, speed: speed,
                                 battery: battery, photoUrl: photoUrl,
                                 startTime: action.assignedAt, endTime: action.endedAt,
                                 origin: startAddress, destination: completeAddress,
                                 showExpandedCardOnCompletion: showExpandedCardOnCompletion)
        
        if (showActionPolylineSummary) {
            self.mapProvider?.clearMap()
            if let encodedPolyline = action.encodedPolyline {
                self.mapProvider?.updatePolyline(polyline: encodedPolyline)
            }
        }
        
        // Update user's phone number to be used in didTapCallButton
        if let user = action.user as HyperTrackUser? {
            if let phone = user.phone as String? {
                self.phoneNumber = phone
            }
        }
    }
    
    func resetAddressInfo(_ actionIdToBeUpdated: String?){
        var actionId = actionIdToBeUpdated
        if (actionId == nil) {
            actionId = HTConsumerClient.sharedInstance.getActionIds().first
        }
        
        let action: HyperTrackAction = HTConsumerClient.sharedInstance.getAction(actionId: actionId!)!
        
        var destinationAddress: String = ""
        if let place = action.expectedPlace {
            destinationAddress = place.address!
        } else {
            // Hide address view if expected place is not available
            self.view.updateAddressView(isAddressViewShown: false,
                                        destinationAddress: destinationAddress)
            return
        }
        
        // Check if address view has been customized and update accordingly
        if let isAddressViewShown = self.customizationDelegate?.showAddressViewForActionID?(map: self, actionID: action.id!) {
            self.isAddressViewShown = isAddressViewShown
        }
        
        // Hide Address view if action is completed
        if (self.useCase == HTConstants.UseCases.TYPE_SINGLE_USER_SINGLE_ACTION), (action.display != nil) {
            self.isAddressViewShown = !(action.display!.showSummary)
        }
        
        self.view.updateAddressView(isAddressViewShown: self.isAddressViewShown,
                                    destinationAddress: destinationAddress)
    }
    
    func resetDestinationMarker(_ actionIdToBeUpdated: String?) {
        var actionId = actionIdToBeUpdated
        if (actionId == nil) {
            actionId = HTConsumerClient.sharedInstance.getActionIds().first
        }
        
        let action: HyperTrackAction = HTConsumerClient.sharedInstance.getAction(actionId: actionId!)!
        
        // Check if action has been completed for order tracking use-case
        if (self.useCase == HTConstants.UseCases.TYPE_SINGLE_USER_SINGLE_ACTION), (action.display != nil), (action.display?.showSummary == true) {
            return
        }
        
        if let expectedPlaceCoordinates = HTConsumerClient.sharedInstance.getExpectedPlaceLocation(actionId: action.id!) {
            
            // Handle destinationMarker customization
            if let isDestinationMarkerShown = self.customizationDelegate?.showExpectedPlaceMarker?(map: self, actionID: action.id!) {
                self.isDestinationMarkerShown = isDestinationMarkerShown
            }
            
            // Get annotation for destinationMarker
            let destinationAnnotation = HTMapAnnotation()
            destinationAnnotation.coordinate = expectedPlaceCoordinates
            destinationAnnotation.title = "destination"
            destinationAnnotation.type = HTConstants.MarkerType.DESTINATION_MARKER
            
            self.mapProvider?.updateDestinationMarker(showDestination: self.isDestinationMarkerShown, destinationAnnotation: destinationAnnotation)
            
        } else{
            self.mapProvider?.updateDestinationMarker(showDestination: false, destinationAnnotation: nil)
        }
    }
    
    func resetReFocusButton() {
        // Check if ReFocus Button has been customized and update accordingly
        if let isRefocusButtonShown = self.customizationDelegate?.showReFocusButton?(map: self) {
            self.isRefocusButtonShown = isRefocusButtonShown
        }
        self.view.updateReFocusButton(isRefocusButtonShown: self.isRefocusButtonShown)
    }
    
    func resetBackButton() {
        // Check if Back Button has been customized and update accordingly
        if let isBackButtonShown = self.customizationDelegate?.showBackButton?(map: self) {
            self.isBackButtonShown = isBackButtonShown
        }
        self.view.updateBackButton(isBackButtonShown: self.isBackButtonShown)
    }
    
    func processTimeAwarePolyline(userId : String, timeAwarePolyline:String?){
        // Decode updated TimeAwarePolyine
        var deocodedLocations: [TimedCoordinates] = []
        if (timeAwarePolyline != nil) {
            if let timedCoordinates = timedCoordinatesFrom(polyline: timeAwarePolyline!) {
                deocodedLocations = timedCoordinates
            }
        }
        
        // Get new locations from decodedLocations
        let newLocations = deocodedLocations.filter{$0.timeStamp > self.lastPlottedTime}
        var coordinates = newLocations.map{$0.location}
        
        // MARK TODO- temporary check
        if coordinates.count > 50 {
            coordinates = Array(coordinates.suffix(from: coordinates.count - 50))
        }
        
        self.setUpHeroMarker(userId: userId, coordinates: coordinates)
        
        // Update lastPlottedTime to reflect latest animated point
        if let lastPoint = newLocations.last {
            self.lastPlottedTime = lastPoint.timeStamp
        }
    }
    
    func setUpHeroMarker(userId: String, coordinates: [CLLocationCoordinate2D]) {
        
        if (coordinates.count < 1) {
            return
        }
        
        let user = HTConsumerClient.sharedInstance.getUser(userId: userId)
        let action = user?.actions?.first as! HyperTrackAction
        
        // Check if action has been completed for order tracking use-case
        if (self.useCase == HTConstants.UseCases.TYPE_SINGLE_USER_SINGLE_ACTION), (action.display != nil), (action.display?.showSummary == true) {
            return
        }
        
        var heroAnnotation = self.mapViewDataSource.getMapViewModel(userId: userId)?.heroMarker
        if (heroAnnotation == nil) {
            
            if let coordinate = coordinates.first as CLLocationCoordinate2D? {
                heroAnnotation = HTMapAnnotation()
                heroAnnotation!.type = HTConstants.MarkerType.HERO_MARKER
                heroAnnotation!.coordinate = coordinate
                
                if (self.customizationDelegate?.enableLiveLocationSharingView?(map: self) == true) {
                    heroAnnotation!.disableRotation = true
                    heroAnnotation!.type = HTConstants.MarkerType.HERO_MARKER_WITH_ETA
                    
                    if let userName = user?.expandedUser?.name {
                        let userNameArr = userName.components(separatedBy: " ")
                        heroAnnotation!.title = userNameArr[0]
                    }
                    
                    heroAnnotation!.subtitle = getSubtitleDisplayText(action: action as! HyperTrackAction)?.capitalized
                
                } else if let disableHeroMarkerRotation =
                    self.customizationDelegate?.disableHeroMarkerRotationForActionID?(
                        map: self, actionID: action.id!) {
                    heroAnnotation!.disableRotation = disableHeroMarkerRotation
                }
                
                self.mapProvider?.updateHeroMarker(userId: userId,
                                                   actionID: action.id!,
                                                   heroAnnotation: heroAnnotation!,
                                                   disableHeroMarkerRotation: heroAnnotation!.disableRotation)
            }
        }
        
        heroAnnotation!.subtitle = getSubtitleDisplayText(action: action as! HyperTrackAction)?.capitalized
        self.mapViewDataSource.setHeroMarker(userId: userId,
                                             annotation: heroAnnotation)
        
        // TODO - Update eta on hero marker for LLS use-case
        let unitAnimationDuration = 5.0 / Double(coordinates.count)
        self.mapProvider?.animateMarker(userId: userId, locations: coordinates, currentIndex: 0, duration: unitAnimationDuration, disableHeroMarkerRotation: heroAnnotation!.disableRotation)
    }
    
    func getSubtitleDisplayText(action:HyperTrackAction) -> String?{
        
        var subtitle = ""
        
        if let action = action as HyperTrackAction?, let actionStatus = action.status {
            if actionStatus == "completed" {
                subtitle = "completed"
                return subtitle
            }else if (actionStatus == "suspended"){
                subtitle = "suspended"
                return subtitle
            }
        }
        
        if let actionDisplay = action.display {
            if let duration = actionDisplay.durationRemaining {
                let timeRemaining = duration
                let etaMinutes = Double(timeRemaining / 60)
                let eta:String = String(format:"%.0f", etaMinutes)
                subtitle = eta.description + " min"
                return subtitle
            }
            
            if let statusText = actionDisplay.statusText {
                return statusText
            }
        }
        return subtitle
    }
    
    public func onUserListUpdated() {
        self.onUpdateAllUsers()
    }
    
    public func onUserListChanged(){
        self.onUpdateAllUsers()
    }
    
    public func onActionStatusChanged(actionIds:[String],actions:[HyperTrackAction]){
        
    }
    
    public func onActionStatusRefreshed(actionIds:[String],actions:[HyperTrackAction]){
        
    }
    
    public func onActionsRemoved() {
        
    }
}
