//
//  ThemeManager.swift
//  Meta-iPhone
//
//  Created by Ulhas Mandrawadkar on 03/06/16.
//  Copyright © 2016 HyperTrack, Inc. All rights reserved.
//

import UIKit

final class ThemeManager {
    static func applyTheme() {
        applyThemeToNavigationBar()
    }
    
    private static func applyThemeToNavigationBar() {
        UINavigationBar.appearance().tintColor = UIColor.accentColor
        UINavigationBar.appearance().backgroundColor = UIColor.backgroundColor
    }
}

extension UIView {
    internal func applyTheme() {
        self.backgroundColor = UIColor.backgroundColor
    }
}
