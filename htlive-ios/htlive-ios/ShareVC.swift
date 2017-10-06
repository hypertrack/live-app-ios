//
//  ShareVC.swift
//  htlive-ios
//
//  Created by Vibes on 7/4/17.
//  Copyright © 2017 PZRT. All rights reserved.
//

import UIKit
import HyperTrack
import MapKit
import CoreGraphics
import Contacts
import MessageUI
import Crashlytics

class ShareVC: UIViewController  {
    let monitorRegionRadius = 100
    
    @IBOutlet fileprivate weak var hyperTrackView: UIView!
    @IBOutlet fileprivate weak var shareLocationButton: UIButton!
    
    var shortCode : String?
    var collectionId: String?
    
    var hyperTrackMap : HTMap? = nil
    var isDeeplinked = false
    var selectedLocation : HyperTrackPlace?
    var alertController : UIAlertController?
    var shareView: CustomShareView?
    var activityViewController : UIActivityViewController? = nil
    private lazy var liveLocationAlert:LiveLocationAlertView? = {
        return Bundle.main.loadNibNamed("LiveLocationAlert", owner: self, options: nil)?.first as? LiveLocationAlertView
    }()
    
    
    @IBOutlet var placeHolderMapView : MKMapView!
    
    @IBOutlet weak var shareLocationActivityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        shareLocationButton.shadow()
        HyperTrack.getCurrentLocation { (clLocation, error) in
            if let location  = clLocation{
                let region = MKCoordinateRegionMake((location.coordinate),MKCoordinateSpanMake(0.005, 0.005))
                self.placeHolderMapView.setRegion(region, animated: true)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.view.showActivityIndicator()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        if (hyperTrackMap != nil){
            hyperTrackMap = nil
        }
        
        super.viewDidAppear(animated)
        self.view.hideActivityIndicator()
        
        if let collectionId = self.collectionId{
            self.isDeeplinked = true
            self.trackTripFromCollectionId(collectionId: collectionId)
        }
        else if let shortCode = self.shortCode {
            self.isDeeplinked = true
            self.trackTripFromShortCode(shortCode: shortCode)
        }
        else if(HyperTrackAppService.sharedInstance.getCurrentCollectionId() != nil) {
            self.isDeeplinked = true
            self.trackTripFromCollectionId(collectionId: HyperTrackAppService.sharedInstance.getCurrentCollectionId()!)
        }
        
        if(!isDeeplinked){
            showHypertrackView()
        }
    }
    
    
    override func viewDidDisappear(_ animated: Bool) {
        self.hyperTrackMap?.resetViews()
    }
    
    func trackTripFromShortCode(shortCode : String){
        self.view.showActivityIndicator()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            HyperTrack.getActionsFromShortCode(shortCode, completionHandler: { (actions, error) in
                
                self.view.hideActivityIndicator()
                
                if let _ = error {
                    self.showAlertAndDismissController(title: "Error", message: error?.errorMessage)
                    return
                }
                
                if let htActions = actions {
                    if let collectionId =  htActions.last?.collectionId{
                        self.trackTripFromCollectionId(collectionId: collectionId)
                    }else{
                        self.showAlertAndDismissController(title: "Error", message: "Something went wrong, no look up id in the action")
                    }
                    
                }else {
                    self.showAlertAndDismissController(title: "Error", message: "Something went wrong, no actions for this lookup id")
                    
                }
            })
        }
    }
    
    func trackTripFromCollectionId(collectionId : String){
        self.view.showActivityIndicator()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            HyperTrack.trackActionFor(collectionId: collectionId, completionHandler: { (actions, error) in
                
                self.view.hideActivityIndicator()
                
                if let _ = error {
                    self.liveLocationAlert?.activityIndicator.stopAnimating()
                    self.changeToStartTrackingButton()
                    self.showAlertAndDismissController(title: "Error", message: error?.errorMessage)
                    return
                }
                
                if let actions = actions {
                    if actions.count > 0 {
                        HyperTrackAppService.sharedInstance.currentAction = actions.last
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            if (!self.doesCollectionIdHasMyUserId(actions: actions)){
                                if (!(actions.last?.isCompleted())!){
                                    self.showShareLiveLocationView(action: (actions.last)!)
                                }
                            }else{
                                if let action = self.getActionFrom(actions: actions, collectionId: collectionId, userId:HyperTrack.getUserId()!){
                                    HyperTrackAppService.sharedInstance.currentAction = action
                                }
                                
                            }
                            self.showHypertrackView()
                        }
                    }
                    else{
                        self.showAlertAndDismissController(title: "Something went wrong.", message: "Try again later")
                    }
                }else{
                    self.showAlertAndDismissController(title: "Something went wrong.", message: "Try again later")
                }
            })
        }
    }
    
    
    
    func showHypertrackView(){
        if(hyperTrackMap == nil){
            hyperTrackMap = HyperTrack.map()
            hyperTrackMap?.showBackButton = false
            hyperTrackMap?.showReFocusButton = false
            hyperTrackMap?.showTrafficForMapView = false
            hyperTrackMap?.enableLiveLocationSharingView = true
            
            hyperTrackMap?.setHTViewCustomizationDelegate(customizationDelegate: self)
            hyperTrackMap?.setHTViewInteractionDelegate(interactionDelegate: self)
            if (self.hyperTrackView != nil) {
                hyperTrackMap?.embedIn(self.hyperTrackView)
            }
        }
    }
    
    func showShareSheetWithText(text:String){
        let textToShare : Array = [text]
        self.activityViewController = UIActivityViewController(activityItems: textToShare, applicationActivities: nil)
        self.activityViewController?.completionWithItemsHandler = { activityType, complete, returnedItems, error in
        }
        DispatchQueue.main.async {
            self.present(self.activityViewController!, animated: false, completion: nil)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    fileprivate var error: NSError {
        get {
            return NSError(domain: "io.hypertrack.meta", code: 400, userInfo: nil)
        }
    }
    
    fileprivate func showAlert(title: String?, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let ok: UIAlertAction = UIAlertAction.init(title: "OK", style: .cancel, handler: nil)
        alert.addAction(ok)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    fileprivate func showAlertAndDismissController(title: String?, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let ok : UIAlertAction = UIAlertAction.init(title: "OK", style: .cancel) { (action) in
            self.dismiss(animated: true, completion: nil)
        }
        alert.addAction(ok)
        
        if (self.isBeingPresented){
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.present(alert, animated: true, completion: nil)
            }
        }
        else{
            self.present(alert, animated: true, completion: nil)
            
        }
    }
    
    func changeToConfirmLocatinButton(){
        self.liveLocationAlert?.closeButton.isHidden = true
        self.liveLocationAlert?.mainLabel.text = "Move map to adjust marker"
        self.liveLocationAlert?.actionButton.setTitle("Confirm Location", for: UIControlState.normal)
        self.liveLocationAlert?.actionButton.removeTarget(self, action: #selector(startTracking(_:)), for: UIControlEvents.touchUpInside)
        self.liveLocationAlert?.actionButton.addTarget(self, action: #selector(confirmLocation(_:)), for: UIControlEvents.touchUpInside)
    }
    
    func changeToStartTrackingButton(){
        self.liveLocationAlert?.closeButton.isHidden = true
        self.liveLocationAlert?.mainLabel.text = "Looks good?"
        self.liveLocationAlert?.actionButton.removeTarget(self, action: #selector(confirmLocation(_:)), for: UIControlEvents.touchUpInside)
        self.liveLocationAlert?.actionButton.setTitle("Share Live Location", for: UIControlState.normal)
        self.liveLocationAlert?.actionButton.addTarget(self, action: #selector(startTracking(_:)), for: UIControlEvents.touchUpInside)
    }
    
    func changeToStopTrackingButton(){
        self.liveLocationAlert?.closeButton.isHidden = false
        
        self.liveLocationAlert?.mainLabel.text = "Are you sure?"
        self.liveLocationAlert?.actionButton.removeTarget(self, action: #selector(stopTracking(_:)), for: UIControlEvents.touchUpInside)
        self.liveLocationAlert?.actionButton.setTitle("Stop Sharing", for: UIControlState.normal)
        self.liveLocationAlert?.actionButton.addTarget(self, action: #selector(stopTracking(_:)), for: UIControlEvents.touchUpInside)
    }
    func stopTracking(_ sender: Any) {
        HyperTrackAppService.sharedInstance.completeAction()
        removeCustomAlert()
    }
    
    func showCustomAlert(){
        self.view.addSubview(liveLocationAlert!)
        presentViewAnimatedFromBottom(view:liveLocationAlert!)
    }
    
    func removeCustomAlert(){
        self.liveLocationAlert?.activityIndicator.stopAnimating()
        self.liveLocationAlert?.removeFromSuperview()
    }
    
    
    func confirmLocation(_ sender: Any){
        self.selectedLocation  = hyperTrackMap?.confirmLocation()
        changeToStartTrackingButton()
    }
    
    func startTracking(_ sender: Any) {
        self.liveLocationAlert?.actionButton.setTitle("", for: UIControlState.normal)
        self.liveLocationAlert?.activityIndicator.startAnimating()
        
        guard let place =  self.selectedLocation else {
            self.showAlert(title: "Error", message: "No Selected Location")
            return
        }
        let htActionParams = HyperTrackActionParams()
        htActionParams.expectedPlace = place
        htActionParams.type = "visit"
        htActionParams.collectionId = UUID().uuidString
        
        HyperTrack.createAndAssignAction(htActionParams, { (action, error) in
            if let error = error {
                self.showAlert(title: "Error", message: error.errorMessage)
                return
            }
            if let action = action {
                HyperTrack.trackActionFor(collectionId: action.collectionId!, completionHandler: { (actions, error) in
                    if let _ = error {
                        self.liveLocationAlert?.activityIndicator.stopAnimating()
                        self.changeToStartTrackingButton()
                        return
                    }
                    
                    if let actions = actions {
                        if actions.count > 0 {
                            HyperTrackAppService.sharedInstance.setCurrentCollectionId(collectionId: (action.collectionId)!)
                            HyperTrackAppService.sharedInstance.setCurrentTrackedAction(action: action)
                            
                            // add geofence code here
                            HyperTrack.startMonitoringForEntryAtPlace(place: place,radius:CLLocationDistance(self.monitorRegionRadius),identifier:(action.collectionId)!)
                            
                            
                            self.removeCustomAlert()
                            self.shareLink(action: action)
                        }
                        else{
                            self.showAlertAndDismissController(title: "Something went wrong.", message: "No actions found")
                        }
                    }else{
                        self.showAlertAndDismissController(title: "Something went wrong.", message: "No actions found")
                    }
                })
            }else{
                self.showAlert(title: "Error", message: "No action found")
            }
        })
    }
    
    func showStopTrackingAlert(){
        changeToStopTrackingButton()
        liveLocationAlert?.removeFromSuperview()
        self.view.addSubview(liveLocationAlert!)
        presentViewAnimatedFromBottom(view:liveLocationAlert!)
    }
    
    
    func doesCollectionIdHasMyUserId(actions : [HyperTrackAction]) -> Bool{
        for action in actions {
            if let userId = action.user?.id {
                if (HyperTrack.getUserId() == userId){
                    return true
                }
            }
        }
        return false
    }
    
    func isMyUserId(action : HyperTrackAction)-> Bool{
        if let userId = action.user?.id {
            if (HyperTrack.getUserId() == userId){
                return true
            }
        }
        return false
    }
    
    func getActionFrom(actions : [HyperTrackAction],collectionId:String,userId:String) -> HyperTrackAction?{
        for action in actions {
            if(action.user?.id == userId && action.collectionId == collectionId){
                return action
            }
        }
        return nil
    }
    
    
}

extension ShareVC:HTViewCustomizationDelegate{
    
    func showInfoViewForActionID(map: HTMap, actionID: String) -> Bool{
        return true
    }
}


extension ShareVC:HTViewInteractionDelegate {
    
    
    func didSelectLocation(place : HyperTrackPlace?){
        self.changeToStartTrackingButton()
        self.selectedLocation = place
        showCustomAlert()
    }
    
    func willChooseLocationOnMap(){
        self.changeToConfirmLocatinButton()
        showCustomAlert()
    }
    
    func didTapBackButton(_ sender: Any) {
        HyperTrackFlowInteractor.topViewController()?.dismiss(animated: true, completion: nil)
    }
    
    func didTapStopLiveLocationSharing(actionId : String){
        showStopTrackingAlert()
    }
    
    func didTapShareLiveLocationLink(action : HyperTrackAction){
        self.shareLink(action: action)
    }
    
    func showShareLiveLocationView(action : HyperTrackAction){
        
        let shareView: ShareLiveLocationView = Bundle.main.loadNibNamed("ShareLiveLocationView", owner: self, options: nil)?.first as! ShareLiveLocationView
        shareView.shareDelegate = self
        shareView.action = action
        
        if(action.eta != nil){
            var etaMinutes = 0.0
            let actionDisplay = action.display
            if (actionDisplay != nil) {
                if let duration = actionDisplay!.durationRemaining {
                    let timeRemaining = duration
                    etaMinutes = Double(timeRemaining / 60)
                    shareView.etaLabel.text = "Your friend is \(Int(etaMinutes)) min away!"
                    
                    if let name = action.user?.name {
                        shareView.etaLabel.text = name + " is \(Int(etaMinutes)) min away!"
                    }
                }
            }
        }
        else{
            shareView.etaLabel.text = ""
        }
        
        self.view.addSubview(shareView)
        shareView.frame = CGRect(x:0,y:(self.view.frame.height + (shareView.frame.size.height)),width : self.view.frame.size.width,height:shareView.frame.size.height)
        UIView.animate(withDuration: 0.5, animations: {
            shareView.frame = CGRect(x:0,y:(self.view.frame.height-(shareView.frame.size.height)),width : self.view.frame.size.width,height:shareView.frame.size.height)
        })
        
        shareView.cloaseButton.isHidden = false
        shareView.cloaseButton.addTarget(self, action: #selector(showShareLocationButton(_:)), for: UIControlEvents.touchUpInside)
        
    }
    
    @IBAction func shareLocation(_ sender: Any) {
        self.shareLocationButton.setTitle("", for: UIControlState.normal)
        shareLocationActivityIndicator.startAnimating()
        if let expectedPlace = HyperTrackAppService.sharedInstance.currentAction?.expectedPlace{
            self.shareLocationActivityIndicator.stopAnimating()
            self.shareLocationButton.setTitle("Share Live Location", for: UIControlState.normal)
            let htActionParams = HyperTrackActionParams()
            htActionParams.expectedPlace = expectedPlace
            htActionParams.type = "visit"
            htActionParams.collectionId = (HyperTrackAppService.sharedInstance.currentAction?.collectionId)!
            
            HyperTrack.createAndAssignAction(htActionParams, { (action, error) in
                if let error = error {
                    self.showAlert(title: "Error", message: error.errorMessage)
                    return
                }
                if let action = action {
                    if let collectionId = action.collectionId {
                        HyperTrackAppService.sharedInstance.setCurrentCollectionId(collectionId: collectionId)
                        HyperTrackAppService.sharedInstance.setCurrentTrackedAction(action: action)

                        // geofence
                        HyperTrack.startMonitoringForEntryAtPlace(place: expectedPlace,radius:CLLocationDistance(self.monitorRegionRadius),identifier: collectionId)
                        
                    }else{
                        self.showAlert(title: "Error", message: "No collectionId present in action")
                    }
                    self.shareLocationButton.isHidden = true
                    return
                }
            })
        }
    }
    
    
    
    
    func showShareLocationButton(_ sender: Any){
        self.shareLocationButton.isHidden = false
        self.hyperTrackView.bringSubview(toFront: self.shareLocationButton)
    }
    
    func shareLink(action : HyperTrackAction) {
        
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.locale = Locale.init(identifier: "en_US")
        
        if(shareView == nil){
            shareView = Bundle.main.loadNibNamed("CustomShareView", owner: self, options: nil)?.first as? CustomShareView
        }
        
        shareView?.shareDelegate = self
        
        if(action.eta != nil){
            
            let dateString = formatter.string(from: action.eta!)
            
            var etaMinutes = 0.0
            
            let actionDisplay = action.display
            if (actionDisplay != nil) {
                if let duration = actionDisplay!.durationRemaining {
                    let timeRemaining = duration
                    etaMinutes = Double(timeRemaining / 60)
                    shareView?.etaLabel.text = "You're \(Int(etaMinutes)) min away!"
                }
            }
            
            // text to share
            let text = "Will be there by " + dateString + ". See my live location and share yours. "  + action.trackingUrl!
            shareView?.linkText = text
        }
        else{
            shareView?.etaLabel.text = ""
            let text = "See my live location and share yours. " + action.trackingUrl!
            shareView?.linkText = text
        }
        
        
        self.view.addSubview(shareView!)
        
        shareView?.linkLabel.text = action.trackingUrl!
        presentViewAnimatedFromBottom(view: shareView!)
    }
    
    func presentViewAnimatedFromBottom(view : UIView){
        
        view.frame = CGRect(x:0,y:(self.view.frame.height + (view.frame.size.height)),width : self.view.frame.size.width,height:view.frame.size.height)
        UIView.animate(withDuration: 0.3, animations: {
            view.frame = CGRect(x:0,y:(self.view.frame.height-(view.frame.size.height)),width : self.view.frame.size.width,height:view.frame.size.height)
            
        })
    }
    
}

extension ShareVC : CustomShareViewDelegate,MFMessageComposeViewControllerDelegate{
    
    func didClickCloseButton(view : CustomShareView){
        
    }
    func didClickOnShare(view : CustomShareView){
        self.shareView?.removeFromSuperview()
        self.showShareSheetWithText(text: view.linkText!)
    }
    func didClickOnMessenger(view : CustomShareView){
        let urlStr = "fb-messenger://share?link=" +  (view.linkText?.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!)!
        if let url = URL.init(string: urlStr) {
            NSLog(urlStr)
            if(UIApplication.shared.canOpenURL(url)){
                UIApplication.shared.open(url, options: [:], completionHandler: { (shared) in
                })
            }
        }
        
        self.shareView?.removeFromSuperview()
        
    }
    func didClickOnWhatsapp(view : CustomShareView){
        let urlStr = "whatsapp://send?text=" +  (view.linkText?.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!)!
        if let url = URL.init(string: urlStr) {
            if(UIApplication.shared.canOpenURL(url)){
                UIApplication.shared.open(url, options: [:], completionHandler: { (shared) in
                })
            }
        }
        
        self.shareView?.removeFromSuperview()
        
    }
    
    func didClickOnMessages(view : CustomShareView){
        
        if MFMessageComposeViewController.canSendText() == true {
            let messageController = MFMessageComposeViewController()
            messageController.messageComposeDelegate  = self
            messageController.body = view.linkText
            self.present(messageController, animated: true, completion: nil)
        } else {
            //handle text messaging not available
        }
        
        self.shareView?.removeFromSuperview()
        
    }
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult){
        controller.dismiss(animated: true, completion: nil)
    }
    
}


extension ShareVC:ShareLiveLocationDelegate{
    func didClickOnShareLiveLocation(view : ShareLiveLocationView){
        view.shareLocationButton.setTitle("", for: UIControlState.normal)
        view.activityIndicator.startAnimating()
        if let expectedPlace = view.action?.expectedPlace{
            
            let htActionParams = HyperTrackActionParams()
            htActionParams.expectedPlace = expectedPlace
            htActionParams.type = "visit"
            htActionParams.collectionId = (view.action?.collectionId)!
            
            HyperTrack.createAndAssignAction(htActionParams, { (action, error) in
                if let error = error {
                    self.showAlert(title: "Error", message: error.errorMessage)
                    return
                }
                if let action = action {
                    view.removeFromSuperview()
                    if let collectionId = action.collectionId {
                        HyperTrackAppService.sharedInstance.setCurrentCollectionId(collectionId: collectionId)
                        HyperTrackAppService.sharedInstance.setCurrentTrackedAction(action: action)

                        // geofence
                        HyperTrack.startMonitoringForEntryAtPlace(place: expectedPlace,radius:CLLocationDistance(self.monitorRegionRadius),identifier: collectionId)
                        
                        
                    }else{
                        self.showAlert(title: "Error", message: "No collectionId present in action")
                    }
                    
                    self.shareLocationButton.isHidden = true
                    return
                }
            })
        }
        
    }
}


