//
//  HTCommonView.swift
//  Pods
//
//  Created by Ravi Jain on 7/24/17.
//
//

import UIKit
import MapKit

class HTCommonView: UIView {

    @IBOutlet weak var mapView: UIView!
    @IBOutlet weak var reFocusButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var destinationView: UIView!

    weak var interactionViewDelegate: HTViewInteractionInternalDelegate?
    weak var customizationDelegate: HTViewCustomizationInternalDelegate?

    var isLiveLocationSharingEnabled = false
    var isDestinationMarkerShown: Bool = true

    var mapProvider: MapProviderProtocol?
    var isCardExpanded = false
    var mapViewDataSource: HTMapViewDataSource?
    var useCase = HTConstants.UseCases.TYPE_SINGLE_USER_SINGLE_ACTION

    var lastPlottedTimeMap = [String:Date]()
    var showConfirmLocationButton = false
    
    
    public func enableLiveLocationSharing(){

    }
    
    func zoomMapTo(visibleRegion: MKCoordinateRegion, animated: Bool){
        
    }

    
    func clearView() {
    
    
    }
    
    func reloadCarousel(){
        

    }
    
    func updateInfoView(statusInfo : HTStatusCardInfo){

    }
    
    func updateAddressView(isAddressViewShown: Bool, destinationAddress: String? ,action:HyperTrackAction) {

    }
    
    func updateReFocusButton(isRefocusButtonShown: Bool) {
    }
    
    func updateBackButton(isBackButtonShown: Bool) {

    }
    
    func updateViewFocus(isInfoViewCardExpanded: Bool, isDestinationViewVisible: Bool){
        
    }
    
    func clearMap(){
        self.mapProvider?.clearMap()
    }
    
    func updatePolyline(polyline: String){
        
    }
    
    func updatePolyline(polyline: String,startMarkerImage:UIImage?){

    }
    
    func updateDestinationMarker(showDestination: Bool, destinationAnnotation: HTMapAnnotation?){
        
        
    }
    
    func updateHeroMarker(userId: String, actionID: String, heroAnnotation: HTMapAnnotation, disableHeroMarkerRotation: Bool){
        
    }
    
    func animateMarker(userId: String, locations: [CLLocationCoordinate2D], currentIndex: Int, duration: TimeInterval, disableHeroMarkerRotation: Bool){
       
    }
    
    func reFocusMap(isInfoViewCardExpanded: Bool, isDestinationViewVisible: Bool){
        
    }
   
    func updatePhoneButton(isPhoneShown: Bool) {
               
    }
    
    func confirmLocation()-> HyperTrackPlace?{
        return nil
    }
    
     func processTimeAwarePolyline(userId : String, timeAwarePolyline:String?,disableHeroMarkerRotation:Bool){
        // Decode updated TimeAwarePolyine
        var deocodedLocations: [TimedCoordinates] = []
        if (timeAwarePolyline != nil) {
            if let timedCoordinates = timedCoordinatesFrom(polyline: timeAwarePolyline!) {
                deocodedLocations = timedCoordinates
            }
        }
        
        if (self.lastPlottedTimeMap[userId] == nil){
            self.lastPlottedTimeMap[userId]  = Date.distantPast
        }
        
        let lastPlottedTime = self.lastPlottedTimeMap[userId]
        // Get new locations from decodedLocations
        let newLocations = deocodedLocations.filter{$0.timeStamp > lastPlottedTime!}
        var coordinates = newLocations.map{$0.location}
        
        // MARK TODO- temporary check
        if coordinates.count > 50 {
            coordinates = Array(coordinates.suffix(from: coordinates.count - 50))
        }
        
        self.setUpHeroMarker(userId: userId, coordinates: coordinates,disableHeroMarkerRotation:disableHeroMarkerRotation)
        
        // Update lastPlottedTime to reflect latest animated point
        if let lastPoint = newLocations.last {
            self.lastPlottedTimeMap[userId]  = lastPoint.timeStamp
        }
    }
    
    
    func setUpHeroMarker(userId: String, coordinates: [CLLocationCoordinate2D],disableHeroMarkerRotation:Bool) {
        
        let user = HTConsumerClient.sharedInstance.getUser(userId: userId)
        if let  action = user?.actions?.last as? HyperTrackAction {
            
            // Check if action has been completed for order tracking use-case
            if (self.useCase == HTConstants.UseCases.TYPE_SINGLE_USER_SINGLE_ACTION), (action.display != nil), (action.display?.showSummary == true) {
                return
            }
            
            var heroAnnotation = self.mapViewDataSource?.getMapViewModel(userId: userId)?.heroMarker
            if (heroAnnotation == nil) {
                heroAnnotation = HTMapAnnotation()
                heroAnnotation?.action = action
                heroAnnotation!.type = HTConstants.MarkerType.HERO_MARKER
                heroAnnotation!.disableRotation = disableHeroMarkerRotation
                if let coordinate = coordinates.first as CLLocationCoordinate2D? {
                    heroAnnotation!.coordinate = coordinate
                }
                
                self.mapProvider?.addMarker(heroAnnotation: heroAnnotation!)
                
            }
            
            heroAnnotation!.subtitle = getSubtitleDisplayText(action: action)?.capitalized
            self.mapViewDataSource?.setHeroMarker(userId: userId,
                                                  annotation: heroAnnotation)
            
            // TODO - Update eta on hero marker for LLS use-case
            let unitAnimationDuration = 5.0 / Double(coordinates.count)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.animateMarker(userId: userId, locations: coordinates, currentIndex: 0, duration: unitAnimationDuration, disableHeroMarkerRotation: heroAnnotation!.disableRotation)
            }
        }
        
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
    

    func resetDestinationMarker(_ actionIdToBeUpdated: String?, showExpectedPlacelocation:Bool) {
        var actionId = actionIdToBeUpdated
        if (actionId == nil) {
            actionId = HTConsumerClient.sharedInstance.getActionIds().last
        }
        
        let action: HyperTrackAction = HTConsumerClient.sharedInstance.getAction(actionId: actionId!)!
        
        // Check if action has been completed for order tracking use-case
        if (self.useCase == HTConstants.UseCases.TYPE_SINGLE_USER_SINGLE_ACTION), (action.display != nil), (action.display?.showSummary == true) {
            return
        }
        
        if let expectedPlaceCoordinates = HTConsumerClient.sharedInstance.getExpectedPlaceLocation(actionId: action.id!) {
            
            // Handle destinationMarker customization
            self.isDestinationMarkerShown = showExpectedPlacelocation
            
            // Get annotation for destinationMarker
            let destinationAnnotation = HTMapAnnotation()
            destinationAnnotation.coordinate = expectedPlaceCoordinates
            destinationAnnotation.title = HTGenericUtils.getPlaceName(place: action.expectedPlace)
            destinationAnnotation.type = HTConstants.MarkerType.DESTINATION_MARKER
            destinationAnnotation.action = action
            
            self.updateDestinationMarker(showDestination: self.isDestinationMarkerShown, destinationAnnotation: destinationAnnotation)
            
        } else{
            self.updateDestinationMarker(showDestination: false, destinationAnnotation: nil)
        }
    }


    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
