//
//  HTMapAnnotation.swift
//  Pods
//
//  Created by Ravi Jain on 05/06/17.
//
//

import UIKit
import MapKit

class HTMapAnnotation: MKPointAnnotation {
  
    var id : String?
    dynamic var disableRotation: Bool = false
    var image: UIImage?
    var colour: UIColor?
    var type = HTConstants.MarkerType.HERO_MARKER
    
    override init() {
        super.init()
        self.image = nil
        self.colour = UIColor.red
    }
}
