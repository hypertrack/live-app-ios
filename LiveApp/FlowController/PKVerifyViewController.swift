//
//  PKVerifyViewController.swift
//  LiveApp
//
//  Created by Dmytro Shapovalov on 6/25/19.
//  Copyright © 2019 Dmytro Shapovalov. All rights reserved.
//

import UIKit
import HyperTrack

fileprivate let iPhoneSEScreenWidth: CGFloat = 320.0

class PKVerifyViewController: BaseFlowController {
    private var appState: AppState?
    var publishableKey: String = ""
    private let titleLabel: UILabel = {
        let label = UILabel.baseLabel
        label.text = String.localize(key: "PKVERIFY_TITLE")
        return label
    }()
    private let subTitleLabel: UILabel = {
        let label = UILabel.subTitleLabel
        label.text = String.localize(key: "PKVERIFY_SUBTITLE")
        return label
    }()
    private let textView: UITextView = {
        let textView = UITextView.baseTextView
        return textView
    }()
    private let tipsLabel: UILabel = {
        let label = UILabel.tipsLabel
        label.text = String.localize(key: "PKVERIFY_TIPS")
        return label
    }()
    private let button: UIButton = {
        let btn = UIButton.baseGreen
        btn.setTitle(String.localize(key: "PKVERIFY_BUTTON_TITLE"),
                     for: .normal)
        btn.isEnabled = false
        btn.addTarget(
            self,
            action: #selector(buttonClicked),
            for: .touchUpInside)
        return btn
    }()
    
    convenience init(appState: AppState) {
        self.init(nibName:nil, bundle:nil)
        self.appState = appState
        self.publishableKey = appState.pk_key ?? ""
        textView.delegate = self
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
            selector: #selector(hyperTrackAuthorized),
            name: NSNotification.Name.HyperTrackHasInitialized,
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(getHyperTrackError(_:)),
            name: Notification.Name.getErrorNotification,
            object: nil)
    }
    
    private func createUI() {
        
        self.navigationController?.navigationBar.isHidden = false
        self.navigationItem.setHidesBackButton(
            true,
            animated:false)
        self.title = NSLocalizedString(
            "PKVERIFY_NAVIGATION_TITLE",
            comment: "")
        self.view.backgroundColor = .white
        
        let viewContainer = UIView()
        viewContainer.translatesAutoresizingMaskIntoConstraints = false
        viewContainer.addSubview(titleLabel)
        viewContainer.addSubview(subTitleLabel)
        viewContainer.addSubview(textView)
        viewContainer.addSubview(tipsLabel)
        view.addSubview(viewContainer)
        view.addSubview(button)
        
        viewContainer.topAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.topAnchor,
            constant:0).isActive = true
        viewContainer.leftAnchor.constraint(
            equalTo:view.leftAnchor,
            constant:0).isActive = true
        viewContainer.rightAnchor.constraint(
            equalTo:view.rightAnchor,
            constant:0).isActive = true
        
        titleLabel.topAnchor.constraint(
            equalTo:viewContainer.topAnchor,
            constant: 21).isActive = true
        titleLabel.leftAnchor.constraint(
            equalTo:viewContainer.leftAnchor,
            constant:27).isActive = true
        titleLabel.rightAnchor.constraint(
            equalTo:viewContainer.rightAnchor,
            constant:-27).isActive = true
        
        subTitleLabel.topAnchor.constraint(
            equalTo:titleLabel.bottomAnchor,
            constant: 5).isActive = true
        subTitleLabel.leftAnchor.constraint(
            equalTo:viewContainer.leftAnchor,
            constant:27).isActive = true
        subTitleLabel.rightAnchor.constraint(
            equalTo:viewContainer.rightAnchor,
            constant:-27).isActive = true
        
        textView.topAnchor.constraint(
            equalTo:subTitleLabel.bottomAnchor,
            constant: 16).isActive = true
        textView.leftAnchor.constraint(
            equalTo:viewContainer.leftAnchor,
            constant:27).isActive = true
        textView.rightAnchor.constraint(
            equalTo:viewContainer.rightAnchor,
            constant:-27).isActive = true
        textView.heightAnchor.constraint(
            equalToConstant: 140).isActive = true
        
        tipsLabel.topAnchor.constraint(
            equalTo:textView.bottomAnchor,
            constant: 5).isActive = true
        tipsLabel.leftAnchor.constraint(
            equalTo:viewContainer.leftAnchor,
            constant:27).isActive = true
        tipsLabel.rightAnchor.constraint(
            equalTo:viewContainer.rightAnchor,
            constant:-27).isActive = true
        tipsLabel.bottomAnchor.constraint(
            equalTo:viewContainer.bottomAnchor,
            constant: -30).isActive = true
        
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
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    @objc func buttonClicked() {
        publishableKey = textView.text
        verify(publishableKey)
    }
    
    override func isFlowCompleted() -> Bool {
        return !publishableKey.isEmpty
    }
    
    private func verify(_ publishableKey: String) {
        HTActivityIndicatorView.startAnimatingOnView()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.appProvider?.canSetupHyperTrack(publishableKey,
                                                    false,
                                                    false)
    }
}

extension PKVerifyViewController {
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc func keyboardWillShow(_ notification: NSNotification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
            view.frame.width > iPhoneSEScreenWidth {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            self.button.frame.origin.y = self.view.frame.height - (28 + self.button.frame.height + keyboardRectangle.height)
        }
    }
    
    @objc func keyboardWillHide(_ notification: NSNotification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
            view.frame.width > iPhoneSEScreenWidth {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            self.button.frame.origin.y += keyboardHeight
        }
    }
}

extension PKVerifyViewController {
    @objc func getHyperTrackError(_ notif: Notification) {
        guard let error = notif.userInfo?[errorKey] as? HyperTrackCriticalError else { return }
        HTActivityIndicatorView.stopAnimationOnView()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.displayError(error, alertTitle: "PKVERIFY_ALERT_TITLE")
    }
    
    @objc func hyperTrackAuthorized() {
        HTActivityIndicatorView.stopAnimationOnView()
        NotificationCenter.default.post(
            name: Notification.Name.updatePKNotification,
            object: nil,
            userInfo: [notifyPublishableKey: publishableKey])
        interactorDelegate?.haveFinishedFlow(sender: self)
    }
}

extension PKVerifyViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        if textView.text.count == 0 {
            self.button.isEnabled = false
        } else {
            self.button.isEnabled = true
        }
    }
    
    func textView(_ textView: UITextView,
                  shouldChangeTextIn range: NSRange,
                  replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            buttonClicked()
            return false
        }
        return true
    }
}
