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
    
//    fileprivate lazy var placelineUseCase: HTPlaceLineUseCase = HTPlaceLineUseCase()
    fileprivate lazy var calendar: FSCalendar = {
        let calendar = FSCalendar(frame: .zero)
        calendar.dataSource = self
        calendar.delegate = self
        calendar.backgroundColor = .white
        return calendar
    }()
//    fileprivate lazy var liveUseCase = HTLiveTrackingUseCase()
//    fileprivate lazy var orderUseCase = HTOrderTrackingUseCase()
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
//        contentView.setBottomViewWithUseCase(placelineUseCase)
//        placelineUseCase.update()
    }
    
    fileprivate func enableOrderTrackingUseCase() {
//        orderUseCase.trackingDelegate = self
//        contentView.setBottomViewWithUseCase(orderUseCase)
//        if let collectionId = UserDefaults.standard.string(forKey: orderCollectionIdKey), !collectionId.isEmpty {
//            self.collectionId = collectionId
//            startOrderTracking(collectionId: collectionId)
//        }
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
        summaryUseCase.activityDelegate = self
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
//        guard HyperTrack.getUserId() != nil else {
//            return
//        }
//        if !collectionId.isEmpty {
//            orderUseCase.trackActionWithCollectionId(collectionId, pollDuration: orderUseCase.pollDuration, completionHandler: nil)
//        } else {
//            let actionParams = HyperTrackActionParams.default
//            let expectedPlace = HyperTrackPlace()
//            _ = expectedPlace.setLocation(coordinates: CLLocationCoordinate2D(latitude: 12.9296494, longitude: 77.6357699))
//            expectedPlace.address = "HAL Airport"
//            expectedPlace.city = "Bengaluru"
//            expectedPlace.country = "India"
//            expectedPlace.landmark = "HAL"
//            expectedPlace.name = "HAL Airport"
//            actionParams.expectedPlace = expectedPlace
//            actionParams.lookupId = String(randomStringWithLength(len: 6))
//            _ = actionParams.setType(type: "delivery")
//            HyperTrack.createAndAssignAction(actionParams, { [unowned self] (response, error) in
//                if let collectionId = response?.collectionId {
//                    self.collectionId = collectionId
//                    self.orderUseCase.trackActionWithCollectionId(collectionId, pollDuration: self.orderUseCase.pollDuration, completionHandler: nil)
//                    UserDefaults.standard.set(collectionId, forKey: self.collectionIdKey)
//                    UserDefaults.standard.synchronize()
//                }
//            })
//        }
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
    
    fileprivate func showError(title: String, message: String?) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(ac, animated: true, completion: nil)
    }
    
    func trackUsingUrl(notification: Notification) {
        guard let url = notification.object as? String else { return }
        if let collectionId = UserDefaults.standard.string(forKey: collectionIdKey), !collectionId.isEmpty {
            summaryUseCase.liveUC.trackActionWithShortCodes([url]) { [unowned self] (response, error) in
                if let data = response {
                    guard let first = data.first else { return }
                    let vc = SecondTrackingViewController(nibName: nil, bundle: nil)
                    vc.collectionId = first.collectionId
                    vc.modalPresentationStyle = .overCurrentContext
                    vc.modalTransitionStyle = .coverVertical
                    self.present(vc, animated: true, completion: nil)
                } else {
                    self.showError(title: "Error", message: error?.displayErrorMessage)
                }
            }
        } else {
            summaryUseCase.enabeLiveTracking()
            summaryUseCase.liveUC.trackActionWithShortCodes([url]) { [unowned self] (response, error) in
                if let data = response {
                    guard let first = data.first else { return }
                    self.sharedCollectionId = first.collectionId
                    self.startTracking(collectionId: first.collectionId, useCase: self.summaryUseCase.liveUC)
                } else {
                    self.showError(title: "Error", message: error?.displayErrorMessage)
                }
            }
        }
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
        contentView.showCurrentLocation = true
        contentView.cleanUp()
        //TODO: v2
//        contentView.showsUserLocation = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.setCurrentLocation()
    }
    
    func setCurrentLocation(){
        if !isACellSelected {
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

extension ViewController: FSCalendarDelegate {
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        summaryUseCase.placelineUC.setDate(date)
        calendar.removeFromSuperview()
    }
}

extension ViewController: FSCalendarDataSource {
    func minimumDate(for calendar: FSCalendar) -> Date {
        return (Date() - 86400 * 30)
    }
    
    func maximumDate(for calendar: FSCalendar) -> Date {
        return Date()
    }
}

extension ViewController: HTActivitySummaryUseCaseDelegate {
    func openCalendar(_ open: Bool, selectedDate: Date) {
        if open {
            view.addSubview(calendar)
            calendar.translatesAutoresizingMaskIntoConstraints = false
            view.addConstraints([
                NSLayoutConstraint(item: calendar, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 0),
                NSLayoutConstraint(item: calendar, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: 0),
                NSLayoutConstraint(item: calendar, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 30),
                ])
            calendar.removeConstraints(calendar.constraints)
            calendar.addConstraints([
                NSLayoutConstraint(item: calendar, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 300),
                ])

        } else {
            calendar.removeFromSuperview()
        }
    }
    
    func showLoader(_ show: Bool) {
        isLoading = show
    }
    
    func shareLiveTrackingDetails(_ url: String, eta: String) {
        let shareText = eta.isEmpty ? ("See my live location and share yours. " + url) : ("Will be there by " + eta + ". See my live location and share yours. "  + url)
        let activityViewController = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
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
        sharedCollectionId = ""
        self.collectionId = ""
        UserDefaults.standard.set("", forKey: self.collectionIdKey)
    }
}

extension ViewController: HTOrderTrackingUseCaseDelegate {
    func placeOrderClicked() {
        startOrderTracking(collectionId: "")
    }
    
    func orderTrackingEnded(_ collectionId: String) {
        UserDefaults.standard.set("", forKey: self.orderCollectionIdKey)
    }
}
