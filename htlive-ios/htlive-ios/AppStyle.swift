//
//  AppStyle.swift
//  htlive-ios
//
//  Created by Atul Manwar on 21/02/18.
//  Copyright © 2018 PZRT. All rights reserved.
//

import UIKit
import HyperTrack

struct AppFontProvider: HTFontProviderProtocol {
    fileprivate func getWeight(_ weight: UIFont.HTFontWeight) -> String {
        switch weight {
        case .bold:
            return "SemiBold"
        case .medium:
            return "Medium"
        case .regular:
            return "Regular"
        }
    }
    
    fileprivate func getSize(_ size: UIFont.HTSize) -> CGFloat {
        switch size {
        case .title:
            return 16
        case .normal:
            return 14
        case .info:
            return 12
        case .caption:
            return 10
        }
    }

    func getFont(_ size: UIFont.HTSize, weight: UIFont.HTFontWeight) -> UIFont {
        return UIFont(name: "WorkSans-\(getWeight(weight))", size: getSize(size))!
    }
}
