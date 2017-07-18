//
//  MKMapView+Extension.swift
//  Meta-iPhone
//
//  Created by Ulhas Mandrawadkar on 08/01/16.
//  Copyright © 2016 HyperTrack, Inc. All rights reserved.
//

import UIKit
import MapKit

extension MKMapView {
    
    func mapRectThatFits(first: CLLocationCoordinate2D, second: CLLocationCoordinate2D) -> MKMapRect {
        
        if (!(CLLocationCoordinate2DIsValid(first) && CLLocationCoordinate2DIsValid(second))) {
            return MKMapRectNull
        }
        
        let firstPoint = MKMapPointForCoordinate(first)
        let firstRect = MKMapRect(origin: firstPoint, size: MKMapSizeMake(0.0, 0.0))
        
        let secondPoint = MKMapPointForCoordinate(second)
        let secondRect = MKMapRect(origin: secondPoint, size: MKMapSizeMake(0.0, 0.0))
        
        return MKMapRectUnion(firstRect, secondRect)
    }
}
