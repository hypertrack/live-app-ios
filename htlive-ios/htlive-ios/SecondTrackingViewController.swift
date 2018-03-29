//
//  SecondTrackingViewController.swift
//  htlive-ios
//
//  Created by Atul Manwar on 28/03/18.
//  Copyright © 2018 PZRT. All rights reserved.
//

import UIKit
import HyperTrack
import FSCalendar
import MessageUI
import MapKit
import Alamofire

final class SecondTrackingViewController: UIViewController {
    fileprivate var contentView: HTMapContainer!
    fileprivate lazy var liveUseCase = HTLiveTrackingUseCase()

    var collectionId = ""
    
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
    
    fileprivate (set) lazy var crossButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage.getImageFromHTBundle(named: HTConstants.ImageNames.crossButton), for: .normal)
        button.addConstraints([
            NSLayoutConstraint(item: button, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 48),
            NSLayoutConstraint(item: button, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 48),
            ])
        button.layer.cornerRadius = 24
        button.addTarget(self, action: #selector(crossClicked), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        contentView = HTMapContainer(frame: .zero)
        view.addSubview(contentView)
        contentView.edges()
        contentView.cleanUp()
        enableLiveTrackingUseCase()
        contentView.setPrimaryAction(crossButton, anchor: .topLeft)
    }
    
    func crossClicked() {
        contentView.cleanUp()
        dismiss(animated: true, completion: nil)
        liveUseCase.stop()
    }

    fileprivate func enableLiveTrackingUseCase() {
        liveUseCase.isTrackingEnabled = false
        liveUseCase.trackingDelegate = self
        contentView.setBottomViewWithUseCase(liveUseCase)
        startTracking(collectionId: collectionId, useCase: liveUseCase)
    }
    
    fileprivate func startTracking(collectionId: String, useCase: HTLiveTrackingUseCase) {
        guard HyperTrack.getUserId() != nil else {
            return
        }
        if !collectionId.isEmpty {
            useCase.trackActionWithCollectionId(collectionId, pollDuration: useCase.pollDuration, completionHandler: nil)
        } else {
            crossClicked()
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
    
    override func viewWillAppear(_ animated: Bool) {
        self.view.resignFirstResponder()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

extension SecondTrackingViewController {
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

extension SecondTrackingViewController: HTLiveTrackingUseCaseDelegate {
    func showLoader(_ show: Bool) {
        isLoading = show
    }
    
    func shareLiveTrackingDetails(_ url: String, eta: String) {
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view
        activityViewController.excludedActivityTypes = [.print, .assignToContact, .saveToCameraRoll]
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    func shareLiveLocationClicked() {
    }
    
    func liveTrackingEnded(_ collectionId: String) {
        crossClicked()
    }
}

