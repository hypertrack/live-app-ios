//
//  ViewController.swift
//  htlive-ios
//
//  Created by Vibes on 7/4/17.
//  Copyright © 2017 PZRT. All rights reserved.
//

import UIKit
import HyperTrack
import MessageUI
import MapKit
import Alamofire

let pink = UIColor(red:1.00, green:0.51, blue:0.87, alpha:1.0)

class ViewController: UIViewController {
    fileprivate var contentView: HTMapContainer!
    
    fileprivate lazy var summaryUseCase = HTActivitySummaryUseCase()
    fileprivate var actionId: String = ""
    fileprivate let collectionIdKey = "htLiveTrackingCollectionId"
    fileprivate let orderCollectionIdKey = "htOrderTrackingCollectionId"
    fileprivate var collectionId = ""
    fileprivate var sharedCollectionId = ""

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
        HyperTrack.requestAlwaysLocationAuthorization { (_) in
            
        }
        contentView.edges()
        contentView.cleanUp()
        enableSummaryUseCase()
        NotificationCenter.default.addObserver(self, selector: #selector(self.onForegroundNotification), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(trackUsingUrl), name: NSNotification.Name(rawValue:HTLiveConstants.trackUsingUrl), object: nil)
    }
    
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
            let actionParams = HTActionParams.default
            if !sharedCollectionId.isEmpty {
                actionParams.collectionId = sharedCollectionId
            }
            HyperTrack.createAndAssignAction(actionParams, { [weak self] (response, error) in
                guard let `self` = self else { return }
                if let collectionId = response?.collectionId {
                    self.collectionId = collectionId
                    useCase.trackActionWithCollectionId(collectionId, pollDuration: useCase.pollDuration, completionHandler: nil)
                    UserDefaults.standard.set(collectionId, forKey: self.collectionIdKey)
                    UserDefaults.standard.synchronize()
                }
            })
        }
    }
    
    fileprivate func startMockTracking() {
        let expectedPlace = HTPlaceBuilder()
            .setCity("Bengaluru")
            .setCountry("India")
            .setAddress("HAL Airport")
            .setLandmark("HAL")
            .setName("HAL Airport")
            .setLocation(CLLocationCoordinate2D(latitude: 12.9296494, longitude: 77.6357699))
            .setId(UUID().uuidString)
            .build()
        let actionParams = HTActionParams.default.setUserId(userId: HyperTrack.getUserId() ?? "").setType(type: "visit").setExpectedPlace(expectedPlace: expectedPlace)
        HyperTrack.createMockAction(nil, nil, actionParams, completionHandler: { [weak self] (response, error) in
            if let `self` = self, let id = response?.id {
                self.summaryUseCase.liveUC.trackActionWithIds([id], pollDuration: self.summaryUseCase.liveUC.pollDuration, completionHandler: nil)
            }
        })
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
            summaryUseCase.liveUC.trackActionWithShortCodes([url]) { [weak self] (response, error) in
                guard let `self` = self else { return }
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
            summaryUseCase.liveUC.trackActionWithShortCodes([url]) { [weak self] (response, error) in
                if let data = response, let `self` = self {
                    guard let first = data.first else { return }
                    self.sharedCollectionId = first.collectionId
                    self.startTracking(collectionId: first.collectionId, useCase: self.summaryUseCase.liveUC)
                } else {
                    self?.showError(title: "Error", message: error?.displayErrorMessage)
                }
            }
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
        summaryUseCase.update()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.view.resignFirstResponder()
        contentView.showCurrentLocation = true
        contentView.cleanUp()
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

extension ViewController: HTActivitySummaryUseCaseDelegate {    
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
//        startMockTracking()
        if let collectionId = UserDefaults.standard.string(forKey: collectionIdKey), !collectionId.isEmpty {
            self.collectionId = collectionId
            startTracking(collectionId: collectionId, useCase: summaryUseCase.liveUC)
        } else {
            startTracking(collectionId: "", useCase: summaryUseCase.liveUC)
        }
    }
    
    func liveTrackingEnded(_ type: HTTrackWithTypeData) {
        sharedCollectionId = ""
        self.collectionId = ""
        UserDefaults.standard.set("", forKey: self.collectionIdKey)
    }
}

/// Ignore
//    fileprivate lazy var placelineUseCase: HTPlaceLineUseCase = HTPlaceLineUseCase()
//    fileprivate lazy var liveUseCase = HTLiveTrackingUseCase()
//    fileprivate lazy var orderUseCase = HTOrderTrackingUseCase()
//    fileprivate func enablePlacelineUseCase() {
//        contentView.setBottomViewWithUseCase(placelineUseCase)
//        placelineUseCase.update()
//    }

//    fileprivate func enableOrderTrackingUseCase() {
//        orderUseCase.trackingDelegate = self
//        contentView.setBottomViewWithUseCase(orderUseCase)
//        if let collectionId = UserDefaults.standard.string(forKey: orderCollectionIdKey), !collectionId.isEmpty {
//            self.collectionId = collectionId
//            startOrderTracking(collectionId: collectionId)
//        }
//    }

//    fileprivate func enableLiveTrackingUseCase() {
//        liveUseCase.trackingDelegate = self
//        contentView.setBottomViewWithUseCase(liveUseCase)
//        if let collectionId = UserDefaults.standard.string(forKey: collectionIdKey), !collectionId.isEmpty {
//            self.collectionId = collectionId
//            startTracking(collectionId: collectionId, useCase: liveUseCase)
//        }
//    }

//    fileprivate func startOrderTracking(collectionId: String) {
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
//            HyperTrack.createAndAssignAction(actionParams, { [weak self] (response, error) in
//                if let collectionId = response?.collectionId {
//                    self.collectionId = collectionId
//                    self.orderUseCase.trackActionWithCollectionId(collectionId, pollDuration: self.orderUseCase.pollDuration, completionHandler: nil)
//                    UserDefaults.standard.set(collectionId, forKey: self.collectionIdKey)
//                    UserDefaults.standard.synchronize()
//                }
//            })
//        }
//    }

//extension ViewController: HTOrderTrackingUseCaseDelegate {
//    func placeOrderClicked() {
//        startOrderTracking(collectionId: "")
//    }
//
//    func orderTrackingEnded(_ type: HTTrackWithTypeData) {
//        UserDefaults.standard.set("", forKey: self.orderCollectionIdKey)
//    }
//}

