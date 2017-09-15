//
//  PlacelineView.swift
//  Pods
//
//  Created by ravi on 9/14/17.
//
//

import UIKit
import CoreLocation
import MapKit

@objc public class PlacelineView: UIView {

    @IBOutlet weak var placeLineTable: UITableView!
    @IBOutlet weak var mapView: MKMapView!
    
    var segments: [HyperTrackActivity] = []
    var selectedIndexPath : IndexPath? = nil
    var noResults = false
    let regionRadius: CLLocationDistance = 200
    
    var annotations = [MKPointAnnotation]()
    var polyLine : MKPolyline?
    public var date : Date? = nil
    
    func initPlacelineView(date : Date?){
        let nib = UINib(nibName: "placeCell", bundle: Settings.getBundle())
        placeLineTable.register(nib, forCellReuseIdentifier: "placeCell")
        placeLineTable.delegate = self
        placeLineTable.dataSource = self
        mapView.delegate = self
        self.date = date
        getPlaceLineData()
    }
    
    func getPlaceLineData(){
    
        if(HyperTrack.getUserId() != nil) {
            HyperTrack.getPlaceline(date: date) { (placeLine, error) in
                guard let fetchedPlaceLine = placeLine else { return }
                if let segments = fetchedPlaceLine.segments {
                    self.segments = segments.reversed()
                    if segments.count == 0 {
                        self.noResults = true
                    } else {
                        self.noResults = false
                    }
                    self.placeLineTable.reloadData()
                    if(segments.count > 0){
                        self.selectedIndexPath = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                            self.tableView(self.placeLineTable, didSelectRowAt: IndexPath.init(row: 0, section: 0))
                            
                        }
                    }
                }
                
            }
        }
    }
    

    
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}


extension PlacelineView : UITableViewDataSource, UITableViewDelegate {
  
    
   public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard segments.count != 0 else { return 1 }
        return segments.count
    }
    
    
   public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return 72
    }
    
  public  func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    func getTopVisibleRow() {
        let array = placeLineTable.indexPathsForVisibleRows
    }
    
    
   public  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "placeCell", for: indexPath) as! placeCell
        cell.layer.backgroundColor = UIColor.clear.cgColor
        if segments.count != 0 {
            cell.setStats(activity: segments[indexPath.row])
        } else {
            
            if self.noResults {
                cell.noResults()
            } else {
                cell.loading()
            }
        }
        cell.selectionStyle = .none
        
        if(selectedIndexPath?.row != indexPath.row) || (cell.status.text == "Loading Placeline.."){
            cell.normalize()
        }else if (selectedIndexPath?.row == indexPath.row){
            cell.select()
        }
        return cell
        
    }
    
    
   public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let cell = placeLineTable.cellForRow(at: indexPath) as? placeCell else { return }
        placeLineTable.scrollToRow(at: indexPath, at: .middle, animated: true)
        self.mapView.removeAnnotations(annotations)
        self.mapView.removeOverlays(self.mapView.overlays)
        annotations = [MKPointAnnotation]()
        if(polyLine != nil){
            self.mapView.remove(polyLine!)
            
        }
        
        if (self.segments.count == 0){
            return
        }
        
        if(!self.noResults){
            showDataOnMapForActivity(activithy: segments[indexPath.row])
            cell.select()
            if(selectedIndexPath != nil && selectedIndexPath?.row != indexPath.row){
                var  oldCell = self.placeLineTable.cellForRow(at: selectedIndexPath!) as? placeCell
                oldCell?.normalize()
            }
            selectedIndexPath = indexPath
        }
    }
    
    
    func showDataOnMapForActivity(activithy : HyperTrackActivity){
        print(activithy)
        if(activithy.type == "trip"){
            drawPolyLineForActivity(activity: activithy)
        }else if(activithy.type == "stop"){
            drawPointForActivity(activity: activithy)
        }
    }
    
    
    func drawPolyLineForActivity(activity : HyperTrackActivity){
        mapPolylineFor(encodedPolyline: activity.encodedPolyline!)
    }
    
    func drawPointForActivity(activity : HyperTrackActivity){
        let annotation =  MKPointAnnotation()
        annotation.title = "point"
        if let place = activity.place{
            annotation.coordinate = CLLocationCoordinate2DMake((place.location?.coordinates.last)!, (place.location?.coordinates.first)!)
            annotations.append(annotation)
            self.mapView.addAnnotation(annotation)
            centerMapOnAnnotation(annotation:annotation)
        }
    }
    
    
    public func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as? placeCell
        cell?.deselect()
    }
}



extension PlacelineView : MKMapViewDelegate {
    
    func mapPolylineFor(encodedPolyline: String) {
        let coordinates = decodePolyline(encodedPolyline)
        
        self.polyLine = MKPolyline(coordinates: coordinates!, count: coordinates!.count)
        self.mapView.add(polyLine!)
        
        if let first = coordinates?.first {
            let startAnnotation = MKPointAnnotation()
            startAnnotation.coordinate = first
            startAnnotation.title = "start"
            annotations.append(startAnnotation)
            self.mapView.addAnnotation(startAnnotation)
        }
        
        if let last = coordinates?.last {
            let startAnnotation = MKPointAnnotation()
            startAnnotation.coordinate = last
            startAnnotation.title = "stop"
            annotations.append(startAnnotation)
            self.mapView.addAnnotation(startAnnotation)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            let mapEdgePadding = UIEdgeInsets(top: 120, left: 40, bottom: 0.60 * (self.frame.size.height), right: 40)
            self.mapView.setVisibleMapRect((self.polyLine?.boundingMapRect)!,edgePadding: mapEdgePadding ,animated: true)
        }
    }
    
    
    func centerMapOnAnnotation(annotation: MKPointAnnotation){
        let span = MKCoordinateSpanMake(0.008,0.008)
        let region = MKCoordinateRegion(center: annotation.coordinate, span: span)
        mapView.setRegion(region, animated: true)

        var coordinate = annotation.coordinate
        coordinate.latitude -= self.mapView.region.span.latitudeDelta * 0.10;
        mapView.setCenter(coordinate, animated: false)

    }
    
    func getVisibleRectForAnnotation(markers : [MKPointAnnotation?],width:Double) -> MKMapRect{
        var zoomRect:MKMapRect = MKMapRectNull
        
        for index in 0..<markers.count {
            let annotation = markers[index]
            if let annotation = annotation{
                let aPoint:MKMapPoint = MKMapPointForCoordinate(annotation.coordinate)
                let rect:MKMapRect = MKMapRectMake(aPoint.x, aPoint.y, width, width)
                if MKMapRectIsNull(zoomRect) {
                    zoomRect = rect
                } else {
                    zoomRect = MKMapRectUnion(zoomRect, rect)
                }
            }
        }
        return zoomRect
    }
    
    func focusMarkers(markers : [MKPointAnnotation?],width:Double){
        
        let zoomRect = getVisibleRectForAnnotation(markers: markers, width: width)
        
        if(!MKMapRectIsNull(zoomRect)){
            let mapEdgePadding = UIEdgeInsets(top: 120, left: 40, bottom: 0.60 * (self.frame.size.height), right: 40)
            mapView.setVisibleMapRect(zoomRect, edgePadding: mapEdgePadding, animated: true)
            
        }
    }
    
    
    func decodePolyline(_ encodedPolyline: String, precision: Double = 1e5) -> [CLLocationCoordinate2D]? {
        
        let data = encodedPolyline.data(using: String.Encoding.utf8)!
        
        let byteArray = (data as NSData).bytes.assumingMemoryBound(to: Int8.self)
        let length = Int(data.count)
        var position = Int(0)
        
        var decodedCoordinates = [CLLocationCoordinate2D]()
        
        var lat = 0.0
        var lon = 0.0
        
        while position < length {
            
            do {
                let resultingLat = try decodeSingleCoordinate(byteArray: byteArray, length: length, position: &position, precision: precision)
                lat += resultingLat
                
                let resultingLon = try decodeSingleCoordinate(byteArray: byteArray, length: length, position: &position, precision: precision)
                lon += resultingLon
            } catch {
                return nil
            }
            
            decodedCoordinates.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
        }
        
        return decodedCoordinates
    }
    
    private func decodeSingleCoordinate(byteArray: UnsafePointer<Int8>, length: Int, position: inout Int, precision: Double = 1e5) throws -> Double {
        
        guard position < length else {
            return 0.0
        }
        
        let bitMask = Int8(0x1F)
        
        var coordinate: Int32 = 0
        
        var currentChar: Int8
        var componentCounter: Int32 = 0
        var component: Int32 = 0
        
        repeat {
            currentChar = byteArray[position] - 63
            component = Int32(currentChar & bitMask)
            coordinate |= (component << (5*componentCounter))
            position += 1
            componentCounter += 1
        } while ((currentChar & 0x20) == 0x20) && (position < length) && (componentCounter < 6)
        
        if (componentCounter == 6) && ((currentChar & 0x20) == 0x20) {
        }
        
        if (coordinate & 0x01) == 0x01 {
            coordinate = ~(coordinate >> 1)
        } else {
            coordinate = coordinate >> 1
        }
        
        return Double(coordinate) / precision
    }
    
    
   public func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let polyline = overlay as? MKPolyline else {
            return MKOverlayRenderer()
        }
        
        let renderer = CustomPolyline(polyline: polyline)
        renderer.lineWidth = 3.0
        renderer.strokeColor = UIColor(red:0.40, green:0.39, blue:0.49, alpha:1.0)
        
        return renderer
    }
    
    public func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let marker = MKAnnotationView()
        marker.frame = CGRect(x:0,y:0,width:20.0,height:20.0)
        let bundle = Bundle(for: PlacelineView.self)
        if let title = annotation.title{
            if(title == "start"){
                let image = UIImage.init(named: "stopOrEnd", in: bundle, compatibleWith: nil)
                marker.image =  image?.resizeImage(newWidth: 15.0)
            }else if (title == "stop"){
                marker.image =  UIImage.init(named: "destinationMarker", in: bundle, compatibleWith: nil)?.resizeImage(newWidth: 30.0)
            }
            else if (title == "point"){
                marker.image =  UIImage.init(named: "origin", in: bundle, compatibleWith: nil)?.resizeImage(newWidth: 15.0)
            }
        }
        
        marker.annotation = annotation
        return marker
    }
    
    
}

class CustomPolyline: MKPolylineRenderer {
    
    override func applyStrokeProperties(to context: CGContext, atZoomScale zoomScale: MKZoomScale) {
        super.applyStrokeProperties(to: context, atZoomScale: zoomScale)
        // UIGraphicsPushContext(context)
        
        if let ctx = UIGraphicsGetCurrentContext() {
            ctx.setLineWidth(self.lineWidth)
        }
    }
}


extension Date
{
    func toString( dateFormat format  : String ) -> String
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        dateFormatter.locale = Locale.init(identifier: "en_US")
        return dateFormatter.string(from: self)
    }
    
}
