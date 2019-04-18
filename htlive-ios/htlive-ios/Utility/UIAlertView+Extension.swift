//
//  UIAlertView+Extension.swift
//  Meta-iPhone
//
//  Created by Ulhas Mandrawadkar on 22/02/16.
//  Copyright © 2016 HyperTrack, Inc. All rights reserved.
//

import UIKit

extension UIAlertController {
    static func alert(title: String, message: String, action: String) -> UIAlertController {
        let alert: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let ok: UIAlertAction = UIAlertAction.init(title: action, style: .cancel, handler: nil)
        alert.addAction(ok)
        
        return alert
    }

}
