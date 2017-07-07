//
//  ActionStore.swift
//  HyperTrack
//
//  Created by Anil Giri on 28/04/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import Foundation
import CoreLocation

public protocol ActionStoreDelegate {
    func didReceiveLocationUpdates(_ locations: [TimedCoordinates], action: HyperTrackAction?)
    func clearAction()
}

struct TrackerConstants {
    static let minPollingFrequency = 5.0 //seconds
}

final class ActionStore {
    static let sharedInstance = ActionStore()
    var trackedActions = [String]()
    var pollingTimer: Timer?
    var delegate : ActionStoreDelegate?

    func trackActionFor(_ actionID: String, delegate: ActionStoreDelegate) {
        // All actions that are to be refreshed at frequency of <gap> seconds.
        self.delegate = delegate
        self.clearAction()

        trackedActions.append(actionID)
        updateLocations()
        self.initializeTimer()
    }
  
    func trackActionFor(shortCode: String, delegate: ActionStoreDelegate) {
        self.delegate = delegate
        self.clearAction()
        self.firstUpdateFor(shortCode: shortCode)
    }

    func initializeTimer() {
        pollingTimer = Timer.scheduledTimer(timeInterval: TrackerConstants.minPollingFrequency, target: self, selector: #selector(updateLocations), userInfo: nil, repeats: true)
        pollingTimer?.fire()
    }

    func clearAction() {
        trackedActions = []
        pollingTimer?.invalidate()
        if let delegate = self.delegate {
            delegate.clearAction()
        }
    }

    @objc func updateLocations() {
        for actionID in self.trackedActions {
            fetchUpdatesFor(actionID, completion: { (_ timedLocations: [TimedCoordinates], action: HyperTrackAction?) in
                
                if let delegate = self.delegate {
                    delegate.didReceiveLocationUpdates(timedLocations, action: action)
                }
            })
        }
    }
    
    func firstUpdateFor(shortCode: String) {
        RequestManager().fetchDetailsForActionsByShortCodes([shortCode], completionHandler: { (actions, error) in
            
            var locations: [TimedCoordinates] = []
            
            if let actions = actions {
                if actions.count > 0 {
                    let action = actions.first
                    let polyline = action?.timeAwarePolyline
                    
                    if let polylineString = polyline {
                        if let coordinates = timedCoordinatesFrom(polyline: polylineString) {
                            locations = coordinates
                        }
                    }
                    
                    if let actionId = action?.id as String? {
                        self.trackedActions.append(actionId)
                    }
                    
                    if let delegate = self.delegate {
                        delegate.didReceiveLocationUpdates(locations, action: action)
                    }
                    
                    self.initializeTimer()

                }
            }
        })
    }
    
    func fetchUpdatesFor(_ actionID: String, completion: ((_ timedLocations: [TimedCoordinates], _ action: HyperTrackAction?) -> Void)?) {
        var locations = [TimedCoordinates]()
        
        RequestManager().fetchDetailsForActions([actionID]) { (actions, error) in
            
            if let actions = actions {
                if actions.count > 0 {
                    let action = actions.first
                    let polyline = action?.timeAwarePolyline
                    
                    if let polylineString = polyline {
                        if let coordinates = timedCoordinatesFrom(polyline: polylineString) {
                            locations = coordinates
                        }
                    }
                    
                    if let completion = completion {
                        completion(locations, action)
                    }
                }
            }
        }
    }
}
