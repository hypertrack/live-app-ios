    //
//  HTLiveLocationView.swift
//  Pods
//
//  Created by Ravi Jain on 7/24/17.
//
//

import UIKit
import MapKit

enum LiveLocationViewState: Int {
    case LOCATION_SEARCH = 0
    case LOCATION_CONFIRM = 1
    case LOCATION_SELECTED = 2
    case TRACKING_STARTED = 3
    case TRACKING_COMPLETED = 4
}


protocol StatusViewDelegate {
    func willExpand(view: UIView)
    func didExpand(view: UIView )
    func willShrink(view : UIView)
    func didShrink(view : UIView)
}

class HTLiveLocationView: HTCommonView {
    
    
    // search table view
    @IBOutlet weak var searchText: UITextField!
    @IBOutlet weak var searchActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var searchResultTableView: UITableView!
    @IBOutlet weak var infoView: UITextView!
    
    
    @IBOutlet weak var liveLocationView: UIView!
    
    //  confirm view
    @IBOutlet weak var optionsView: UIView!
    
    @IBOutlet weak var stopTrackingButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var fullStopTrackingButton: UIButton!
    
    @IBOutlet weak var refocusButton: UIButton!
    @IBOutlet weak var refocusHeightConstraint: NSLayoutConstraint!
    
    var statusCard : HTStatusCardView? = nil
    var pinnedImageView : UIImageView? = nil
    
    var searchResults : [HyperTrackPlace]? = []
    var selectedLocation : HyperTrackPlace?
    var isShowingSearchResults = false
    var destinationAnnotation : HTMapAnnotation? = nil
    var currentUserAnnotation : HTMapAnnotation? = nil
    
    @IBOutlet weak var confirmButton: UIButton!
    var shouldStartTrackingRegion  = false
    
    var isShowingSavedResults = true
    var didAddedStatusView = false
    
    var lastPosition: CLLocationCoordinate2D?
    var currentHeading: CLLocationDegrees = 0.0
    var multiUserStatusCards = [HTLiveMultiStatusCard]()
    var currentViewState = LiveLocationViewState.LOCATION_SEARCH
    {
        didSet{
            onStateChange(currentState: currentViewState, fromState: oldValue)
        }
    }
    
    var didUserStartPanning = false
    var tripSummaryCard : TripSummaryView? = nil
    var tripSummarySuperView : UIView? = nil
    var expandedCard : ExpandedCard? = nil
    var completedView : CompletedView?
    var haveShownInitialMarkers = false
    var lastUserLocation : CLLocationCoordinate2D?
    
    func initMapView(mapSubView: MKMapView, interactionViewDelegate: HTViewInteractionInternalDelegate) {
        
        self.interactionViewDelegate = interactionViewDelegate
        self.liveLocationView.addSubview(mapSubView)
        self.liveLocationView.sendSubview(toBack: mapSubView)
        self.mapView = mapSubView
        self.refocusButton.isHidden = true
        if HTConsumerClient.sharedInstance.getLookUpId() != nil {
            currentViewState = LiveLocationViewState.TRACKING_STARTED
        }
        
        self.setUpSearchResultTableView()
        self.setUpNotifications()
        self.setUpPinnedImageView()
        self.setUpMapView()
        
        self.optionsView.isHidden = true
        self.infoView.isHidden =   ((self.getSavedPlaces()?.count)! > 0 )
        self.fullStopTrackingButton.shadow()
        if(currentViewState == LiveLocationViewState.TRACKING_STARTED) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.setUpAnnotations()
                let userIds = HTConsumerClient.sharedInstance.getUserIds()
                if (userIds.count > 0){
                    if let actions = HTConsumerClient.sharedInstance.getActions(userId: userIds.first!){
                        self.onStartTracking(action: actions.last!,userIds: userIds)
                    }
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.haveShownInitialMarkers = true
            }
            
        }else{
            haveShownInitialMarkers = true
        }
    }
    
    func setUpSearchResultTableView(){
        self.searchText.delegate = self
        self.destinationView.layer.cornerRadius = self.searchText.frame.width/10.0
        self.destinationView.layer.masksToBounds = true
        self.searchText.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        self.searchResultTableView.delegate = self
        self.searchResultTableView.dataSource = self
        self.searchResultTableView.backgroundColor = UIColor.clear
        
        self.searchResultTableView.register(UINib(nibName: "SearchCellView", bundle: Settings.getBundle()), forCellReuseIdentifier: "SearchCell")
        self.searchResultTableView.isHidden = false
        
        if(currentViewState != LiveLocationViewState.LOCATION_SEARCH){
            self.searchResultTableView.isHidden = true
        }else{
            self.searchText.becomeFirstResponder()
        }
    }
    
    func setUpNotifications(){
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onLocationUpdate(notification:)),
                                               name: NSNotification.Name(rawValue: HTConstants.HTLocationChangeNotification), object: nil)
        
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onHeadingUpdate(notification:)),
                                               name: NSNotification.Name(rawValue: HTConstants.HTLocationHeadingChangeNotification), object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onBackgroundNotification(notification:)),
                                               name: Notification.Name.UIApplicationWillResignActive, object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onActiveNotification(notification:)),
                                               name: Notification.Name.UIApplicationDidBecomeActive, object: nil)
    }
    
    func setUpPinnedImageView(){
        let image = UIImage.init(named: "square", in: Settings.getBundle(), compatibleWith: nil)
        self.pinnedImageView = UIImageView.init(image: image, highlightedImage: image)
        self.pinnedImageView?.frame = CGRect(x:0,y:0,width:29,height:29)
        self.pinnedImageView?.contentMode = UIViewContentMode.scaleAspectFit
    }
    
    func setUpMapView(){
        if(currentViewState == LiveLocationViewState.LOCATION_SEARCH){
            self.mapView.isHidden = true
        }else{
            self.mapView.isHidden = false
            
        }
        self.mapProvider?.mapCustomizationDelegate = self
    }
    
    @IBAction func onRefocusClicked(_ sender: Any) {
        if(currentViewState == LiveLocationViewState.TRACKING_STARTED){
            self.focusMarkers(force: true)
            self.interactionViewDelegate?.didTapReFocusButton?(self)
        }
        didUserStartPanning = false
    }
    
    @IBAction func onConfirmLocationButtonClick(_ sender: Any) {
        if self.selectedLocation != nil {
            didSelectedLocation(place: self.selectedLocation!,selectOnMap : false)
            self.confirmButton.isHidden = true
        }
        
    }
    func setUpAnnotations(){
        let userIds = HTConsumerClient.sharedInstance.getUserIds()
        if userIds.count > 0 {
            for userId in userIds {
                if let act = HTConsumerClient.sharedInstance.getUser(userId:userId)?.actions?.last {
                    resetDestinationMarker(act?.id, showExpectedPlacelocation: true)
                    let user = HTConsumerClient.sharedInstance.getUser(userId:userId)
                    self.processTimeAwarePolyline(userId: userId, timeAwarePolyline:user?.expandedUser?.timeAwarePolyline, disableHeroMarkerRotation: false)
                }
            }
        }
    }
    
    
    func onActiveNotification(notification : Notification){
        
        
    }
    
    func onBackgroundNotification(notification:Notification){
        
    }
    
    
    override func confirmLocation()-> HyperTrackPlace?{
        if let location = self.selectedLocation{
            didSelectedLocation(place: location, selectOnMap: false)
            
        }
        return self.selectedLocation
    }
    
    func updateLocation(){
        if(currentViewState == LiveLocationViewState.TRACKING_STARTED){
            if let userAnnotation = currentUserAnnotation {
                if let location = Transmitter.sharedInstance.locationManager.getLastKnownLocation(){
                    HTLogger.shared.info("updating user coordinate" + location.description)
                    if (lastUserLocation != nil){
                        UIView.animate(withDuration: 0.2, animations: {userAnnotation.coordinate = location.coordinate}, completion: { (finished) in
                            userAnnotation.location  = location
                            self.updateCourse(annotation: userAnnotation)
                            self.lastUserLocation = location.coordinate
                            userAnnotation.coordinate = location.coordinate
                            self.currentUserAnnotation =  userAnnotation
                        })
                    }else{
                        self.updateCourse(annotation: userAnnotation)
                        self.lastUserLocation = location.coordinate
                        userAnnotation.coordinate = location.coordinate
                        userAnnotation.location  = location
                        self.currentUserAnnotation =  userAnnotation
                        
                    }
                }
            }
            self.focusMarkers()
        }
    }
    
    func onLocationUpdate(notification : Notification){
        updateLocation()
    }
    
    func onHeadingUpdate(notification : Notification){
        if(currentViewState == LiveLocationViewState.TRACKING_STARTED){
            if let userAnnotation = currentUserAnnotation {
                if let location = Transmitter.sharedInstance.locationManager.getLastKnownLocation(){
                    userAnnotation.coordinate = location.coordinate
                    userAnnotation.location  = location
                    self.currentUserAnnotation = userAnnotation
                    self.updateCourse( annotation: userAnnotation)
                }
            }
        }
    }
    
    func onStopTrip(notification : Notification){
        currentViewState = LiveLocationViewState.LOCATION_SEARCH
        resetViewToStartSearch()
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: HTConstants.HTTrackingStopedForAction), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.UIApplicationDidBecomeActive, object: nil)
        
    }
    
    func onStateChange(currentState : LiveLocationViewState, fromState:LiveLocationViewState){
        self.confirmButton.isHidden = true
        
        if(currentViewState == LiveLocationViewState.TRACKING_STARTED){
            self.refocusButton.isHidden = false
        }else if (currentViewState == LiveLocationViewState.LOCATION_SEARCH){
            self.refocusButton.isHidden = true
            self.searchText.text = ""
            self.searchResults = []
            self.isShowingSearchResults = false
            self.searchResultTableView.reloadData()

        }
        else if (currentViewState == LiveLocationViewState.TRACKING_COMPLETED){
            self.refocusButton.isHidden = true
                  }
        
        if(currentViewState != LiveLocationViewState.TRACKING_STARTED){
            didUserStartPanning = false
        }
        
        if(currentViewState == LiveLocationViewState.LOCATION_CONFIRM){
            if(self.showConfirmLocationButton){
                self.confirmButton.isHidden = false
            }
        }
        
    }
    
    func updateCourse(annotation: HTMapAnnotation){
        if let mapView = self.mapView as? MKMapView {
            if let view = mapView.view(for: annotation) {
                if let markerView = view.subviews.first as? HTMarkerWithTitle {
                    let headingDirection = annotation.location?.course
                    HTLogger.shared.info("headingDirection " + (headingDirection?.description)!)
                    if(Double(headingDirection!) > 0){
                        let rotation = CGFloat(headingDirection!/180 * Double.pi)
                        markerView.markerImage.transform = CGAffineTransform(rotationAngle: rotation)
                    }
                    
                }
            }
        }
    }
    
    func degreesToRadian(degree : CLLocationDirection) -> Double {
        return Double(degree) * .pi / 180
    }
    
    func resetViewToStartSearch(){
        self.resetSearchView()
        self.resetStatusView()
        self.mapView.isHidden = true
        self.mapProvider?.removeAllAnnotations()
        self.mapProvider?.removeAllAnnotations()
        self.destinationAnnotation = nil
        self.currentUserAnnotation = nil
    }
    
    func resetSearchView(){
        self.searchResultTableView.reloadData()
        
        self.searchResultTableView.isHidden = false
        self.isShowingSearchResults = false
        self.shouldStartTrackingRegion = false
        self.searchText.isEnabled = true
        self.searchText.becomeFirstResponder()
    }
    
    func resetStatusView(){
        self.optionsView.isHidden = true
        if let statusCard = self.statusCard{
            statusCard.isHidden = true
            self.didAddedStatusView = false
            statusCard.removeFromSuperview()
        }
        
        if multiUserStatusCards.count > 0 {
            self.didAddedStatusView = false
            for statusCard in multiUserStatusCards{
                statusCard.removeFromSuperview()
            }
        }
    }
    
    func didSelectedLocation(place : HyperTrackPlace, selectOnMap:Bool){
        
        currentViewState = LiveLocationViewState.LOCATION_SELECTED
        self.resetStatusView()
        
        self.searchText.resignFirstResponder()
        self.searchResultTableView.isHidden = true
        isShowingSearchResults = false
        self.infoView.isHidden = true
        self.mapView.isHidden = false
        //self.confirmLocationView.isHidden = false
        
        self.selectedLocation = place
        self.searchText.text = HTGenericUtils.getPlaceName(place: place)
        self.shouldStartTrackingRegion = false
        
        if self.destinationAnnotation != nil {
            self.mapProvider?.removeMarker(heroAnnotation: self.destinationAnnotation!)
        }
        
        let mapAnnotation = HTMapAnnotation()
        mapAnnotation.coordinate = CLLocationCoordinate2DMake((selectedLocation?.location?.coordinates.last)! , (selectedLocation?.location?.coordinates.first)!)
        mapAnnotation.title = HTGenericUtils.getPlaceName(place: place)
        mapAnnotation.type = HTConstants.MarkerType.DESTINATION_MARKER
        mapProvider?.addMarker(heroAnnotation: mapAnnotation)
        self.destinationAnnotation = mapAnnotation
        
        if(!selectOnMap){
            
            self.interactionViewDelegate?.didSelectLocation?(place: place)
            
            if let location = Transmitter.sharedInstance.locationManager.getLastKnownLocation(){
                let currentLocationAnnotation = HTMapAnnotation()
                currentLocationAnnotation.title = "You"
                currentLocationAnnotation.coordinate = location.coordinate
                currentLocationAnnotation.location = location
                currentLocationAnnotation.type = HTConstants.MarkerType.HERO_MARKER
                currentLocationAnnotation.image =  UIImage.init(named: "purpleArrow", in:  Settings.getBundle(), compatibleWith: nil)
                mapProvider?.addMarker(heroAnnotation: currentLocationAnnotation)
                self.focusMarkers()
                self.currentUserAnnotation = currentLocationAnnotation
            }else{
                let region = MKCoordinateRegionMake(mapAnnotation.coordinate,MKCoordinateSpanMake(0.005, 0.005))
                mapProvider?.zoomTo(visibleRegion: region, animated: true)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { // in half a second...
                self.shouldStartTrackingRegion = true
            }
        }else{
            self.interactionViewDelegate?.willChooseLocationOnMap?()
            let region = MKCoordinateRegionMake(mapAnnotation.coordinate,MKCoordinateSpanMake(0.01, 0.01))
            mapProvider?.zoomTo(visibleRegion: region, animated: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { // in half a second...
                self.shouldStartTrackingRegion = true
            }
        }
    }
    
    func reloadSearchTableView(){
        self.searchResultTableView.reloadData()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { // in half a second...
            
        }
    }
    
    func focusMarkers(force : Bool = false){
        if(!self.didUserStartPanning || force){
            let mapEdgePadding = UIEdgeInsets(top: 120, left: 50, bottom: 240, right: 50)
            mapProvider?.focusAllMarkers(insets: mapEdgePadding)
        }
    }
    
    
    func didStartTracking(notification: NSNotification) {
        
    }
    
    func onStartTracking(action : HyperTrackAction , userIds : [String]){
        
        if (currentViewState == LiveLocationViewState.LOCATION_SELECTED){
            currentViewState = LiveLocationViewState.TRACKING_STARTED
        }
        
        self.didAddedStatusView = true
        self.destinationAnnotation?.action = action
        self.addLiveStatusCard(action: action,userIds: userIds)
        shouldStartTrackingRegion = false
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: HTConstants.HTTrackingStartedForLookUpId), object: nil)
        
        if let place = self.selectedLocation{
            Settings.addPlaceToSavedPlaces(place:place)
        }
    }
    
    func canShareTracking(userIds : [String]) -> Bool{
        if(userIds.count == 1){
            if(HTGenericUtils.isCurrentUser(userId: userIds.first)){
                return true
            }
        }
        return false
    }
    
    func canStopTracking(userIds : [String]) -> Bool{
        for userId in userIds {
            if(HTGenericUtils.isCurrentUser(userId:userId)){
                return true
            }
        }
        return false
    }
    
    func isTripCompleted(userIds : [String]) -> Bool{
        var isTripFinished = true
        for userId in userIds {
            let user = HTConsumerClient.sharedInstance.getUser(userId: userId)
            if let  action = user?.actions?.last {
                let statusInfo = HTStatusCardInfo.getUserInfo(action!,userId, useCase: HTConstants.UseCases.TYPE_SINGLE_USER_SINGLE_ACTION, isCurrentUser: HTGenericUtils.isCurrentUser(userId: userId))
                if !statusInfo.showActionDetailSummary{
                    isTripFinished = false
                }
                
            }
        }
        return isTripFinished
    }
    
    func showTripSummary(action : HyperTrackAction,userIds : [String]){
      
        self.refocusButton.isHidden = true
        
        if(userIds.count == 1){
            if(self.statusCard == nil){
                if statusCard == nil {
                    loadStatusCard()
                }
            }
            
            let statusInfo = HTStatusCardInfo.getUserInfo(action, action.user?.id, useCase: HTConstants.UseCases.TYPE_SINGLE_USER_SINGLE_ACTION, isCurrentUser: HTGenericUtils.isCurrentUser(userId: action.user?.id))
            self.statusCard?.reloadWithUpdatedInfo(statusInfo)
            if(statusInfo.showActionPolylineSummary){
                self.clearMap()
                if let encodedPolyline = action.encodedPolyline {
                    let startImage =  UIImage.init(named: "pitchPink", in:  Settings.getBundle(), compatibleWith: nil)
                    
                    let destinationImage =  UIImage.init(named: "square", in:  Settings.getBundle(), compatibleWith: nil)
                    
                    self.mapProvider?.updatePolyline(polyline: encodedPolyline,startMarkerImage:startImage,destinationImage:destinationImage)
                }
            }
            
            focusMarkers(force: true)
            
        }else{
            showMultiTripSummary(action: action, userIds: userIds)
        }
        
        self.optionsView.isHidden = true
        HTConsumerClient.sharedInstance.eventDelegate?.didShowSummary?(forAction: action)
    }
    
    func loadStatusCard(){
        HTLogger.shared.info("loading status card")
        if (statusCard == nil){
            let bundle = Settings.getBundle()!
            let statusCard: HTStatusCardView = bundle.loadNibNamed("StatusCardView", owner: self, options: nil)?.first as! HTStatusCardView
            self.statusCard = statusCard
            self.statusCard?.statusDelegate = self
        }
       
        self.mapView.addSubview(self.statusCard!)
        self.statusCard?.isHidden = false
        self.statusCard?.frame = CGRect(x:20,y:self.mapView.frame.height - 80 - (self.statusCard?.frame.height)!, width : self.mapView.frame.width - 40,height : (self.statusCard?.frame.height)!)
        self.mapView.bringSubview(toFront: self.statusCard!)
    }
    
    
    func addLiveStatusCard(action : HyperTrackAction, userIds : [String]){
        if(currentViewState == LiveLocationViewState.TRACKING_STARTED) {
            if(isTripCompleted(userIds: userIds)){
                showTripSummary(action:action,userIds: userIds)
            }
            else{
                if(userIds.count == 1){
                    loadStatusCard()
                }
                else if (userIds.count >= 2){
                    if(self.statusCard != nil){
                        self.statusCard?.removeFromSuperview()
                    }
                    
                    let bundle = Settings.getBundle()!
                    let user1Card = bundle.loadNibNamed("LiveMultiStatus", owner: self, options: nil)?.first as? HTLiveMultiStatusCard
                    user1Card?.userId = userIds.first
                    user1Card?.statusDelegate = self
                    let user2Card = bundle.loadNibNamed("LiveMultiStatus", owner: self, options: nil)?.first as? HTLiveMultiStatusCard
                    user2Card?.userId = userIds.last
                    user2Card?.statusDelegate = self
                    user1Card?.frame = CGRect(x:0,y:0,width:self.mapView.frame.width * 0.45,height:((user1Card?.frame.height)!))
                    user2Card?.frame = CGRect(x:0,y:0,width:self.mapView.frame.width * 0.45,height:((user2Card?.frame.height)!))
                    
                    user1Card?.shadow()
                    user2Card?.shadow()
                    self.multiUserStatusCards = [user1Card!,user2Card!]
                    
                    self.mapView.addSubview(user1Card!)
                    user1Card?.frame = CGRect(x: 10, y: self.mapView.frame.height - 80 - (user1Card?.frame.height)! , width: (user1Card?.frame.width)!, height: ((user1Card?.frame.height)!))
                    self.mapView.addSubview(user2Card!)
                    
                    user2Card?.frame = CGRect(x: self.mapView.frame.width - (user2Card?.frame.width)! - 10, y: self.mapView.frame.height - 80 - (user2Card?.frame.height)! , width: (user2Card?.frame.width)!, height: ((user2Card?.frame.height)!))
                    
                }
                
                self.updateStatusCard(action: action,userIds: userIds)
                
                if (self.canStopTracking(userIds: userIds) && self.canShareTracking(userIds: userIds)){
                    self.optionsView.isHidden = false
                    self.fullStopTrackingButton.isHidden = true
                    self.stopTrackingButton.isHidden = false
                    self.shareButton.isHidden = false
                }else if (!self.canShareTracking(userIds: userIds) && self.canStopTracking(userIds: userIds)){
                    self.optionsView.isHidden = false
                    self.fullStopTrackingButton.isHidden = false
                    self.stopTrackingButton.isHidden = true
                    self.shareButton.isHidden = true
                    
                }else{
                    self.optionsView.isHidden = true
                    
                }
                
            }
        }
    }
    
    
    
    
    func getUserCardFor(userId : String) -> HTLiveMultiStatusCard? {
        for card in self.multiUserStatusCards {
            if(card.userId == userId ){
                return card
            }
        }
        
        return nil
    }
    
    func updateStatusCard(action : HyperTrackAction, userIds:[String]){
        
        if(isTripCompleted(userIds: userIds)){
            currentViewState = LiveLocationViewState.TRACKING_COMPLETED
            showTripSummary(action:action,userIds: userIds)
        }else{
            if(userIds.count == 1){
                if(self.statusCard == nil){
                    if let actions = HTConsumerClient.sharedInstance.getActions(userId: userIds.first!){
                        addLiveStatusCard(action: actions.last!, userIds: userIds)
                    }
                }
                
                let statusInfo = HTStatusCardInfo.getUserInfo(action, action.user?.id, useCase: HTConstants.UseCases.TYPE_SINGLE_USER_SINGLE_ACTION, isCurrentUser: HTGenericUtils.isCurrentUser(userId: action.user?.id))
                self.statusCard?.reloadWithUpdatedInfo(statusInfo)
                
            }else if (userIds.count >= 2){
                
                if (self.multiUserStatusCards.count != 2){
                    if let actions = HTConsumerClient.sharedInstance.getActions(userId: userIds.first!){
                        addLiveStatusCard(action: actions.last!, userIds: userIds)
                    }
                    
                }
                
                for userId in userIds {
                    
                    let user = HTConsumerClient.sharedInstance.getUser(userId: userId)
                    if let  action = user?.actions?.last {
                        let statusInfo = HTStatusCardInfo.getUserInfo(action!,userId, useCase: HTConstants.UseCases.TYPE_SINGLE_USER_SINGLE_ACTION, isCurrentUser: HTGenericUtils.isCurrentUser(userId: userId))
                        if let userCard = self.getUserCardFor(userId: userId){
                            userCard.updateView(statusInfo: statusInfo)
                        }
                    }
                }
            }
        }
    }
    
    
    func showMultiTripSummary(action : HyperTrackAction,userIds: [String]){
        if(self.tripSummaryCard == nil){
            
            let bundle = Settings.getBundle()!
            self.tripSummaryCard = bundle.loadNibNamed("TripSummaryView", owner: self, options: nil)?.first as? TripSummaryView
            self.tripSummaryCard?.delegate = self
            self.tripSummaryCard?.action = action
            var index = 0
            for userId in userIds {
                let user = HTConsumerClient.sharedInstance.getUser(userId: userId)
                if let  action = user?.actions?.last {
                    let statusInfo = HTStatusCardInfo.getUserInfo(action!,userId, useCase: HTConstants.UseCases.TYPE_SINGLE_USER_SINGLE_ACTION, isCurrentUser: HTGenericUtils.isCurrentUser(userId: userId))
                    tripSummaryCard?.updateSection(statusInfo:statusInfo,index: index)
                    index = index + 1
                }
                
                if let userCard = self.getUserCardFor(userId: userId){
                    userCard.isHidden = true
                }
            }
            if(self.tripSummarySuperView == nil){
                self.tripSummarySuperView = UIView.init(frame: self.mapView.frame)
                self.tripSummarySuperView?.backgroundColor = UIColor.black
                self.tripSummarySuperView?.alpha = 0.7
            }
            
            self.mapView.addSubview(self.tripSummarySuperView!)
            self.mapView.addSubview(self.tripSummaryCard!)
            
        }
        self.tripSummaryCard?.frame = CGRect(x:0, y:0, width:self.mapView.frame.size.width * 0.8, height:self.mapView.frame.size.height * 0.8)
        self.tripSummaryCard?.center = self.mapView.center
        self.destinationView.isHidden = true
    }
    

    override func processTimeAwarePolyline(userId : String, timeAwarePolyline:String?,disableHeroMarkerRotation:Bool){
        if(HTGenericUtils.isCurrentUser(userId: userId)){
            if( currentUserAnnotation == nil){
                if let location = Transmitter.sharedInstance.locationManager.getLastKnownLocation(){
                    let currentLocationAnnotation = HTMapAnnotation()
                    currentLocationAnnotation.title = "You"
                    currentLocationAnnotation.coordinate = location.coordinate
                    currentLocationAnnotation.location = location
                    currentLocationAnnotation.type = HTConstants.MarkerType.HERO_MARKER
                    currentLocationAnnotation.image =  UIImage.init(named: "purpleArrow", in:  Settings.getBundle(), compatibleWith: nil)
                    let user = HTConsumerClient.sharedInstance.getUser(userId: userId)
                    if let  action = user?.actions?.last as? HyperTrackAction {
                        currentLocationAnnotation.action = action
                    }
                    mapProvider?.addMarker(heroAnnotation: currentLocationAnnotation)
                    self.currentUserAnnotation = currentLocationAnnotation
                }
            }
        }else{
            super.processTimeAwarePolyline(userId: userId, timeAwarePolyline: timeAwarePolyline, disableHeroMarkerRotation: disableHeroMarkerRotation)
        }
        focusMarkers()
    }
    
    override func resetDestinationMarker(_ actionIdToBeUpdated: String?, showExpectedPlacelocation:Bool) {
        
        if(currentViewState == LiveLocationViewState.TRACKING_STARTED){
            let action: HyperTrackAction = HTConsumerClient.sharedInstance.getAction(actionId: actionIdToBeUpdated!)!
            self.selectedLocation = action.expectedPlace
            var isAdded = true
            if(self.destinationAnnotation == nil){
                self.destinationAnnotation = HTMapAnnotation()
                isAdded = false
            }
            if let selectedLocation = self.selectedLocation{
                self.destinationAnnotation?.coordinate = CLLocationCoordinate2DMake((selectedLocation.location?.coordinates.last)! , (selectedLocation.location?.coordinates.first)!)
                self.destinationAnnotation?.title = HTGenericUtils.getPlaceName(place: action.expectedPlace)
                self.destinationAnnotation?.type = HTConstants.MarkerType.DESTINATION_MARKER
                self.destinationAnnotation?.action = action
                
                if(!isAdded){
                    self.mapProvider?.addMarker(heroAnnotation: self.destinationAnnotation!)
                }
            }
            
            self.searchText.text = HTGenericUtils.getPlaceName(place : action.expectedPlace)
        }
        
        focusMarkers()
    }
    
    override func setUpHeroMarker(userId: String, coordinates: [CLLocationCoordinate2D],disableHeroMarkerRotation:Bool) {
        
        if(currentViewState == LiveLocationViewState.TRACKING_STARTED){
            let user = HTConsumerClient.sharedInstance.getUser(userId: userId)
            
            if let  action = user?.actions?.last as? HyperTrackAction {
                
                // Check if action has been completed for order tracking use-case
                
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
                var animatedCordinates = [CLLocationCoordinate2D]()
                for coordinate in coordinates{
                    animatedCordinates.append(coordinate)
                }
                
                if (animatedCordinates.count > 20){
                    let animatedCordinatesSlice = animatedCordinates.suffix(from:coordinates.count - 20)
                    animatedCordinates = Array(animatedCordinatesSlice)
                }
                
                let unitAnimationDuration = 5.0 / Double(animatedCordinates.count)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.animateMarker(userId: userId, locations: animatedCordinates, currentIndex: 0, duration: unitAnimationDuration, disableHeroMarkerRotation: heroAnnotation!.disableRotation)
                }
            }
        }
    }
    
    override func animateMarker(userId: String,
                                locations: [CLLocationCoordinate2D],
                                currentIndex: Int, duration: TimeInterval,
                                disableHeroMarkerRotation: Bool) {
        
        let user = HTConsumerClient.sharedInstance.getUser(userId: userId)
        if let heroAnnotation = (self.mapViewDataSource?.getMapViewModel(userId: userId)?.heroMarker){
            let view = self.mapProvider?.getViewForMaker(annotation: heroAnnotation)
            if let view = view {
                
                // Update HeroMarker's title and subtitle
                if (heroAnnotation.type == HTConstants.MarkerType.HERO_MARKER_WITH_ETA) {
                    if let markerView = view.subviews.first as? MarkerView {
                        markerView.subtitleLabel .text = heroAnnotation.subtitle
                    }
                }
            }
            
            if let coordinates = locations as [CLLocationCoordinate2D]?, coordinates.count >= 1 {
                
                let currentLocation = coordinates[currentIndex]
                
                UIView.animate(withDuration: duration, animations: {heroAnnotation.coordinate = currentLocation}, completion: { (finished) in
                    if(currentIndex < coordinates.count - 1) {
                        
                        if let lastPosition = self.lastPosition {
                            self.currentHeading = HTMapUtils.headingFrom(lastPosition, next: currentLocation)
                        }
                        
                        self.lastPosition = currentLocation
                        
                        
                        if let markerView = view?.subviews.first as? HTMarkerWithTitle {
                            if (disableHeroMarkerRotation == false) {
                                if let adjustedHeading = user?.expandedUser?.lastLocation?.bearing {
                                    markerView.markerImage.transform = CGAffineTransform(rotationAngle: CGFloat(adjustedHeading * Double.pi / 180.0))
                                    self.currentHeading = adjustedHeading
                                }else if (coordinates.count > 1){
                                    if let markerView = view?.subviews.first as? HTMarkerWithTitle {
                                        if (disableHeroMarkerRotation == false) {
                                            if(self.currentHeading != 0){
                                                let adjustedHeading = (self.mapProvider?.getCameraHeading())! + self.currentHeading
                                                markerView.markerImage.transform = CGAffineTransform(rotationAngle: CGFloat(adjustedHeading * Double.pi / 180.0))
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        
                        self.mapViewDataSource?.setHeroMarker(userId: userId, annotation: heroAnnotation)
                        self.animateMarker(userId: userId,
                                           locations: coordinates,
                                           currentIndex: currentIndex + 1,
                                           duration: duration, disableHeroMarkerRotation: disableHeroMarkerRotation)
                    }
                })
            }else{
                if let markerView = view?.subviews.first as? HTMarkerWithTitle {
                    if (disableHeroMarkerRotation == false) {
                        if let adjustedHeading = user?.expandedUser?.lastLocation?.bearing {
                            markerView.markerImage.transform = CGAffineTransform(rotationAngle: CGFloat(adjustedHeading * Double.pi / 180.0))
                            self.currentHeading = adjustedHeading
                        }
                    }
                }
            }
            
            heroAnnotation.currentHeading = self.currentHeading
        }
    }
    
    
    
    override func reloadCarousel(){
        let userIds = HTConsumerClient.sharedInstance.getUserIds()
        if(!didAddedStatusView){
            if let actions = HTConsumerClient.sharedInstance.getActions(userId: userIds.first!){
                onStartTracking(action: actions.last!,userIds: userIds)
            }
        }
        
        if let action  = self.destinationAnnotation?.action {
            if let newAction = HTConsumerClient.sharedInstance.getActions(userId: (action.user?.id)!)?.last{
                self.destinationAnnotation?.action = newAction
                self.updateStatusCard(action: newAction,userIds: userIds)
            }
        }
    }
    
    func isCurrentUserSharingLocation() -> Bool {
        let userIds = HTConsumerClient.sharedInstance.getUserIds()
        let currentUserId = Settings.getUserId()
        if(userIds.count > 0){
            if let userId = currentUserId{
                if(userIds.contains(userId)){
                    return true
                }
            }
        }
        return false
    }
    
    
    @IBAction func stopTracking(_ sender: Any) {
        if (self.destinationAnnotation?.action) != nil {
            self.interactionViewDelegate?.didTapStopLiveLocationSharing?(actionId: (self.destinationAnnotation?.action?.id)!)
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(onStopTrip(notification:)),
                                                   name: NSNotification.Name(rawValue: HTConstants.HTTrackingStopedForAction), object: nil)
        }
    }
    
    @IBAction func shareLink(_ sender: Any) {
        if let action = self.destinationAnnotation?.action {
            self.interactionViewDelegate?.didTapShareLiveLocationLink?(action:action)
        }
    }
    
    
    @IBAction func backButtonPressed(_ sender: Any) {
        if(self.searchText.isFirstResponder){
            self.searchText.resignFirstResponder()
        }
        
        self.didUserStartPanning = false
        self.interactionViewDelegate?.didTapBackButton?(sender)
    }
    
    override func clearView() {
        if (self.multiUserStatusCards.count > 0){
            for card in self.multiUserStatusCards{
                card.removeFromSuperview()
            }
        }
        
        if self.statusCard != nil {
            self.statusCard?.removeFromSuperview()
        }
        
        self.optionsView.isHidden = true
        self.stopTrackingButton.isHidden = true
        
        if self.tripSummarySuperView != nil{
            self.tripSummarySuperView?.removeFromSuperview()
        }
        
        if self.tripSummaryCard != nil {
            self.tripSummaryCard?.removeFromSuperview()
        }
    }
    
}

extension HTLiveLocationView : UITableViewDelegate{
    
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        
        tableView.deselectRow(at: indexPath, animated: true)
        if(indexPath.section == 0 && !isShowingSearchResults){
            if let location = Transmitter.sharedInstance.locationManager.getLastKnownLocation() {
                
                getSearchResultsForCoordinate(cordinate: location.coordinate, completionHandler: { place, error in
                    if(error == nil && place != nil){
                        self.didSelectedLocation(place: place!,selectOnMap : true)
                    }else{
                        //log error
                        
                    }
                })
            }
            else if (indexPath.row == 1){
                
            }
            
            return
        }
        
        let location : HyperTrackPlace
        if(isShowingSavedResults){
            location = (getSavedPlaces()![indexPath.row])
        }else{
            location = (searchResults?[indexPath.row])!
        }
        
        didSelectedLocation(place: location,selectOnMap : false)
    }
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat{
        if(section == 1 ){
            return 20
        }
        return 10
    }
    
    //    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    //        let view = UIView.init(frame: CGRect(x:0,y:0,width:self.mapView.frame.width,height:20))
    //        return view
    //    }
}

extension HTLiveLocationView : UITableViewDataSource{
    
    public func numberOfSections(in tableView: UITableView) -> Int{
        if(!self.isShowingSearchResults){
            return 2
        }
        return 1
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        
        if(section == 0 && !isShowingSearchResults){
            return 2
        }
        
        if(isShowingSavedResults){
            return (getSavedPlaces()!.count)
        }else{
            if searchResults != nil{
                return (searchResults?.count)!
            }
        }
        return 0
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchCell", for: indexPath) as! HTSearchViewCell
        
        let bundle = Bundle(for: HTLiveLocationView.self)
        cell.backgroundColor = UIColor.white
        cell.centreLabel?.text = ""
        cell.mainLabel?.text = ""
        cell.subtitleLabel?.text = ""
        
        if(indexPath.section == 0 && !isShowingSearchResults){
            if( indexPath.row == 0){
                cell.centreLabel?.text = "My location"
                cell.mainLabel?.text = ""
                cell.subtitleLabel?.text = ""
                cell.iconView?.image = UIImage.init(named: "myLocation", in: bundle, compatibleWith: nil)
            }else if (indexPath.row == 1){
                cell.centreLabel?.text = "Choose on map"
                cell.mainLabel?.text = ""
                cell.subtitleLabel?.text = ""
                cell.iconView?.image = UIImage.init(named: "chooseOnMap", in: bundle, compatibleWith: nil)
            }
            return cell
        }
        
        cell.backgroundColor = UIColor.clear
        let location : HyperTrackPlace
        if(isShowingSavedResults){
            location = (getSavedPlaces()![indexPath.row])
            cell.iconView?.image = UIImage.init(named: "recentlyVisited", in: bundle, compatibleWith: nil)
            
        }else{
            location = (searchResults?[indexPath.row])!
            cell.iconView?.image = UIImage.init(named: "searchResult", in: bundle, compatibleWith: nil)
        }
        if(location.name == nil || location.name == ""){
            if(location.address != nil){
                location.name = location.address?.components(separatedBy: ",").first
            }
        }
        cell.mainLabel?.text = location.name
        cell.subtitleLabel?.text = location.address
        
        return cell
    }
    
    
    func getSavedPlaces() -> [HyperTrackPlace]?{
        return Settings.getAllSavedPlaces()
    }
    
    
}

extension HTLiveLocationView {
    
    func textFieldDidChange(_ textField: UITextField) {
        
        if let searchText = textField.text{
            if(textField.text != ""){
                self.isShowingSearchResults = true
                self.reloadSearchTableView()
                self.searchActivityIndicator.startAnimating()
                getSearchResultsForText(searchText: searchText, completionHandler: { places, error in
                    self.searchActivityIndicator.stopAnimating()
                    if(self.isShowingSearchResults){
                        self.searchResultTableView.isHidden = false
                        self.infoView.isHidden = true
                        self.isShowingSavedResults = false
                        
                        if(error == nil){
                            self.searchResults = places
                            self.reloadSearchTableView()
                        }else{
                            //log error
                            self.searchResults = []
                            self.reloadSearchTableView()
                        }
                    }else{
                        self.searchResults = []
                        self.reloadSearchTableView()
                    }
                })
            }else{
                self.isShowingSearchResults = false
                searchResults = []
                self.reloadSearchTableView()
            }
            
        }else{
            self.isShowingSearchResults = false
            searchResults = []
            self.reloadSearchTableView()
        }
    }
    
    func getSearchResultsForText(searchText : String,completionHandler: ((_ places: [HyperTrackPlace]?, _ error: HyperTrackError?) -> Void)?) {
        
        if let location = Transmitter.sharedInstance.locationManager.getLastKnownLocation() {
            var coordinate : CLLocationCoordinate2D? = nil
            coordinate = location.coordinate
            HypertrackService.sharedInstance.findPlaces(searchText: searchText, cordinate: coordinate, completionHandler: completionHandler)
            return
        }
        
    }
}

extension HTLiveLocationView : MapCustomizationDelegate{
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        
        if(shouldStartTrackingRegion && currentViewState != LiveLocationViewState.TRACKING_STARTED && (currentViewState == LiveLocationViewState.LOCATION_SELECTED || currentViewState == LiveLocationViewState.LOCATION_CONFIRM)){
            if(currentViewState != LiveLocationViewState.LOCATION_CONFIRM){
                currentViewState = LiveLocationViewState.LOCATION_CONFIRM
                self.interactionViewDelegate?.willChooseLocationOnMap?()
            }
            self.pinnedImageView?.center = mapView.center
            self.pinnedImageView?.removeFromSuperview()
            mapView.addSubview(self.pinnedImageView!)
            if let annotation =  self.destinationAnnotation {
                mapView.removeAnnotation(annotation)
            }
        }
        else if (currentViewState == LiveLocationViewState.TRACKING_STARTED && haveShownInitialMarkers ) {
            didUserStartPanning = true
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer{
        guard let polyline = overlay as? MKPolyline else {
            return MKOverlayRenderer()
        }
        
        let renderer = MKPolylineRenderer(polyline: polyline)
        renderer.lineWidth = 3.0
        renderer.strokeColor = pink
        
        return renderer
    }
    
    
    func confirmLocation(_ sender: Any){
        
        currentViewState = LiveLocationViewState.LOCATION_SELECTED
        if( currentUserAnnotation == nil){
            if let location = Transmitter.sharedInstance.locationManager.getLastKnownLocation(){
                let currentLocationAnnotation = HTMapAnnotation()
                currentLocationAnnotation.title = "You"
                currentLocationAnnotation.coordinate = location.coordinate
                currentLocationAnnotation.location = location
                currentLocationAnnotation.type = HTConstants.MarkerType.HERO_MARKER
                mapProvider?.addMarker(heroAnnotation: currentLocationAnnotation)
                currentLocationAnnotation.image =  UIImage.init(named: "purpleArrow", in:  Settings.getBundle(), compatibleWith: nil)
                self.currentUserAnnotation = currentLocationAnnotation
            }
        }
        self.focusMarkers()
    }
    
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if(shouldStartTrackingRegion && (currentViewState == LiveLocationViewState.LOCATION_SELECTED || currentViewState == LiveLocationViewState.LOCATION_CONFIRM)  && currentViewState != LiveLocationViewState.TRACKING_STARTED){
            
            if let annotation = self.destinationAnnotation {
                
                DispatchQueue.main.async {
                    
                    annotation.coordinate = mapView.region.center
                    let view = mapView.view(for: annotation)
                    var markerView : HTMarkerWithTitle? = nil
                    
                    if let view = view {
                        markerView = view.subviews.first as? HTMarkerWithTitle
                        markerView?.titleLabel?.text = ""
                        markerView?.activityIndicator.startAnimating()
                    }
                    self.searchActivityIndicator.startAnimating()
                    
                    self.getSearchResultsForCoordinate(cordinate: annotation.coordinate, completionHandler: { place, error in
                        
                        self.searchActivityIndicator.isHidden = true
                        if(markerView != nil){
                            markerView?.activityIndicator.stopAnimating()
                        }
                        if(error == nil){
                            annotation.title = HTGenericUtils.getPlaceName(place: place)
                            annotation.place = place
                            if(markerView != nil){
                                markerView?.titleLabel?.text = HTGenericUtils.getPlaceName(place: place)
                            }
                            self.searchText.text = HTGenericUtils.getPlaceName(place: place)
                            self.selectedLocation = place
                        }
                        
                        self.pinnedImageView?.removeFromSuperview()
                        self.mapProvider?.addMarker(heroAnnotation: annotation)
                        
                    })
                }
            }
        }
    }
    
    
    func annotationView(_ mapView: MKMapView, annotation: HTMapAnnotation) -> MKAnnotationView?{
        if(annotation.type == HTConstants.MarkerType.DESTINATION_MARKER){
            return mapMarkerForDestination(annotation: annotation)
        }
        else{
            return mapMarkerForHero(annotation: annotation)
        }
    }
    
    func mapMarkerForDestination(annotation : HTMapAnnotation) -> MKAnnotationView {
        let bundle = Settings.getBundle()!
        let markerView: HTMarkerWithTitle = bundle.loadNibNamed("MarkerTitleView", owner: self, options: nil)?.first as! HTMarkerWithTitle
        if let title = annotation.title{
            markerView.setTitle(title: title)
        }
        return mapMarkerForView(markerView: markerView)
    }
    
    func mapMarkerForHero(annotation : HTMapAnnotation) -> MKAnnotationView {
        let bundle = Settings.getBundle()!
        let markerView: HTMarkerWithTitle = bundle.loadNibNamed("MarkerTitleView", owner: self, options: nil)?.first as! HTMarkerWithTitle
        markerView.radiate()
        if let title = annotation.title{
            markerView.setTitle(title: title)
        }else{
            if let action = annotation.action{
                if(HTGenericUtils.isCurrentUser(userId: action.user?.id)){
                    markerView.setTitle(title: "You")
                }else{
                    if let name = action.user?.name {
                        markerView.setTitle(title: name)
                    }else{
                        markerView.setTitle(title: "")
                        
                    }
                }
            }
        }
        markerView.markerImage.image =  UIImage.init(named: "triangle", in: bundle, compatibleWith: nil)
        
        
        if(annotation.image != nil){
            markerView.markerImage.image =  annotation.image
            
            
        }
        else{
            if let action = annotation.action{
                if(HTGenericUtils.isCurrentUser(userId: action.user?.id)){
                    markerView.markerImage.image =  UIImage.init(named: "purpleArrow", in: bundle, compatibleWith: nil)
                }
            }
        }
        
        
        
        
        if let user = annotation.action?.user {
            if(HTGenericUtils.isCurrentUser(userId: user.id) ) {
            }
        }
        
        let view =  mapMarkerForView(markerView: markerView)
        if(annotation.location != nil){
            let headingDirection =  annotation.location?.course
            if( Double((headingDirection)!) > 0){
                let rotation = CGFloat(headingDirection!/180 * Double.pi)
                markerView.markerImage.transform = CGAffineTransform(rotationAngle: rotation)
            }
        }
        return view
    }
    
    
    
    func mapMarkerForView(markerView: UIView) -> MKAnnotationView {
        let marker = MKAnnotationView()
        let adjustedOrigin = CGPoint(x: -markerView.frame.size.width / 2, y: -markerView.frame.size.height / 2)
        markerView.frame = CGRect(origin: adjustedOrigin, size: markerView.frame.size)
        
        marker.addSubview(markerView)
        marker.bringSubview(toFront: markerView)
        return marker
    }
    
}


extension HTLiveLocationView{
    
    func getSearchResultsForCoordinate(cordinate: CLLocationCoordinate2D?, completionHandler: ((HyperTrackPlace?, HyperTrackError?) -> Void)?) {
        let geoJsonLocation = HTGeoJSONLocation.init(type: "Point", coordinates: cordinate!)
        HypertrackService.sharedInstance.createPlace(geoJson:geoJsonLocation, completionHandler: completionHandler)
        return
    }
    
}

class HTMarkerWithTitle : UIView {
    
    @IBOutlet weak var titleLabel : UILabel?
    @IBOutlet weak var markerImage: UIImageView!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var radiatingImageView: UIImageView!
    
    @IBOutlet weak var radiationSize: NSLayoutConstraint!
    @IBOutlet weak var widthConstraint: NSLayoutConstraint!
    
    let minWidth = CGFloat(100)
    
    override func awakeFromNib() {
        
        
        titleLabel?.layer.cornerRadius =  (self.titleLabel?.frame.width)! / (10.0)
        titleLabel?.layer.masksToBounds = true
        
        titleLabel?.shadowColor = UIColor.white;
        titleLabel?.shadowOffset = CGSize.init(width: 0, height: 1);

        
    }
    
    func setTitle(title : String?){
        self.titleLabel?.text = ""
        
        if let title = title {
            self.titleLabel?.text = title
            var width =  self.titleLabel?.intrinsicContentSize.width  ?? 0
            width = width + 10.0
            if( width < minWidth){
                self.widthConstraint.constant = width
            }else{
                self.widthConstraint.constant = minWidth
            }
        }else{
            self.titleLabel?.text = ""
        }
        self.titleLabel?.needsUpdateConstraints()
    }
    
    func radiate() {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(0), execute: {
            
            UIView.animate(withDuration: 2, delay: 0, options: [.repeat], animations: {
                self.radiatingImageView.transform = CGAffineTransform(scaleX: 30, y: 30)
                self.radiatingImageView.alpha = 0
            }, completion: { (hello) in
                self.radiatingImageView.alpha = 1
                self.radiatingImageView.transform = CGAffineTransform(scaleX: 0, y: 0)
            })
        })
    }
    
    func stopRadiation() {
        radiatingImageView.layer.removeAllAnimations()
    }
    
    
}

extension HTLiveLocationView:TripSummaryViewDelegate{
    func onDoneClicked(view: TripSummaryView) {
        self.interactionViewDelegate?.didTapBackButton?(self)
    }
}

extension HTLiveLocationView: UITextFieldDelegate{
    public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool{
        if(currentViewState == LiveLocationViewState.LOCATION_CONFIRM  || currentViewState == LiveLocationViewState.LOCATION_SELECTED){
            currentViewState = LiveLocationViewState.LOCATION_SEARCH
            resetViewToStartSearch()
        }
        return true
    }
}

extension HTLiveLocationView : StatusViewDelegate{
    
    func willExpand(view: UIView){
        self.refocusButton.isHidden = true
    }
    func didExpand(view: UIView ){
        self.refocusButton.isHidden = false
        self.refocusHeightConstraint.constant = view.frame.size.height + 10
        self.refocusButton.needsUpdateConstraints()
    }
    func willShrink(view : UIView){
        self.refocusButton.isHidden = true
        
    }
    func didShrink(view : UIView){
        self.refocusButton.isHidden = false
        self.refocusHeightConstraint.constant = view.frame.size.height + 10
        self.refocusButton.needsUpdateConstraints()
    }
}

