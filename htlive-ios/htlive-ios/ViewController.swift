//
//  ViewController.swift
//  htlive-ios
//
//  Created by Vibes on 7/4/17.
//  Copyright © 2017 PZRT. All rights reserved.
//

import UIKit
import HyperTrack
import FSCalendar
import MessageUI
import MapKit
import Alamofire

let pink = UIColor(red:1.00, green:0.51, blue:0.87, alpha:1.0)

class ViewController: UIViewController {
    fileprivate var contentView: HTMapContainer!
    
    fileprivate lazy var placelineUseCase: HTPlaceLineUseCase = HTPlaceLineUseCase()
    
//    fileprivate lazy var liveUseCase = HTLiveTrackingUseCase()
    fileprivate lazy var orderUseCase = HTOrderTrackingUseCase()
    fileprivate lazy var summaryUseCase = HTActivitySummaryUseCase()
    fileprivate var actionId: String = ""
    fileprivate let collectionIdKey = "htLiveTrackingCollectionId"
    fileprivate let orderCollectionIdKey = "htOrderTrackingCollectionId"
    fileprivate var collectionId = ""
    fileprivate var sharedCollectionId = ""
    var segments: [HyperTrackActivity] = []
    var placeLine: HyperTrackPlaceline? = nil

    var selectedIndexPath : IndexPath? = nil
    var noResults = false
    let regionRadius: CLLocationDistance = 200

    var annotations = [MKPointAnnotation]()
    var polyLine : MKPolyline?
    var isACellSelected = false
    fileprivate lazy var loaderContainer: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = UIColor.black
        view.alpha = 0.3
        return view
    }()
    
    fileprivate lazy var activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.white)
        activityIndicator.startAnimating()
        return activityIndicator
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        contentView = HTMapContainer(frame: .zero)
        view.addSubview(contentView)
        contentView.edges()
        contentView.cleanUp()
        enableSummaryUseCase()
//        enableOrderTrackingUseCase()
//        enableLiveTrackingUseCase()
//        enablePlacelineUseCase()
//        contentView.setBottomViewWithUseCase(placelineUseCase)
        NotificationCenter.default.addObserver(self, selector: #selector(self.userCreated), name: NSNotification.Name(rawValue:HTLiveConstants.userCreatedNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onForegroundNotification), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onBackgroundNotification), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onLocationUpdate(notification:)), name: NSNotification.Name(rawValue: HTConstants.HTLocationChangeNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(trackUsingUrl), name: NSNotification.Name(rawValue:HTLiveConstants.trackUsingUrl), object: nil)
    }
    
    fileprivate func enablePlacelineUseCase() {
        contentView.setBottomViewWithUseCase(placelineUseCase)
        placelineUseCase.update()
    }
    
    fileprivate func enableOrderTrackingUseCase() {
        orderUseCase.trackingDelegate = self
        contentView.setBottomViewWithUseCase(orderUseCase)
        if let collectionId = UserDefaults.standard.string(forKey: orderCollectionIdKey), !collectionId.isEmpty {
            self.collectionId = collectionId
            startOrderTracking(collectionId: collectionId)
        }
    }
    
//    fileprivate func enableLiveTrackingUseCase() {
//        liveUseCase.trackingDelegate = self
//        contentView.setBottomViewWithUseCase(liveUseCase)
//        if let collectionId = UserDefaults.standard.string(forKey: collectionIdKey), !collectionId.isEmpty {
//            self.collectionId = collectionId
//            startTracking(collectionId: collectionId, useCase: liveUseCase)
//        }
//    }
    
    fileprivate func enableSummaryUseCase() {
        summaryUseCase.trackingDelegate = self
        contentView.setBottomViewWithUseCase(summaryUseCase)
        summaryUseCase.update()
    }

    fileprivate func startTracking(collectionId: String, useCase: HTLiveTrackingUseCase) {
        guard HyperTrack.getUserId() != nil else {
            return
        }
        if !collectionId.isEmpty {
            useCase.trackActionWithCollectionId(collectionId, pollDuration: useCase.pollDuration, completionHandler: nil)
        } else {
            let actionParams = HyperTrackActionParams.default
            if !sharedCollectionId.isEmpty {
                actionParams.collectionId = sharedCollectionId
            }
            HyperTrack.createAndAssignAction(actionParams, { [unowned self] (response, error) in
                if let collectionId = response?.collectionId {
                    self.collectionId = collectionId
                    useCase.trackActionWithCollectionId(collectionId, pollDuration: useCase.pollDuration, completionHandler: nil)
                    UserDefaults.standard.set(collectionId, forKey: self.collectionIdKey)
                    UserDefaults.standard.synchronize()
                }
            })
        }
    }
    
    fileprivate func startOrderTracking(collectionId: String) {
        guard HyperTrack.getUserId() != nil else {
            return
        }
//        HyperTrack.startTracking()
        if !collectionId.isEmpty {
            orderUseCase.trackActionWithCollectionId(collectionId, pollDuration: orderUseCase.pollDuration, completionHandler: nil)
        } else {
            let actionParams = HyperTrackActionParams.default
            let expectedPlace = HyperTrackPlace()
            _ = expectedPlace.setLocation(coordinates: CLLocationCoordinate2D(latitude: 12.9296494, longitude: 77.6357699))
            expectedPlace.address = "HAL Airport"
            expectedPlace.city = "Bengaluru"
            expectedPlace.country = "India"
            expectedPlace.landmark = "HAL"
            expectedPlace.name = "HAL Airport"
            actionParams.expectedPlace = expectedPlace
            actionParams.lookupId = String(randomStringWithLength(len: 6))
            _ = actionParams.setType(type: "delivery")
            HyperTrack.createAndAssignAction(actionParams, { [unowned self] (response, error) in
                if let collectionId = response?.collectionId {
                    self.collectionId = collectionId
                    self.orderUseCase.trackActionWithCollectionId(collectionId, pollDuration: self.orderUseCase.pollDuration, completionHandler: nil)
                    UserDefaults.standard.set(collectionId, forKey: self.collectionIdKey)
                    UserDefaults.standard.synchronize()
                }
            })
        }
    }
    
    fileprivate var isLoading: Bool = false {
        didSet {
            guard let window = view.window else { return }
            loaderContainer.removeFromSuperview()
            activityIndicator.removeFromSuperview()
            if isLoading {
                loaderContainer.frame = window.bounds
                activityIndicator.center = window.center
                window.addSubview(loaderContainer)
                window.addSubview(activityIndicator)
            }
        }
    }
    
    func trackUsingUrl(notification: Notification) {
        guard let url = notification.object as? String else { return }
        summaryUseCase.enabeLiveTracking()
        summaryUseCase.liveUC.trackActionWithShortCodes([url]) { [unowned self] (response, error) in
            if let data = response {
                guard let first = data.first else { return }
                self.sharedCollectionId = first.collectionId
                self.summaryUseCase.liveUC.trackActionWithCollectionId(first.collectionId, pollDuration: self.summaryUseCase.liveUC.pollDuration, completionHandler: nil)
            } else {
                let ac = UIAlertController(title: "Error", message: error?.displayErrorMessage, preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(ac, animated: true, completion: nil)
            }
        }
//        HyperTrack.trackActionFor(shortCode: url) { [unowned self] (action, error) in
//            if let collectionId = action?.collectionId {
//                self.startTracking(collectionId: collectionId)
//            }
//        }
    }
    
    func onLocationUpdate(notification: Notification) {
        setCurrentLocation()
    }

    func onLiveLocationButtonClick(sender: UIButton) {
        let reachabilityManager = Alamofire.NetworkReachabilityManager(host: "www.google.com")
        if (reachabilityManager?.isReachable)! {
            let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            let liveLocationController = storyboard.instantiateViewController(withIdentifier: "ShareVC") as! ShareVC
            self.present(liveLocationController, animated: true) {
                NSLog("presented")
            }
        } else{
            showAlert(title: "Internet not available", message: "To share live location, Please check your internet connectivity and try again")
        }
    }
    
    
    fileprivate func showAlert(title: String?, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let ok : UIAlertAction = UIAlertAction.init(title: "OK", style: .cancel) { (action) in
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
    
    func onForegroundNotification(_ notification: Notification){
        summaryUseCase.placelineUC.update()
//        placelineUseCase.update()
//        isACellSelected = false
        //TODO: v2
//        contentView.showsUserLocation = true
    }
    
    func onBackgroundNotification(_ notification: Notification){
        //TODO: v2
//       contentView.showsUserLocation = false
    }
    func userCreated(_ notification: Notification) {
//        placelineUseCase.update()
    }

    override func viewWillAppear(_ animated: Bool) {
        self.view.resignFirstResponder()
        //TODO: v2
//        contentView.showsUserLocation = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.setCurrentLocation()
    }
    
    func setCurrentLocation(){
        if !isACellSelected {
//            HyperTrack.getCurrentLocation { (clLocation, error) in
//                if let location  = clLocation{
//                    let region = MKCoordinateRegionMake((location.coordinate),MKCoordinateSpanMake(0.005, 0.005))
//                    self.contentView.setRegion(region, animated: true)
//                }else{
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
//                        if self.segments.count > 0 {
//                            self.tableView(self.placeLineTable, didSelectRowAt: IndexPath.init(row: 0, section: 0))
//                        }
//                    }
//                }
//            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
}

extension ViewController {
    func onTap(sender:UITapGestureRecognizer) {
      shareLogs()
    }
    
    func shareLogs() {
        let path = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)
        if let baseDir = path.first {
            if let baseURL = NSURL(fileURLWithPath: baseDir).appendingPathComponent("Logs") {
                let enumerator = FileManager.default.enumerator(at: baseURL,
                                                                includingPropertiesForKeys: [],
                                                                options: [.skipsHiddenFiles], errorHandler: { (url, error) -> Bool in
                                                                    print("directoryEnumerator error at \(url): ", error)
                                                                    return true
                })!
                
                var urlPaths = [URL]()
                for case let fileURL as URL in enumerator {
                    
                        if NSData(contentsOfFile: fileURL.path) != nil {
                            urlPaths.append(fileURL)
                            let activityController = UIActivityViewController(activityItems: urlPaths, applicationActivities: nil)
                            self.present(activityController, animated: true, completion: nil)
                            break
                            
                        }
                }
            
            }
        }
    }
}

extension ViewController: HTLiveTrackingUseCaseDelegate {
    func showLoader(_ show: Bool) {
        isLoading = show
    }
    
    func shareLiveTrackingDetails(_ text: String) {
        let activityViewController = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view
        activityViewController.excludedActivityTypes = [.print, .assignToContact, .saveToCameraRoll]
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    func shareLiveLocationClicked() {
        if let collectionId = UserDefaults.standard.string(forKey: collectionIdKey), !collectionId.isEmpty {
            self.collectionId = collectionId
            startTracking(collectionId: collectionId, useCase: summaryUseCase.liveUC)
        } else {
            startTracking(collectionId: "", useCase: summaryUseCase.liveUC)
        }
    }
    
    func liveTrackingEnded(_ collectionId: String) {
//        enableSummaryUseCase()
        UserDefaults.standard.set("", forKey: self.collectionIdKey)
//        HyperTrack.stopTracking()
    }
}

extension ViewController: HTOrderTrackingUseCaseDelegate {
    func placeOrderClicked() {
        startOrderTracking(collectionId: "")
    }
    
    func orderTrackingEnded(_ collectionId: String) {
        UserDefaults.standard.set("", forKey: self.orderCollectionIdKey)
//        HyperTrack.stopTracking()
    }
}
