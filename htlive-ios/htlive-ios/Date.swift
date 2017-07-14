//
//  Date.swift
//  htlive-ios
//
//  Created by Vibes on 7/14/17.
//  Copyright © 2017 PZRT. All rights reserved.
//

import Foundation

extension Date
{
    func toString( dateFormat format  : String ) -> String
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }
    
}
