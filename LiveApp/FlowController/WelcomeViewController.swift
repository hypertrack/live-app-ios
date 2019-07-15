//
//  WelcomeViewController.swift
//  LiveApp
//
//  Created by Dmytro Shapovalov on 6/25/19.
//  Copyright © 2019 Dmytro Shapovalov. All rights reserved.
//

import UIKit

fileprivate let welcomeStateKey = "WelcomeStateKey"

class WelcomeViewController: BaseFlowController {
    private var currentState: Bool = false {
        didSet {
            UserDefaults.standard.set(
                currentState, forKey: welcomeStateKey)
        }
    }
    private let titleLabel: UILabel = {
        let label = UILabel.titleLabel
        label.text = String.localize(key: "WELCOME_TITLE_1")
        return label
    }()
    private let image: UIImageView = {
        let image = UIImageView.baseImageView
        image.image = UIImage(named: "illustrations")
        return image
    }()
    private let stepOneLabel: UILabel = {
        let label = UILabel.baseLabel
        label.text = String.localize(key: "WELCOME_STEP_1")
        return label
    }()
    private let stepTwoLabel: UILabel = {
        let label = UILabel.baseLabel
        label.text = String.localize(key: "WELCOME_STEP_2")
        return label
    }()
    private let stepThreeLabel: UILabel = {
        let label = UILabel.baseLabel
        label.text = String.localize(key: "WELCOME_STEP_3")
        return label
    }()
    private let button: UIButton = {
        let btn = UIButton.baseGreen
        btn.setTitle(String.localize(
            key: "WELCOME_BUTTON_TITLE"), for: .normal)
        btn.addTarget(
            self,
            action: #selector(buttonClicked),
            for: .touchUpInside)
        return btn
    }()
    
    convenience init() {
        self.init(nibName:nil, bundle:nil)
        currentState = UserDefaults.standard.bool(
            forKey: welcomeStateKey)
        isAnimationNeeded = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        createUI()
    }
    
    private func createUI() {
        
        self.navigationController?.navigationBar.isHidden = true
        
        view.backgroundColor = .white
        view.addSubview(titleLabel)
        view.addSubview(image)
        let viewLabelContainer = UIView()
        viewLabelContainer.translatesAutoresizingMaskIntoConstraints = false
        viewLabelContainer.addSubview(stepOneLabel)
        viewLabelContainer.addSubview(stepTwoLabel)
        viewLabelContainer.addSubview(stepThreeLabel)
        view.addSubview(viewLabelContainer)
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
        
        viewLabelContainer.topAnchor.constraint(
            equalTo:image.bottomAnchor,
            constant: 30).isActive = true
        viewLabelContainer.centerXAnchor.constraint(
            equalTo: button.centerXAnchor).isActive = true
        viewLabelContainer.heightAnchor.constraint(
            equalToConstant: 19).isActive = true
        
        stepOneLabel.topAnchor.constraint(
            equalTo:viewLabelContainer.bottomAnchor,
            constant: 0).isActive = true
        stepOneLabel.leftAnchor.constraint(
            equalTo:viewLabelContainer.leftAnchor,
            constant:0).isActive = true
        stepOneLabel.rightAnchor.constraint(
            equalTo:viewLabelContainer.rightAnchor,
            constant:0).isActive = true

        stepTwoLabel.topAnchor.constraint(
            equalTo:stepOneLabel.bottomAnchor,
            constant: 5).isActive = true
        stepTwoLabel.leftAnchor.constraint(
            equalTo:viewLabelContainer.leftAnchor,
            constant:0).isActive = true
        stepTwoLabel.rightAnchor.constraint(
            equalTo:viewLabelContainer.rightAnchor,
            constant:0).isActive = true

        stepThreeLabel.topAnchor.constraint(
            equalTo:stepTwoLabel.bottomAnchor,
            constant: 5).isActive = true
        stepThreeLabel.leftAnchor.constraint(
            equalTo:viewLabelContainer.leftAnchor,
            constant:0).isActive = true
        stepThreeLabel.rightAnchor.constraint(
            equalTo:viewLabelContainer.rightAnchor,
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
    
    @objc func buttonClicked() {
        currentState = true
        interactorDelegate?.haveFinishedFlow(
            sender: self)
    }
    
    override func isFlowCompleted() -> Bool {
        return currentState
    }
}
