//
//  String+Extension.swift
//  Meta-iPhone
//
//  Created by Ulhas Mandrawadkar on 05/06/16.
//  Copyright © 2016 HyperTrack, Inc. All rights reserved.
//

extension String {
    
    subscript (i: Int) -> Character {
        if self.isEmpty {
            return Character("")
        }
        
        if i > self.count {
            return Character("")
        }
        
        return self[self.index(self.startIndex, offsetBy: i)]
    }
    
    subscript (i: Int) -> String {
        if self.isEmpty {
            return ""
        }
        
        if i > self.count {
            return ""
        }
        
        return String(self[i] as Character)
    }
    
//    subscript (r: Range<Int>) -> String {
//        let start = self.index(self.startIndex, offsetBy: r.lowerBound)
//        let end = self.index(start, offsetBy: r.upperBound - r.lowerBound)
//        return self[Range(start ..< end)]
//    }
    subscript (r: Range<Int>) -> String {
        let range = Range(uncheckedBounds: (lower: max(0, min(self.count, r.lowerBound)), upper: min(self.count, max(0, r.upperBound))))
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(start, offsetBy: range.upperBound - range.lowerBound)
        return String(self[start ..< end])
    }
}
