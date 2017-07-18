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
        
        if i > self.characters.count {
            return Character("")
        }
        
        return self[self.index(self.startIndex, offsetBy: i)]
    }
    
    subscript (i: Int) -> String {
        if self.isEmpty {
            return ""
        }
        
        if i > self.characters.count {
            return ""
        }
        
        return String(self[i] as Character)
    }
    
    subscript (r: Range<Int>) -> String {
        let start = self.index(self.startIndex, offsetBy: r.lowerBound)
        let end = self.index(start, offsetBy: r.upperBound - r.lowerBound)
        return self[Range(start ..< end)]
    }
}
