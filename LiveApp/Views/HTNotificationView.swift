//
//  NotificationView.swift
//  LiveApp
//
//  Created by Dmytro Shapovalov on 6/28/19.
//  Copyright © 2019 Dmytro Shapovalov. All rights reserved.
//

import UIKit

class HTNotificationView: UIView {

    var errorText: String? {
        didSet {
            self.errorLabel.text = errorText
        }
    }
    
    private let errorLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(
            ofSize: 14,
            weight: UIFont.Weight.medium)
        label.textColor = .white
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpNotificationView()
        self.backgroundColor = UIColor("#3391FF")
        self.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setUpNotificationView() {
        self.addSubview(errorLabel)
        
        errorLabel.topAnchor.constraint(
            equalTo:self.topAnchor,
            constant: 6).isActive = true
        errorLabel.leftAnchor.constraint(
            equalTo:self.leftAnchor,
            constant: 15).isActive = true
        errorLabel.rightAnchor.constraint(
            equalTo:self.rightAnchor,
            constant: -15).isActive = true
        errorLabel.bottomAnchor.constraint(
            equalTo:self.bottomAnchor,
            constant: -6).isActive = true
        self.isHidden = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(openSettings))
        self.addGestureRecognizer(tapGesture)
    }
    
    @objc private func openSettings() {
        if let url = URL.init(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showNotificationView(errorText: String) {
        DispatchQueue.main.async {
            self.errorText = errorText
            self.isHidden = false
        }
    }
    
    func hideNotificationView() {
        DispatchQueue.main.async {
            self.isHidden = true
        }
    }
}
