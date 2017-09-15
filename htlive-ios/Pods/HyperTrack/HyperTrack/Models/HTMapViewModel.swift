//
//  HTMapViewModel.swift
//  Pods
//
//  Created by Ravi Jain on 04/06/17.
//
//

import UIKit
import MapKit

class HTMapViewModel: NSObject {
    
    var heroMarker : HTMapAnnotation?
    var destinationMarker : HTMapAnnotation?
    var sourceMarker : HTMapAnnotation?
    var acionSummaryStartMarker : HTMapAnnotation?
    var actionSummaryEndMarker : HTMapAnnotation?
    var actionSummaryPolylineLatLng : [CLLocationCoordinate2D]?
    
    var rotateHeroMarker = true
    var isHeroMarkerVisible = true
    var isDestinationMarkerVisible = true
    var isActionSummaryInfoVisible = true
    var isAddressInfoVisible = true
    var isUserInfoVisible = false
    var isOrderDetailsButtonVisible = false
    var isSourceMarkerVisible = true
    var isCallButtonVisible = true
    
    var disableEditDestination = false
    var showUserLocationMissingAlert = true
    var showEditDestinationFailureAlert = true
    
    var type = HTConstants.AnnotationType.ACTION
    
    override init(){
        
    }
    
    init(heroMarker:HTMapAnnotation?,destinationMarker : HTMapAnnotation?,sourceMarker : HTMapAnnotation?,acionSummaryStartMarker : HTMapAnnotation?,actionSummaryEndMarker : HTMapAnnotation?){
        self.heroMarker = heroMarker
        self.destinationMarker = destinationMarker
        self.sourceMarker  = sourceMarker
        self.actionSummaryEndMarker = actionSummaryEndMarker
        self.acionSummaryStartMarker = acionSummaryStartMarker
    }
}
