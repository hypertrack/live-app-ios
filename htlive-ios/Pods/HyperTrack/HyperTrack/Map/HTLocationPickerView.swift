//
//  HTLocationPickerView.swift
//  Pods
//
//  Created by Ravi Jain on 05/07/17.
//
//

import UIKit
import MapKit

class HTLocationPickerView: UIView,MKMapViewDelegate {

    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var searchResultTableView: UITableView!

    override func awakeFromNib() {
        
        self.mapView.delegate = self
        // This enables UI settings on MKMapView
        self.mapView.showsPointsOfInterest = true

    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
