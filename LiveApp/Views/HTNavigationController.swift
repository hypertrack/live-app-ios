//
//  HTNavigationController.swift
//  LiveApp
//
//  Created by Dmytro Shapovalov on 6/26/19.
//  Copyright © 2019 Dmytro Shapovalov. All rights reserved.
//

import UIKit

class HTNavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        configure()
    }
    
    private func configure() {
        self.interactivePopGestureRecognizer?.isEnabled = false
    }
}
