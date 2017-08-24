//
//  HTLocationPickerView.swift
//  Pods
//
//  Created by Ravi Jain on 05/07/17.
//
//

import UIKit
import MapKit

protocol  HTLocationPickerViewDelegate : class {
    func getSavedPlaces() -> [HyperTrackPlace]?
    func getSearchResultsForText(searchText : String,completionHandler: ((_ places: [HyperTrackPlace]?, _ error: HyperTrackError?) -> Void)?)
    func getSearchResultsForCoordinated(cordinate: CLLocationCoordinate2D? ,completionHandler: ((_ place: HyperTrackPlace?, _ error: HyperTrackError?) -> Void)?)
    func didSelectedLocation(place : HyperTrackPlace, fromHistory:Bool)
}

class HTLocationPickerView: UIView,MKMapViewDelegate,UISearchBarDelegate,UITableViewDelegate,UITableViewDataSource {
    
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var searchResultTableView: UITableView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet fileprivate weak var addDestinationHeightConstraint : NSLayoutConstraint!
    @IBOutlet weak var addDestinationButton: UIButton!
    
    fileprivate var pointAnnotation: MKPointAnnotation!
    
    open var longitudinalDistance: Double!
    open var isMapViewCenterChanged = false

    
    var searchResults : [HyperTrackPlace]?
    var isShowingSavedResults = true
    weak var pickerViewDelegate : HTLocationPickerViewDelegate?
    
    override func awakeFromNib() {
        self.mapView.bringSubview(toFront: self.searchBar)
        self.mapView.bringSubview(toFront: self.backButton)
        self.mapView.bringSubview(toFront: self.searchResultTableView)
        
        self.mapView.delegate = self
        self.mapView.showsPointsOfInterest = true
        mapView.isRotateEnabled = true
        mapView.isPitchEnabled = true
        mapView.showsUserLocation = true
        mapView.isScrollEnabled = true
        mapView.isZoomEnabled = true
        
        
        mapView.delegate = self
        self.searchResultTableView.dataSource = self
        self.searchResultTableView.delegate = self
        self.searchBar.delegate = self
        self.mapView.bringSubview(toFront: self.addDestinationButton)
        
        var region : MKCoordinateRegion?
        self.pointAnnotation = MKPointAnnotation()
        
        if let location = Transmitter.sharedInstance.locationManager.getLastKnownLocation(){
            region =    MKCoordinateRegionMake(
                (location.coordinate),
                MKCoordinateSpanMake(0.005, 0.005))
            self.pointAnnotation.coordinate = (location.coordinate)
        }
        else{
            region =    MKCoordinateRegionMake(
                CLLocationCoordinate2DMake(28.5621352, 77.1604902),
                MKCoordinateSpanMake(0.05, 0.05))
            self.pointAnnotation.coordinate = CLLocationCoordinate2DMake(28.5621352, 77.1604902)
        }
        
        self.mapView.setRegion(region!, animated: true)
        self.mapView.addAnnotation(self.pointAnnotation)
        
        self.searchResultTableView.register(UINib(nibName: "SearchCellView", bundle: Settings.getBundle()), forCellReuseIdentifier: "searchCell")
        
        self.searchResultTableView.backgroundColor = UIColor.groupTableViewBackground
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow(notification:)),
                                               name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide(notification:)),
                                               name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        self.reloadSearchResults()
    }
    
    public func setUp (){
        self.reloadSearchResults()
    }
    
    func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            
            addDestinationHeightConstraint.constant = keyboardSize.height + 10
            UIView.animate(withDuration: 0.5) {
                self.layoutIfNeeded()
            }
        }
    }
    func keyboardWillHide(notification: NSNotification) {
        if ((notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue) != nil {
            addDestinationHeightConstraint.constant = 20
            UIView.animate(withDuration: 0.5) {
                self.layoutIfNeeded()
            }
        }
    }
    
    func getSavedSearchResults() -> [HyperTrackPlace]?{
        if(pickerViewDelegate != nil){
            if let places =  pickerViewDelegate?.getSavedPlaces(){
                return places
            }
        
        }
        return []
    }
    
    @IBAction func onBackPressed(sender: UIButton) {
        self.removeSearchView()
    }
    
    @IBAction func addDestinationClicked (sender: UIButton) {
        if(self.isMapViewCenterChanged){
            if(pickerViewDelegate != nil){
                pickerViewDelegate?.getSearchResultsForCoordinated(cordinate: pointAnnotation.coordinate, completionHandler: { place, error in
                    if(error == nil){
                        if(self.pickerViewDelegate != nil){
                            self.pickerViewDelegate?.didSelectedLocation(place: place!,fromHistory: false)
                        }
                        self.removeSearchView()
                    }else{
                        //log error
                        
                    }
                })
            }
  
        }
    }
    
    private func reloadSearchResults(){
        
        searchResultTableView.reloadData()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            var height = self.searchResultTableView.contentSize.height
            if(height > 300.0){
                height = 300.0
            }
            self.searchResultTableView.frame = CGRect(x: self.searchResultTableView.frame.origin.x, y: self.searchResultTableView.frame.origin.y, width: self.searchResultTableView.frame.size.width, height: height)

        }

    }
    
    
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if !(searchText.isEmpty) {
            if(pickerViewDelegate != nil){
                pickerViewDelegate?.getSearchResultsForText(searchText: searchText, completionHandler: { places, error in
                    if(error == nil){
                        self.searchResults = places
                        self.isShowingSavedResults = false
                        self.reloadSearchResults()
                    }else{
                        //log error
                        
                    }
                })
            }
        }else{
            searchResults = []
            self.isShowingSavedResults = true
            self.reloadSearchResults()
            
        }
    }
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat{
        if(section == 0){
            return 10.0
        }else{
            return 2.0
        }
    }
    
    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat{
        if(section == 0){
            return 10.0
        }else{
            return 2.0
        }
    }
    public func numberOfSections(in tableView: UITableView) -> Int{
        return 2
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        
        if(section == 0){
            return 1
        }
        
        if(isShowingSavedResults){
            return (getSavedSearchResults()!.count)
        }else{
            if searchResults != nil{
                return (searchResults?.count)!
            }
        }
        return 0
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "searchCell", for: indexPath) as? HTSearchViewCell
        
        let bundle = Bundle(for: HTLocationPickerView.self)
        
        cell?.centreLabel?.text = ""
        cell?.mainLabel?.text = ""
        cell?.subtitleLabel?.text = ""
        
        cell?.iconView?.alpha = 0.4
        if(indexPath.section == 0){
            cell?.centreLabel?.text = "Your Location"
            cell?.iconView?.image = UIImage.init(named: "locateMe", in: bundle, compatibleWith: nil)
        }else{
            let location : HyperTrackPlace
            if(isShowingSavedResults){
                location = (getSavedSearchResults()![indexPath.row])
                cell?.iconView?.image = UIImage.init(named: "savedPlace", in: bundle, compatibleWith: nil)
                
            }else{
                location = (searchResults?[indexPath.row])!
                cell?.iconView?.image = UIImage.init(named: "place", in: bundle, compatibleWith: nil)
            }
            if(location.name == nil || location.name == ""){
                if(location.address != nil){
                    location.name = location.address?.components(separatedBy: ",").first
                }
            }
            cell?.mainLabel?.text = location.name
            cell?.subtitleLabel?.text = location.address
        }
        
        return (cell)!
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        if(indexPath.section == 0){
            if let location = Transmitter.sharedInstance.locationManager.getLastKnownLocation(){
                if(pickerViewDelegate != nil){
                    pickerViewDelegate?.getSearchResultsForCoordinated(cordinate: location.coordinate, completionHandler: { place, error in
                        if(error == nil){
                            if(self.pickerViewDelegate != nil){
                                self.pickerViewDelegate?.didSelectedLocation(place: place!,fromHistory: false)
                            }
                            self.removeSearchView()
                        }else{
                            //log error
                            
                        }
                    })
                }
            }
           
        }else{
            
            let location : HyperTrackPlace
            if(isShowingSavedResults){
                location = (getSavedSearchResults()![indexPath.row])
            }else{
                location = (searchResults?[indexPath.row])!
            }
            
            if(pickerViewDelegate != nil){
                pickerViewDelegate?.didSelectedLocation(place: location,fromHistory: isShowingSavedResults)
            }
            
            removeSearchView()
        }
    }
    
    
    func removeSearchView(){
        self.removeFromSuperview()
        self.searchBar.text = ""
        self.searchResults = []
        self.isShowingSavedResults = true
        self.reloadSearchResults()
    }
    
    
    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar){
        //removeSearchView()
        self.searchResults = []
        self.searchBar.resignFirstResponder()
        self.reloadSearchResults()
    }
    
    
    public func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        
    }
    
    public func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        self.isMapViewCenterChanged = true
        self.pointAnnotation.coordinate = mapView.region.center
    }
    
    
}



class HTSearchViewCell : UITableViewCell {
    
    @IBOutlet weak var mainLabel : UILabel?
    @IBOutlet weak var subtitleLabel : UILabel?
    @IBOutlet weak var iconView : UIImageView?
    @IBOutlet weak var centreLabel : UILabel?
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: "SearchCell")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
}
