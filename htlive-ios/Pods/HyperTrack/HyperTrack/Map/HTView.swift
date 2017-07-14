//
//  HTView.swift
//  HyperTrack
//
//  Created by Vibes on 5/24/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import UIKit
import MapKit

class HTView: UIView,UICollectionViewDataSource, UICollectionViewDelegate,UICollectionViewDelegateFlowLayout,HTStausCardActionDelegate{
    @IBOutlet weak var mapView: UIView!
    @IBOutlet weak var reFocusButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var destinationView: UIView!
    @IBOutlet weak var statusCard: UIView!
    @IBOutlet weak var status: UILabel!
    @IBOutlet weak var eta: UILabel!
    @IBOutlet weak var distanceLeft: UILabel!
    @IBOutlet weak var phoneButton: UIButton!
    @IBOutlet weak var destination: UILabel!
    @IBOutlet weak var progressView: UIView!
    @IBOutlet weak var arrow: UIImageView!
    @IBOutlet weak var cardConstraint: NSLayoutConstraint!
    @IBOutlet weak var tripIcon: UIImageView!
    
    @IBOutlet weak var touchView: UIView!
    var progressCircle = CAShapeLayer()
    var currentProgress : Double = 0
    var isCardExpanded = false
    var expandedCard : ExpandedCard? = nil
    var downloadedPhotoUrl : URL? = nil
    var statusCardEnabled = true
    var interactionViewDelegate: HTViewInteractionInternalDelegate?
    
    
    public var scalingCarousel: HTScalingCarouselView!
    var isLiveLocationSharingEnabled = false
    var previousCount = 0
    var carouselHeightConstraint : NSLayoutConstraint?
    var isCarouselExpanded = false
    var enableCarouselView = true
    let carouselShrinkedHeight = CGFloat(87)
    let carouselExpandedHeight = CGFloat(245)
    let carouselWidthOffset = CGFloat(40)
    let carouselInset = CGFloat(20)
    
    var currentSelectedIndexPath : IndexPath?
    var currentVisibleIndex = 0
    var numberOfItemsInCarousel = 0
    var useCase = HTConstants.UseCases.TYPE_SINGLE_USER_SINGLE_ACTION
    var mapProvider: MapProviderProtocol?
    
    
    func initMapView(mapSubView: MKMapView, interactionViewDelegate: HTViewInteractionInternalDelegate) {
        self.mapView.addSubview(mapSubView)
        self.interactionViewDelegate = interactionViewDelegate
        self.clearView()
    }
    
    override func awakeFromNib() {
        destinationView.shadow()
        statusCard.shadow()
        addProgressCircle()
        addExpandedCard()
        self.statusCard.isHidden = isLiveLocationSharingEnabled
    }
    
    @IBAction func phone(_ sender: Any) {
        self.interactionViewDelegate?.didTapPhoneButton?(sender)
    }
    
    @IBAction func back(_ sender: Any) {
        self.interactionViewDelegate?.didTapBackButton?(sender)
    }
    
    @IBAction func reFocus(_ sender: Any) {
        self.interactionViewDelegate?.didTapReFocusButton?(sender)
    }
    
    @IBAction func expandCard(_ sender: Any) {
        
        if !isCardExpanded {
            
            UIView.animate(withDuration: 0.2, animations: {
                self.cardConstraint.constant = 160
                self.arrow.transform = CGAffineTransform(rotationAngle: 1.57)
                self.layoutIfNeeded()
            })
            
            isCardExpanded = true
        } else {
            
            UIView.animate(withDuration: 0.2, animations: {
                self.cardConstraint.constant = 20
                self.arrow.transform = CGAffineTransform(rotationAngle: 0)
                self.layoutIfNeeded()
            })
            
            isCardExpanded = false
        }
    }
    
    func updateAddressView(isAddressViewShown: Bool, destinationAddress: String?) {
        if isAddressViewShown {
            self.destination.text = destinationAddress
            self.destinationView.isHidden = false
        } else {
            self.destinationView.isHidden = true
        }
    }
    
    func updateInfoView(isInfoViewShown: Bool, showActionDetailSummary: Bool, eta: Double?,
                        distanceLeft: Double?, status: String, userName: String,
                        lastUpdated: Date, timeElapsed: Double, distanceCovered: Double,
                        speed: Int?, battery: Int?, photoUrl: URL?, startTime: Date?, endTime: Date?,
                        origin: String?, destination: String?, showExpandedCardOnCompletion: Bool) {
        //  Check if InfoView is disabled
        if !isInfoViewShown {
            self.statusCard.isHidden = true
            return
        }
        
        // Make InfoView visible
        self.statusCard.isHidden = isLiveLocationSharingEnabled
        
        var progress: Double = 1.0
        
        if (showActionDetailSummary) {
            // Update eta & distance data
            self.eta.text = "\(Int(timeElapsed)) min"
            self.distanceLeft.text = "\(distanceCovered) mi"
            
            if (distanceLeft != nil) {
                progress = distanceCovered / (distanceCovered + distanceLeft!)
            }
            
        } else {
            if (eta != nil) {
                self.eta.text = "ETA \(Int(eta!)) min"
            } else {
                self.eta.text = " "
            }
            
            if (distanceLeft != nil) {
                if (eta != nil) {
                    self.distanceLeft.text = "(\(distanceLeft!) mi)"
                } else {
                    self.distanceLeft.text = "\(distanceLeft!) mi"
                }
            } else {
                self.distanceLeft.text = ""
            }
        }
        
        self.status.text = status
        animateProgress(to: progress)
        
        UIView.animate(withDuration: 0.15) {
            self.layoutIfNeeded()
        }
        
        if let expandedCard = self.expandedCard {
            
            expandedCard.name.text = userName
            
            if let photo = photoUrl {
                if (self.downloadedPhotoUrl == nil) || (self.downloadedPhotoUrl != photo) {
                    expandedCard.photo.image = getImage(photoUrl: photo)
                }
            }
            
            if (showActionDetailSummary) {
                self.completeActionView(startTime: startTime, endTime: endTime,
                                        origin: origin, destination: destination,
                                        timeElapsed: timeElapsed,
                                        distanceCovered: distanceCovered,
                                        showExpandedCardOnCompletion: showExpandedCardOnCompletion)
            } else {
                let timeInSeconds = Int(timeElapsed * 60.0)
                let hours = timeInSeconds / 3600
                let minutes = (timeInSeconds / 60) % 60
                let seconds = timeInSeconds % 60
                
                expandedCard.timeElapsed.text = String(format: "%0.2d:%0.2d:%0.2d", hours, minutes, seconds)
                expandedCard.distanceTravelled.text = "\(distanceCovered) mi"
                
                if (speed != nil) {
                    expandedCard.speed.text = "\(speed!) mph"
                } else {
                    expandedCard.speed.text = "--"
                }
                
                if (battery != nil) {
                    expandedCard.battery.text = "\(Int(battery!))%"
                } else {
                    expandedCard.battery.text = "--"
                }
                
                let lastUpdatedMins = Int(-1 * Double(lastUpdated.timeIntervalSinceNow) / 60.0)
                
                if (lastUpdatedMins < 1) {
                    expandedCard.lastUpdated.text = "Last updated: few seconds ago"
                } else {
                    expandedCard.lastUpdated.text = "Last updated: \(lastUpdatedMins) min ago"
                }
            }
        }
    }
    
    private func completeActionView(startTime: Date?, endTime: Date?,
                                    origin: String?, destination: String?,
                                    timeElapsed: Double, distanceCovered: Double,
                                    showExpandedCardOnCompletion: Bool) {
        guard statusCardEnabled else { return }
        
        let bundle = Settings.getBundle()!
        let completedView: CompletedView = bundle.loadNibNamed("CompletedView", owner: self, options: nil)?.first as! CompletedView
        completedView.alpha = 0
        
        self.statusCard.addSubview(completedView)
        self.statusCard.bringSubview(toFront: completedView)
        self.statusCard.bringSubview(toFront: phoneButton)
        
        completedView.frame = CGRect(x: 0, y: 90, width: self.statusCard.frame.width, height: 155)
        
        self.statusCard.clipsToBounds = true
        
        completedView.completeUpdate(startTime: startTime, endTime: endTime, origin: origin, destination: destination)
        
        //        if (showExpandedCardOnCompletion) {
        self.touchView.isHidden = true
        self.isCardExpanded = true
        
        UIView.animate(withDuration: 0.2, animations: {
            self.cardConstraint.constant = 160
            completedView.alpha = 1
            self.arrow.alpha = 0
            self.layoutIfNeeded()
        })
        
        //        } else {
        //            self.touchView.isHidden = false
        //            self.isCardExpanded = false
        //
        //            UIView.animate(withDuration: 0.2, animations: {
        //                self.cardConstraint.constant = 20
        //                self.arrow.transform = CGAffineTransform(rotationAngle: 0)
        //                self.layoutIfNeeded()
        //            })
        //        }
    }
    
    func updateReFocusButton(isRefocusButtonShown: Bool) {
        self.reFocusButton.isHidden = !isRefocusButtonShown
    }
    
    func updateBackButton(isBackButtonShown: Bool) {
        self.backButton.isHidden = !isBackButtonShown
    }
    
    func clearView() {
        self.destinationView.isHidden = true
        self.statusCard.isHidden = true
        self.reFocusButton.isHidden = true
    }
    
    func addProgressCircle() {
        
        let circlePath = UIBezierPath(ovalIn: progressView.bounds.insetBy(dx: 5 / 2.0, dy: 5 / 2.0))
        
        progressCircle = CAShapeLayer ()
        progressCircle.path = circlePath.cgPath
        progressCircle.strokeColor = htblack.cgColor
        progressCircle.fillColor = grey.cgColor
        progressCircle.lineWidth = 2.5
        
        progressView.layer.insertSublayer(progressCircle, at: 0)
        
        animateProgress(to: 0)
    }
    
    func addExpandedCard() {
        let bundle = Settings.getBundle()!
        let expandedCard: ExpandedCard = bundle.loadNibNamed("ExpandedCard", owner: self, options: nil)?.first as! ExpandedCard
        self.expandedCard = expandedCard
        self.statusCard.addSubview(expandedCard)
        self.statusCard.sendSubview(toBack: expandedCard)
        expandedCard.frame = CGRect(x: 0, y: 90, width: self.statusCard.frame.width, height: 155)
        self.statusCard.clipsToBounds = true
    }
    
    func getImage(photoUrl: URL) -> UIImage? {
        do {
            let imageData = try Data.init(contentsOf: photoUrl, options: Data.ReadingOptions.dataReadingMapped)
            self.downloadedPhotoUrl = photoUrl
            return UIImage(data:imageData)
        } catch let error {
            HTLogger.shared.error("Error in fetching photo: " + error.localizedDescription)
            return nil
        }
    }
    
    func animateProgress(to : Double) {
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = currentProgress
        animation.toValue = to
        animation.duration = 0.5
        animation.fillMode = kCAFillModeForwards
        animation.isRemovedOnCompletion = false
        
        progressCircle.add(animation, forKey: "ani")
        self.currentProgress = to
    }
    
    func noPhone() {
        self.phoneButton.isHidden = true
        self.tripIcon.alpha = 1
    }
    
    
    public func addCarousel() {
        if(isLiveLocationSharingEnabled){
            let frame = CGRect(x: 0, y: 0, width: 0, height: 0)
            scalingCarousel = HTScalingCarouselView(withFrame: frame, andInset: carouselInset)
            scalingCarousel.dataSource = self
            scalingCarousel.delegate = self
            scalingCarousel.translatesAutoresizingMaskIntoConstraints = false
            scalingCarousel.backgroundColor = .clear
            scalingCarousel.register(HTStatusCarouselCell.self, forCellWithReuseIdentifier: "cell")
            
            self.addSubview(scalingCarousel)
            self.bringSubview(toFront: scalingCarousel)
            if #available(iOS 9.0, *) {
                scalingCarousel.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 1).isActive = true
                carouselHeightConstraint = scalingCarousel.heightAnchor.constraint(equalToConstant: carouselShrinkedHeight)
                carouselHeightConstraint?.isActive = true
                scalingCarousel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -10).isActive = true
                reFocusButton.bottomAnchor.constraint(equalTo: self.scalingCarousel.topAnchor, constant: -10).isActive = true
            } else {
                // Fallback on earlier versions
            }
           
            
        }
    }
    
    func isCurrentUserSharingLocation() -> Bool {
        let userIds = HTConsumerClient.sharedInstance.getUserIds()
        let currentUserId = Transmitter.sharedInstance.getUserId()
        if(userIds.count > 0){
            if let userId = currentUserId{
                if(userIds.contains(userId)){
                    return true
                }
            }
        }
        return false
    }
    
    func getUserIdForIndexPath(_ indexPath : IndexPath) -> String? {
        var userId : String?
        let userIds = HTConsumerClient.sharedInstance.getUserIds()
        if(!isCurrentUserSharingLocation() && indexPath.row == 0){
            userId = nil
        }else if (!isCurrentUserSharingLocation()){
            userId = userIds[indexPath.row - 1]
        }
        else{
            userId = userIds[indexPath.row]
        }
        
        return userId
    }
    
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var count = 0
        let userIds = HTConsumerClient.sharedInstance.getUserIds()
        count = userIds.count
        if(!isCurrentUserSharingLocation()){
            count = userIds.count + 1
        }
        numberOfItemsInCarousel = count
        return count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        let userIds = HTConsumerClient.sharedInstance.getUserIds()
        let statusCell = cell as! HTStatusCarouselCell
        statusCell.actionDelegate = self
        statusCell.indexPath = indexPath
        
        var userId = self.getUserIdForIndexPath(indexPath)
        if(userId == nil){
            if let scalingCell = cell as? HTScalingCarouselCell {
                statusCell.changeToShareLiveLocationButton()
            }
            return cell
        }else{
            let user = HTConsumerClient.sharedInstance.getUser(userId: userId!)
            let action = user?.actions?.last
            let statusInfo = getUserInfo(action as! HyperTrackAction, userId)
            statusCell.user = user
            
            if let scalingCell = cell as? HTScalingCarouselCell {
                statusCell.changeToNormalView()
                statusCell.reloadWithUpdatedInfo(statusInfo);
            }
            return cell
        }
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scalingCarousel.didScroll()
        let cellWidth = self.frame.width + carouselInset - carouselWidthOffset
        let currentIndexRow = CGFloat(scrollView.contentOffset.x) / cellWidth
        var currentIndex = Int(round(currentIndexRow))
        
        if (currentIndex < 0 ) {
            currentIndex = 0
        } else if (currentIndex > (numberOfItemsInCarousel - 1)){
            currentIndex = numberOfItemsInCarousel - 1
        }
        
        if( currentIndex != currentVisibleIndex){
            if let userId = self.getUserIdForIndexPath(IndexPath.init(row: currentIndex, section: 0)) {
                mapProvider?.focusMapFor(userId: userId)
            }
        }
        
        self.currentVisibleIndex = currentIndex
    }
    
    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath){
        
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if (isCarouselExpanded) {
            return CGSize(width:self.frame.width - carouselWidthOffset ,height:carouselExpandedHeight)
        }
        
        return CGSize(width:self.frame.width - carouselWidthOffset ,height:carouselShrinkedHeight)
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if (!isCurrentUserSharingLocation() && indexPath.row == 0) {
            return
        }
        
        let cell = collectionView.cellForItem(at: indexPath) as! HTStatusCarouselCell
        if (isCarouselExpanded) {
            currentSelectedIndexPath = nil
            shrinkCarousel()
            cell.setIsExpanded(false)
            
        } else {
            currentSelectedIndexPath = indexPath
            expandCarousel()
            cell.setIsExpanded(true)
        }
        
        collectionView.reloadData()
    }
    
    func startSharingLiveLocation(user : HTTrackedUser? ,indexPath: IndexPath?){
        
        let userId = HTConsumerClient.sharedInstance.getUserIds().first
        let user = HTConsumerClient.sharedInstance.getUser(userId: userId!)
        let lookUpId = user?.actions?.last??.lookupId
        let placeId = user?.actions?.last??.expectedPlace?.id
        self.interactionViewDelegate?.didTapStartLiveLocationSharing!(lookUpId: lookUpId!, place: (user?.actions?.last??.expectedPlace))
        //        let htActionParams = HyperTrackActionParams()
        //        htActionParams.expectedPlaceId = placeId
        //        htActionParams.type = "visit"
        //        htActionParams.lookupId = lookUpId!
        //
        //        HyperTrack.createAndAssignAction(htActionParams, { (action, error) in
        //            if let error = error {
        //                return
        //            }
        //            if let action = action {
        //
        //                return
        //            }
        //        })
        
    }
    
    func stopSharingLiveLocation(user: HTTrackedUser?,indexPath: IndexPath){
        self.interactionViewDelegate?.didTapStopLiveLocationSharing!(actionId:  (user?.actions?.last??.id)!)
        //  Transmitter.sharedInstance.completeAction(actionId: user?.actions?.last??.id)
    }
    
    func userClickedOnPhone(user : HTTrackedUser?,indexPath:IndexPath){
        
    }
    
    func expandCarousel(){
        self.carouselHeightConstraint?.isActive = false
        if #available(iOS 9.0, *) {
            self.carouselHeightConstraint = scalingCarousel.heightAnchor.constraint(equalToConstant: carouselExpandedHeight)
        } else {
            // Fallback on earlier versions
        }
        
        UIView.animate(withDuration: 0.2) {
            self.carouselHeightConstraint?.isActive = true
            self.layoutIfNeeded()
        }
        isCarouselExpanded = true
    }
    
    func shrinkCarousel(){
        carouselHeightConstraint?.isActive = false
        if #available(iOS 9.0, *) {
            carouselHeightConstraint = scalingCarousel.heightAnchor.constraint(equalToConstant: carouselShrinkedHeight)
        } else {
            // Fallback on earlier versions
        }
        UIView.animate(withDuration: 0.2) {
            self.carouselHeightConstraint?.isActive = true
            self.layoutIfNeeded()
        }
        isCarouselExpanded = false
    }
    
    
    func reloadCarousel(){
        if let scalingCarousel = scalingCarousel{
            scalingCarousel.reloadData()
        }
    }
    
    func isCurrentUser(userId : String?) -> Bool{
        if var userId = userId {
            var currentUserId = Transmitter.sharedInstance.getUserId()
            if(currentUserId == userId){
                return true
            }
        }
        return false
    }
    
    func getUserInfo(_ action: HyperTrackAction, _ userId : String?) -> HTStatusCardInfo {
        
        let statusInfo = HTStatusCardInfo()
        
        if let startedAt = action.startedAt {
            var timeElapsed: Double?
            
            if action.endedAt != nil {
                timeElapsed = startedAt.timeIntervalSince(action.endedAt!)
            } else {
                timeElapsed = startedAt.timeIntervalSinceNow
            }
            statusInfo.timeElapsedMinutes = -1 * Double(timeElapsed! / 60)
        }
        
        
        if let distance = action.distance {
            // Convert distance (meters) to miles and round to one decimal
            statusInfo.distanceCovered = round(distance * 0.000621371 * 10) / 10
        } else {
            statusInfo.distanceCovered  = 0.0
        }
        
        if let user = action.user as HyperTrackUser? {
            statusInfo.userName = user.name!
            
            if (isCurrentUser(userId: userId)) {
                statusInfo.markerUserName = "You"
                let bundle = Bundle(for: HTMap.self)
                if (action.display?.showSummary )!{
                    statusInfo.infoCardImage =  UIImage.init(named: "play", in: bundle, compatibleWith: nil)
                    
                } else {
                    statusInfo.infoCardImage =  UIImage.init(named: "square", in: bundle, compatibleWith: nil)
                }
                
                statusInfo.isCurrentUser = true
            } else {
                let fullNameArr =  statusInfo.userName .components(separatedBy: " ")
                statusInfo.markerUserName = fullNameArr[0]
            }
            
            if let photo = user.photo {
                statusInfo.photoUrl = URL(string: photo)
            }
            
            if let batteryPercentage = user.lastBattery {
                statusInfo.battery = batteryPercentage
            }
            
            if let heartbeat = user.lastHeartbeatAt {
                statusInfo.lastUpdated = heartbeat
            }
            
            if let location = user.lastLocation {
                if location.speed >= 0 {
                    statusInfo.speed = Int(location.speed * 2.23693629)
                }
            }
        }
        
        let actionDisplay = action.display
        if (actionDisplay != nil) {
            if let duration = actionDisplay!.durationRemaining {
                let timeRemaining = duration
                statusInfo.etaMinutes = Double(timeRemaining / 60)
            }
            
            if let statusText = actionDisplay!.statusText {
                
                statusInfo.status =  statusText
                
                if (statusText.lowercased() == "on the way"  || statusText.lowercased() == "arriving" || statusText.lowercased() == "leaving now"){
                    statusInfo.status = statusInfo.markerUserName! + " is " + statusText.lowercased()
                    if(isCurrentUser(userId : userId)){
                        statusInfo.status = statusInfo.markerUserName! + " are " + statusText.lowercased()
                    }
                    
                } else if (action.display?.showSummary )!{
                    statusInfo.status = statusInfo.markerUserName! + " has " + statusText.lowercased() + " trip"
                    
                    if(isCurrentUser(userId : userId)){
                        statusInfo.status = statusInfo.markerUserName! + " have " + statusText.lowercased() + " trip"
                    }
                    
                    statusInfo.isCompletedOrCanceled = true
                }
            }
            
            if let distance = actionDisplay!.distanceRemaining {
                // Convert distance (meters) to miles and round to one decimal
                statusInfo.distanceLeft = round(Double(distance) * 0.000621371 * 10) / 10
            }
            
            statusInfo.showActionDetailSummary = actionDisplay!.showSummary
            
            // Check if Action summary needs to be displayed on map or not
            if self.useCase == HTConstants.UseCases.TYPE_SINGLE_USER_SINGLE_ACTION {
                statusInfo.showActionPolylineSummary = actionDisplay!.showSummary
                statusInfo.showExpandedCardOnCompletion = actionDisplay!.showSummary
            }
        }
        
        if let address = action.startedPlace?.address {
            statusInfo.startAddress = address
        }
        
        if let address = action.completedPlace?.address {
            statusInfo.completeAddress = address
        }
        
        statusInfo.startTime = action.assignedAt
        statusInfo.endTime = action.endedAt
        return statusInfo
    }
}
