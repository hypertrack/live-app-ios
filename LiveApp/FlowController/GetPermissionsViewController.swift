//
//  GetPermissionsViewController.swift
//  LiveApp
//
//  Created by Dmytro Shapovalov on 6/25/19.
//  Copyright © 2019 Dmytro Shapovalov. All rights reserved.
//

import UIKit
import HyperTrack

class GetPermissionsViewController: BaseFlowController {
    private var appState: AppState?
    private let titleLabel: UILabel = {
        let label = UILabel.titleLabel
        label.text = String.localize(key: "PERMISSIONS_TITLE_1")
        return label
    }()
    private let image: UIImageView = {
        let image = UIImageView.baseImageView
        image.image = UIImage(named: "illustrations")
        return image
    }()
    private let subTitleLabel: UILabel = {
        let label = UILabel.subTitleLabel
        label.text = String.localize(key: "PERMISSIONS_SUBTITLE_1")
        label.font = UIFont.systemFont(
            ofSize: 14,
            weight: UIFont.Weight.medium)
        label.numberOfLines = 3
        return label
    }()
    private let button: UIButton = {
        let btn = UIButton.baseGreen
        btn.setTitle(String.localize(key: "PERMISSIONS_BUTTON_TITLE"),
                     for: .normal)
        btn.addTarget(
            self,
            action: #selector(buttonClicked),
            for: .touchUpInside)
        return btn
    }()
    
    convenience init(appState: AppState) {
        self.init(nibName:nil, bundle:nil)
        self.appState = appState
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        createUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addObservers()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    private func addObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(hyperTrackStartedTracking),
            name: NSNotification.Name.HyperTrackStartedTracking,
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(getHyperTrackError(_:)),
            name: Notification.Name.getErrorNotification,
            object: nil)
    }
    
    private func createUI() {
        
        self.navigationController?.navigationBar.isHidden = true
        view.backgroundColor = .white
        view.addSubview(titleLabel)
        view.addSubview(image)
        view.addSubview(subTitleLabel)
        view.addSubview(button)
        
        titleLabel.topAnchor.constraint(
            equalTo:view.topAnchor,
            constant: view.frame.height * 0.1256).isActive = true
        titleLabel.leftAnchor.constraint(
            equalTo:view.leftAnchor,
            constant:37).isActive = true
        titleLabel.rightAnchor.constraint(
            equalTo:view.rightAnchor,
            constant:-37).isActive = true
        
        image.topAnchor.constraint(
            equalTo:titleLabel.bottomAnchor,
            constant:30).isActive = true
        image.leftAnchor.constraint(
            equalTo:view.leftAnchor,
            constant:70).isActive = true
        image.rightAnchor.constraint(
            equalTo:view.rightAnchor,
            constant:-70).isActive = true
        image.heightAnchor.constraint(
            equalTo: image.widthAnchor,
            multiplier: 1.0/1.0).isActive = true
        
        subTitleLabel.topAnchor.constraint(
            equalTo:image.bottomAnchor,
            constant: 30).isActive = true
        subTitleLabel.leftAnchor.constraint(
            equalTo:button.leftAnchor,
            constant:0).isActive = true
        subTitleLabel.rightAnchor.constraint(
            equalTo:button.rightAnchor,
            constant:0).isActive = true
        
        button.bottomAnchor.constraint(
            equalTo:view.safeAreaLayoutGuide.bottomAnchor,
            constant: -28).isActive = true
        button.leftAnchor.constraint(
            equalTo:view.leftAnchor,
            constant:28).isActive = true
        button.rightAnchor.constraint(
            equalTo:view.rightAnchor,
            constant:-28).isActive = true
        button.heightAnchor.constraint(
            equalToConstant: 40).isActive = true
    }
    
    @objc func hyperTrackStartedTracking() {
        NotificationCenter.default.post(
            name: Notification.Name.flowComplitedNotification,
            object: nil)
        NotificationCenter.default.post(
            name: Notification.Name.updateTrackingStateNotification,
            object: nil,
            userInfo: [userTrackingStateKey: true])
        interactorDelegate?.haveFinishedFlow(sender: self)
    }

    @objc func buttonClicked() {
        guard let appState = self.appState,
            let pk = appState.pk_key else { return }
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.appProvider?.canSetupHyperTrack(pk,
                                                    true,
                                                    true)
    }
    
    override func isFlowCompleted() -> Bool {
        return appState?.isFlowComplited ?? false
    }
}

extension GetPermissionsViewController {
    @objc private func getHyperTrackError(_ notif: Notification) {
        hyperTrackStartedTracking()
    }
}
