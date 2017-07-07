//
//  MapUtilities.swift
//  HyperTrack
//
//  Created by Anil Giri on 18/05/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit

func smallestMapRegionContaining(_ first: CLLocationCoordinate2D, _ second: CLLocationCoordinate2D, marginDegrees: Double = 0) -> MKCoordinateRegion {
    
    var xSpan = abs(first.latitude - second.latitude) + marginDegrees * abs(first.latitude - second.latitude)
    if xSpan < MaxZoomSpan.latitudeDelta {
        xSpan = MaxZoomSpan.latitudeDelta
    }
    var ySpan = abs(first.longitude - second.longitude) + marginDegrees *  abs(first.longitude - second.longitude)
    if ySpan < MaxZoomSpan.longitudeDelta {
        ySpan = MaxZoomSpan.longitudeDelta
    }
    
    let span = MKCoordinateSpanMake(xSpan, ySpan)
    let center = CLLocationCoordinate2DMake((first.latitude + second.latitude) / 2, (first.longitude + second.longitude) / 2)
    let region = MKCoordinateRegionMake(center, span)
    
    return region
}
