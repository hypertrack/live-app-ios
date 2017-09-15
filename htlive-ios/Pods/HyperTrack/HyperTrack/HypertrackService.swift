//
//  HypertrackService.swift
//  HyperTrack
//
//  Created by Ravi Jain on 8/5/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import UIKit
import CoreLocation

class HypertrackService: NSObject {

    static let sharedInstance = HypertrackService()

    let requestManager: RequestManager

    override init() {
        EventsDatabaseManager.sharedInstance.createEventsTable()
        self.requestManager = RequestManager()
    }

    func setPublishableKey(publishableKey:String) {
        Settings.setPublishableKey(publishableKey: publishableKey)
    }
    
    func getPublishableKey() -> String? {
        return Settings.getPublishableKey()
    }

   
    func findPlaces(searchText:String?, cordinate: CLLocationCoordinate2D? , completionHandler: ((_ places: [HyperTrackPlace]?, _ error: HyperTrackError?) -> Void)?){
        self.requestManager.findPlaces(searchText: searchText, cordinate: cordinate, completionHandler: completionHandler)
    }
    
    
    func createPlace(geoJson : HTGeoJSONLocation,completionHandler: ((_ place: HyperTrackPlace?, _ error: HyperTrackError?) -> Void)?){
        self.requestManager.createPlace(geoJson: geoJson, completionHandler: completionHandler)
    }
    
    func updateSDKControls() {
        guard let userId = Settings.getUserId() else { return }
        
        self.requestManager.getSDKControls(userId: userId) { (controls, error) in
            if (error == nil) {
                if let controls = controls {
                    // Successfully updated the SDKControls
                    HTLogger.shared.info("SDKControls for user: \(userId) updated to batch_duration: \(controls.batchDuration) displacement: \(controls.minimumDisplacement) ttl: \(controls.ttl)")
                    self.processSDKControls(controls: controls)
                }
            }
        }
    }

    
    func getPlacelineActivity(date: Date? = nil, completionHandler: @escaping (_ placeline: HyperTrackPlaceline?, _ error: HyperTrackError?) -> Void) {
        // TODO: this method should not be in Transmitter, but needs access to request manager
        guard let userId = Settings.getUserId() else {
            completionHandler(nil, HyperTrackError(HyperTrackErrorType.userIdError))
            return
        }
        
        requestManager.getUserPlaceline(date: date, userId: userId) { (placeline, error) in
            if (error != nil) {
                completionHandler(nil, error)
                return
            }
            
            completionHandler(placeline, nil)
        }
    }
    
    func getETA(expectedPlaceCoordinates: CLLocationCoordinate2D, vehicleType: String?,
                completionHandler: @escaping (_ eta: NSNumber?, _ error: HyperTrackError?) -> Void) {
        var vehicleTypeParam = vehicleType
        if (vehicleTypeParam == nil) {
            vehicleTypeParam = "car"
        }
        
        Transmitter.sharedInstance.getCurrentLocation { (currentLocation, error) in
            if (currentLocation != nil) {
                self.requestManager.getETA(currentLocationCoordinates: currentLocation!.coordinate,
                                           expectedPlaceCoordinates: expectedPlaceCoordinates,
                                           vehicleType: vehicleTypeParam!,
                                           completionHandler: completionHandler)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    func processSDKControls(controls: HyperTrackSDKControls) {
        // Process controls
        if let runCommand = controls.runCommand {
            
            if runCommand == "GO_OFFLINE" {
                // Stop tracking from the backend
                if Transmitter.sharedInstance.isTracking {
                    HyperTrack.stopTracking()
                }
            } else if runCommand == "FLUSH" {
                self.flushCachedData()
            } else if runCommand == "GO_ACTIVE" {
                // nothing to do as controls will handle
            } else if runCommand == "GO_ONLINE" {
                // nothing to do as controls will handle
            }
        }
        HyperTrackSDKControls.saveControls(controls: controls)
        Transmitter.sharedInstance.refreshTransmitterWithControls(controls: controls)
        Transmitter.sharedInstance.refreshTransmitter()
    }
    
    func flushCachedData() {
        self.requestManager.postEvents(flush: true)
    }


}
