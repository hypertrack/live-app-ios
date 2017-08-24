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
@objc public final class HTMap: NSObject {
    
    static let sharedInstance = HTMap()
    var interactionDelegate: HTViewInteractionDelegate?
    var customizationDelegate: HTViewCustomizationDelegate?
    var useCase = HTConstants.UseCases.TYPE_SINGLE_USER_SINGLE_ACTION
    var baseMapProvider: HTMapProvider
    var mapView: MKMapView!
    var view: HTCommonView!

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
    var enableCarouselView = true
    
    
    
    public var enableLiveLocationSharingView = false {
        didSet {
            if(self.enableLiveLocationSharingView != oldValue){
                if(self.enableLiveLocationSharingView){
                    //     self.view.enableLiveLocationSharing()
                }
            }
        }
    }
    
    
    public var showReFocusButton = true {
        
        didSet {
            if(self.showReFocusButton != oldValue){
                
            }
        }
    }
    
    
    public var showBackButton = true {
        didSet {
            if(self.showBackButton != oldValue){
                
            }
            
        }
    }
    
    public var showTrafficForMapView = false {
        didSet {
            if(self.showTrafficForMapView != oldValue){
            }
            
        }
    }
    
    
    public var initialCoordinatesFor:CLLocationCoordinate2D? = nil {
        didSet {
            
            
        }
    }
    
    convenience override init() {
        
        // default map is apple maps
        self.init(baseMap: HTMapProvider.appleMaps)
        
        self.enableLiveLocationSharingView = false
        self.showBackButton = true
        self.showReFocusButton = true
        self.showTrafficForMapView = false
        
        // choose initial location based on user current location, if it is not present then fallback to default
        
        if let location = Transmitter.sharedInstance.locationManager.getLastKnownLocation(){
            self.initialCoordinates = location.coordinate
        }else{
            self.initialCoordinates = CLLocationCoordinate2DMake(28.5621352, 77.1604902)
        }
    }
    
    init(baseMap: HTMapProvider) {
        baseMapProvider = baseMap
        super.init()
    }
    
    /**
     Use this method on the shared instance of the Map object, to embed the map inside your UIView object.
     
     - Parameter parentView: The UIView object that embeds the map.
     */
    public func embedIn(_ parentView: UIView) {
        
        let region = MKCoordinateRegionMake(self.initialCoordinates,MKCoordinateSpanMake(0.005, 0.005))
        self.setupViewForProvider(baseMap: baseMapProvider, initialRegion: region)
        
        self.view.frame = CGRect(x: 0, y: 0, width: parentView.frame.width, height: parentView.frame.height)
        // translate to fix height of the mapView
        parentView.translatesAutoresizingMaskIntoConstraints = true
        self.mapView.frame = CGRect(x: 0, y: 0, width: parentView.frame.width, height: parentView.frame.size.height)
        parentView.addSubview(self.view)
        if #available(iOS 9.0, *) {
            self.view.widthAnchor.constraint(equalToConstant: parentView.frame.width).isActive = true
            self.view.heightAnchor.constraint(equalToConstant: parentView.frame.height).isActive = true
        }
    }
    
    
    func getMapView() -> MKMapView {
        let mapView = MKMapView()
        mapView.mapType = MKMapType.standard
        mapView.isZoomEnabled = true
        mapView.isRotateEnabled = false
        mapView.isScrollEnabled = true
        
        // Handle Traffic layer customization, for iOS 9 and above
        if #available(iOS 9.0, *) {
            if let showTraffic = self.customizationDelegate?.showTrafficForMapView?(map: self) {
                self.showTrafficForMapView = showTraffic
            }
            mapView.showsTraffic = self.showTrafficForMapView
        }
        return mapView
    }
    
    func initHTView(mapView: UIView, mapProvider : MapProviderProtocol) {
        let bundleRoot = Bundle(for: HyperTrack.self)
        let bundle = Bundle(path: "\(bundleRoot.bundlePath)/HyperTrack.bundle")
        let htView: HTView = bundle!.loadNibNamed("HTView", owner: self, options: nil)?.first as! HTView
        htView.mapProvider = mapProvider
        htView.initMapView(mapSubView: self.mapView, interactionViewDelegate: self)
        self.view = htView
        self.view.customizationDelegate = self
    }
    
    
    func initLiveLocationView(mapView: UIView , mapProvider : MapProviderProtocol) {
        let bundleRoot = Bundle(for: HyperTrack.self)
        let bundle = Bundle(path: "\(bundleRoot.bundlePath)/HyperTrack.bundle")
        let htView: HTLiveLocationView = bundle!.loadNibNamed("LiveLocationView", owner: self, options: nil)?.first as! HTLiveLocationView
        htView.mapProvider = mapProvider
        htView.initMapView(mapSubView: self.mapView, interactionViewDelegate: self)
        self.view = htView
    }
    
    
    
    func viewFor(_ mapType: HTMapProvider) -> MKMapView {
        var mapView: MKMapView
        
        switch mapType {
        case .appleMaps:
            mapView = MKMapView()
            mapView.isRotateEnabled = false
            mapView.isZoomEnabled = false
            mapView.camera.heading = 0.0
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
            provider = AppleMapsProvider(mapView:self.mapView)
            break
            
        case .googleMaps:
            provider = AppleMapsProvider(mapView:self.mapView) // TODO: Instantiate GoogleMaps Adapter
            break
            
        case .openStreetMaps:
            provider = AppleMapsProvider(mapView:self.mapView) // TODO: Instantiate OSM Maps Adapter
            break
        }
        
        provider.mapViewDataSource = self.mapViewDataSource
        return provider
    }
    
    
    
    // MARK Private
    func setupViewForProvider(baseMap: HTMapProvider, initialRegion: MKCoordinateRegion) {
        self.mapView = getMapView()
        let mapProvider = self.providerFor(baseMap)
        
        if(self.enableLiveLocationSharingView){
            initLiveLocationView(mapView: self.mapView, mapProvider: mapProvider)
        }else{
            initHTView(mapView: mapView,mapProvider:mapProvider)
        }
        self.view?.zoomMapTo(visibleRegion: initialRegion, animated: true)
        self.view?.mapProvider?.mapInteractionDelegate = self
        self.view?.mapProvider?.mapViewDataSource = self.mapViewDataSource
        self.view?.mapViewDataSource = self.mapViewDataSource
    }
    
    /**
     Method to set the customization delegate
     
     - Parameter customizationDelegate: Object conforming to HTViewCustomizationDelegate
     */
    public func setHTViewCustomizationDelegate(customizationDelegate: HTViewCustomizationDelegate) {
        self.customizationDelegate = customizationDelegate
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
            self.view?.removeFromSuperview()
        } else {
            HTLogger.shared.error("Failed::Tried to remove mapview from a view that it is not a child of.")
        }
    }
    
    public func resetViews(){
        self.view?.clearMap()
        self.lastPlottedTime = Date.distantPast
        self.mapViewDataSource.clearAllMapViewModels()
        self.view?.clearView()
        self.view = nil
    }
    
    /**
     Method to remove actions from the map
     */
    public func removeActions(_ actionIds: [String]? = nil) {
        // Clear action, which would clear the marker and
        // HTView UI elements
        self.view?.clearMap()
        self.lastPlottedTime = Date.distantPast
        self.mapViewDataSource.clearAllMapViewModels()
        HTConsumerClient.sharedInstance.removeActions(actionIds)
        self.view?.clearView()
        self.view = nil
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
    
        HTConsumerClient.sharedInstance.trackActionFor(lookUpId: lookUpId, delegate: self) { (
            actions, error) in
            if let _ = error {
                
            }else{
                
                if let currentUserId = HyperTrack.getUserId(){
                    if let actions = HTConsumerClient.sharedInstance.getActions(userId: currentUserId){
                        if let action = actions.last {
                            if let place = action.expectedPlace {
                                NotificationCenter.default.addObserver(self,
                                                                       selector: #selector(self.didEnteredMonitorRegion(notification:)),
                                                                       name: NSNotification.Name(rawValue: HTConstants.HTMonitoredRegionEntered), object: nil)
                                NotificationCenter.default.addObserver(self,
                                                                       selector: #selector(self.didEnteredMonitorRegion(notification:)),
                                                                       name: NSNotification.Name(rawValue: HTConstants.HTMonitoredRegionExited), object: nil)
                                
                                Transmitter.sharedInstance.locationManager.startMonitorForPlace(place: place)
                                
                            }
                        }
                    }
                }                
            }
        }
        
        HTConsumerClient.sharedInstance.trackActionFor(lookUpId: lookUpId, delegate: self, completionHandler: completionHandler)
    }
    
    func didEnteredMonitorRegion(notification : Notification){
        if let currentUserId = HyperTrack.getUserId(){
            if let actions = HTConsumerClient.sharedInstance.getActions(userId: currentUserId){
                if let action = actions.last {
                    if let place = action.expectedPlace {
                        if let region = notification.userInfo?["region"] as? CLRegion{
                            if(place.getIdentifier() == region.identifier){
                                HTConsumerClient.sharedInstance.eventDelegate?.didEnterMonitoredDestinationRegionForAction?(forAction: action)
                                NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: HTConstants.HTMonitoredRegionEntered), object: nil)
                                NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: HTConstants.HTMonitoredRegionExited), object: nil)
                            }
                        }
                    }
                }
            }
        }
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
            self.view?.reloadCarousel()
        }
    }
    
    func onUpdateUser(userId : String){
        let trackedUser = HTConsumerClient.sharedInstance.getUser(userId:userId)
        let actionIds = HTConsumerClient.sharedInstance.getActionIds(userId: userId)
        onUpdateAllActions(userId: userId, actions: actionIds!)
        
        // Process time aware polyline for updating hero marker
        self.view?.processTimeAwarePolyline(userId: (trackedUser?.expandedUser?.id)!,
                                            timeAwarePolyline: trackedUser?.expandedUser?.timeAwarePolyline,disableHeroMarkerRotation: shouldDisableHeroMarkerRotation(userId: userId))
        
    }
    
    func shouldDisableHeroMarkerRotation(userId : String) -> Bool {
        let user = HTConsumerClient.sharedInstance.getUser(userId: userId)
        if  let action = user?.actions?.last as? HyperTrackAction {
            if let disableHeroMarkerRotation =
                self.customizationDelegate?.disableHeroMarkerRotationForActionID?(
                    map: self, actionID: action.id!){
                return disableHeroMarkerRotation
            }
        }
        
        return false
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
        resetPhoneButton()
        // Reset view focus
        self.view?.updateViewFocus(isInfoViewCardExpanded: self.view.isCardExpanded,
                                   isDestinationViewVisible: !(self.view.destinationView.isHidden))
    }
    
    @objc public func confirmLocation() -> HyperTrackPlace?{
        return self.view?.confirmLocation()
    }
    
    func isCurrentUser(userId : String?) -> Bool{
        if let userId = userId {
            if let currentUserId = Settings.getUserId() {
                if(currentUserId == userId){
                    return true
                }
            }
        }
        return false
    }
    
    func resetUserInfo(_ actionIdToBeUpdated: String?){
        var actionId = actionIdToBeUpdated
        if (actionId == nil) {
            actionId = HTConsumerClient.sharedInstance.getActionIds().last
        }
        
        let action: HyperTrackAction = HTConsumerClient.sharedInstance.getAction(actionId: actionId!)!
        
        let statusInfo = HTStatusCardInfo.getUserInfo(action, action.user?.id , useCase: self.useCase, isCurrentUser: isCurrentUser(userId: action.user?.id))
        
        if let isInfoViewShown = self.customizationDelegate?.showInfoViewForActionID?(map: self, actionID: action.id!) {
            self.isInfoViewShown = isInfoViewShown
            statusInfo.isInfoViewShown = isInfoViewShown
        }
        
        
        self.view?.updateInfoView(statusInfo: statusInfo)
        // Expanded card
        if (statusInfo.showActionPolylineSummary) {
            self.view?.clearMap()
            if let encodedPolyline = action.encodedPolyline {
                if(customizationDelegate != nil){
                    if let image = customizationDelegate?.startMarkerImageForActionID?(map: self, actionID: action.id!){
                        self.view?.updatePolyline(polyline: encodedPolyline,startMarkerImage:image)
                    }else{
                        self.view?.updatePolyline(polyline: encodedPolyline)
                    }
                    
                }else{
                    self.view?.updatePolyline(polyline: encodedPolyline)
                    
                }
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
            actionId = HTConsumerClient.sharedInstance.getActionIds().last
        }
        
        let action: HyperTrackAction = HTConsumerClient.sharedInstance.getAction(actionId: actionId!)!
        
        var destinationAddress: String = ""
        if let place = action.expectedPlace {
            destinationAddress = place.address!
        } else {
            // Hide address view if expected place is not available
            self.view?.updateAddressView(isAddressViewShown: false,
                                         destinationAddress: destinationAddress,action:action)
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
        
        self.view?.updateAddressView(isAddressViewShown: self.isAddressViewShown,
                                     destinationAddress: destinationAddress,action:action)
    }
    
    func resetDestinationMarker(_ actionIdToBeUpdated: String?) {
        var actionId = actionIdToBeUpdated
        if (actionId == nil) {
            actionId = HTConsumerClient.sharedInstance.getActionIds().last
        }
        self.view?.resetDestinationMarker(actionId,showExpectedPlacelocation: shouldShowDestinationMarker(actionID:actionId!))
    }
    
    func shouldShowDestinationMarker(actionID  : String) -> Bool{
        if let isDestinationMarkerShown = self.customizationDelegate?.showExpectedPlaceMarker?(map: self, actionID: actionID)  {
            return isDestinationMarkerShown
        }
        return true
    }
    
    func resetReFocusButton() {
        
        if let isRefocusButtonShown = self.customizationDelegate?.showReFocusButton?(map: self) {
            self.showReFocusButton = isRefocusButtonShown
        }

        // Check if ReFocus Button has been customized and update accordingly
        self.view?.updateReFocusButton(isRefocusButtonShown: self.showReFocusButton)
    }
    
    func resetBackButton() {
        
        if let isBackButtonShown = self.customizationDelegate?.showBackButton?(map: self) {
            self.showBackButton = isBackButtonShown
        }

        // Check if Back Button has been customized and update accordingly
        self.view?.updateBackButton(isBackButtonShown: self.showBackButton)
    }
    
}


extension HTMap:HTConsumerClientDelegate{
    
    public func onUserListUpdated() {
        self.onUpdateAllUsers()
    }
    
    public func onUserListChanged(){
        self.onUpdateAllUsers()
    }
    
    public func onActionStatusChanged(actionIds:[String],actions:[HyperTrackAction]){
        
    }
    
    func resetPhoneButton() {
        // Check if Phome Button has been customized and update accordingly
        if let shouldShowPhoneButton = self.customizationDelegate?.showCallButton?(map: self) {
            self.view?.updatePhoneButton(isPhoneShown: shouldShowPhoneButton)
        }
        else{
            self.view?.updatePhoneButton(isPhoneShown: true)
        }
    }
    
    
    public func onActionStatusRefreshed(actionIds:[String],actions:[HyperTrackAction]){
        
    }
    
    public func onActionsRemoved() {
        
    }
    
}

extension HTMap : HTViewCustomizationInternalDelegate{
    
    func heroMarkerImageForActionID( actionID: String) -> UIImage?{
        return self.customizationDelegate?.heroMarkerImageForActionID?(map: self, actionID: actionID)
    }
   
    func heroMarkerViewForActionID(actionID: String) -> MKAnnotationView?{
        return self.customizationDelegate?.heroMarkerViewForActionID?(map: self, actionID: actionID)
    }
  
    func disableHeroMarkerRotationForActionID( actionID: String) -> Bool{
      
        if let disableHeroMarkerRotation =
            self.customizationDelegate?.disableHeroMarkerRotationForActionID?(
                map: self, actionID: actionID){
            return disableHeroMarkerRotation
        }
        return false
    }
    
    
    func showStartMarker( actionID: String) -> Bool{
        if let showStartMarker =
            self.customizationDelegate?.showStartMarker?(
                map: self, actionID: actionID){
            return showStartMarker
        }
        return true
    }
    
    
    func startMarkerImageForActionID( actionID: String) -> UIImage?{
        return self.customizationDelegate?.startMarkerImageForActionID?(map: self, actionID: actionID)

    }
    func startMarkerViewForActionID( actionID: String) -> MKAnnotationView?{
        return self.customizationDelegate?.startMarkerViewForActionID?(map: self, actionID: actionID)

    }
   
    func showExpectedPlaceMarker( actionID: String) -> Bool{
        if let showExpectedPlaceMarker =
            self.customizationDelegate?.showExpectedPlaceMarker?(
                map: self, actionID: actionID){
            return showExpectedPlaceMarker
        }
        return true
    }
    
    func expectedPlaceMarkerImageForActionID( actionID: String) -> UIImage?{
        return self.customizationDelegate?.expectedPlaceMarkerImageForActionID?(map: self, actionID: actionID)

    }
    func expectedPlaceMarkerViewForActionID( actionID: String) -> MKAnnotationView?{
        return self.customizationDelegate?.expectedPlaceMarkerViewForActionID?(map: self, actionID: actionID)

    }
    func showAddressViewForActionID( actionID: String) -> Bool{
        if let showAddressViewForActionID =
            self.customizationDelegate?.showAddressViewForActionID?(
                map: self, actionID: actionID){
            return showAddressViewForActionID
        }
        return true

    }
    func showInfoViewForActionID( actionID: String) -> Bool{
        if let showInfoViewForActionID =
            self.customizationDelegate?.showInfoViewForActionID?(
                map: self, actionID: actionID){
            return showInfoViewForActionID
        }
        return true

    }
    func showCallButtonInInfoViewForActionID( actionID: String) -> Bool{
        if let showCallButtonInInfoViewForActionID =
            self.customizationDelegate?.showCallButtonInInfoViewForActionID?(
                map: self, actionID: actionID){
            return showCallButtonInInfoViewForActionID
        }
        return true
 
    }
    func showActionSummaryOnCompletion(actionID: String) -> Bool{
        if let showActionSummaryOnCompletion =
            self.customizationDelegate?.showActionSummaryOnCompletion?(
                map: self, actionID: actionID){
            return showActionSummaryOnCompletion
        }
        return true

    }

}


extension HTMap: HTViewInteractionInternalDelegate{
    
    internal func didTapReFocusButton(_ sender: Any) {
        self.view?.reFocusMap(isInfoViewCardExpanded: (self.view?.isCardExpanded)!,
                              isDestinationViewVisible: !(self.view?.destinationView.isHidden)!)
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
    
    internal func didTapJoinLiveLocationSharing(action : HyperTrackAction? ){
        self.interactionDelegate?.didTapJoinLiveLocationSharing?(action: action!)
        
    }
    
    internal func didTapStartLiveLocationSharing(place : HyperTrackPlace){
        self.interactionDelegate?.didTapStartLiveLocationSharing?(place: place)
    }
    
    internal func didPanMapView() {
        self.interactionDelegate?.didPanMapView?()
    }
    
    func didTapStopLiveLocationSharing(actionId : String){
        self.interactionDelegate?.didTapStopLiveLocationSharing?(actionId: actionId)
    }
    
    func didTapShareLiveLocationLink(action : HyperTrackAction){
        self.interactionDelegate?.didTapShareLiveLocationLink?(action: action)
    }
    
    func didSelectLocation(place : HyperTrackPlace?){
        self.interactionDelegate?.didSelectLocation?(place: place)
    }
    
    func willChooseLocationOnMap(){
        self.interactionDelegate?.willChooseLocationOnMap?()
    }
    
    
}

