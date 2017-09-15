//
//  HTMockLocationManager.swift
//  HyperTrack
//
//  Created by Arjun Attam on 04/06/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import Foundation
import CoreLocation

class MockLocationManager: NSObject {
    var requestManager: RequestManager
    var mockTimer: Timer?
    var coordinates: [TimedCoordinates]?
    
    var isTracking:Bool {
        get {
            return Settings.getMockTracking()
        }
        
        set {
            Settings.setMockTracking(isTracking: newValue)
        }
    }
    
    override init() {
        self.requestManager = RequestManager()
        super.init()
    }
    
    func updateCoordinates(coordinates: [TimedCoordinates]) {
        Settings.setMockCoordinates(coordinates: coordinates)
        self.coordinates = coordinates
    }
    
    func startService(coordinates: [TimedCoordinates]) {
        self.requestManager.startTimer()
        self.updateCoordinates(coordinates: coordinates)
        self.saveTrackingStarted()
        self.scheduleNextTimer()
        self.requestManager.postEvents(flush:true)
    }
    
    @objc func saveNextEvent() {
        // Save the event and schedule the next timer
        if var coordinates = Settings.getMockCoordinates() {
            if coordinates.count > 0 {
                let first = coordinates.removeFirst()
                saveLocationChanged(coordinate: first.location, timeStamp: first.timeStamp)
                
                if coordinates.count == 0 {
                    saveStopStarted(coordinate: first.location, timeStamp: first.timeStamp)
                }
                
                self.updateCoordinates(coordinates: coordinates)
                scheduleNextTimer()
            }
        }
    }
    
    func scheduleNextTimer() {
        // This method goes through self.coordinates and
        // keeps setting a timer on the basis of the timestamps
        // and saves the corresponding events
        if let coordinates = Settings.getMockCoordinates(), let first = coordinates.first {
            let timeToFire = first.timeStamp
            let timerInterval = timeToFire.timeIntervalSinceNow
            
            if timerInterval > 0 {
                // Set the timer
                self.mockTimer = Timer.scheduledTimer(timeInterval: timerInterval,
                                                      target: self,
                                                      selector: #selector(self.saveNextEvent),
                                                      userInfo: nil,
                                                      repeats: false)
            } else {
                // Just do what a timer would have done since
                // the timer interval is negative
                self.saveNextEvent()
            }
        }
    }
    
    func stopService() {
        if self.isTracking {
            self.saveTrackingEnded()
            
            self.requestManager.postEvents(flush:true)
            self.requestManager.stopTimer()
            if let timer = self.mockTimer {
                timer.invalidate()
            }
        }
    }
}

extension MockLocationManager {
    // Might move these to a parent class that is
    // inherited by both LocationManager and MockLM
    func saveTrackingStarted() {
        let eventType = "tracking.started"
        guard let userId = Settings.getUserId() else { return }
        let event = HyperTrackEvent(
            userId:userId,
            recordedAt:Date(),
            eventType:eventType,
            location:nil,
            data : ["is_mock":true]
        )
        event.save()
        // TODO: self.saveDeviceInfoChangedEvent()
        isTracking = true
        Transmitter.sharedInstance.callDelegateWithEvent(event: event)
    }
    
    func saveTrackingEnded() {
        let eventType = "tracking.ended"
        isTracking = false
        
        guard let userId = Settings.getUserId() else { return }
        let event = HyperTrackEvent(
            userId:userId,
            recordedAt:Date(),
            eventType:eventType,
            location:nil,
            data : ["is_mock":true]
        )
        event.save()
        Transmitter.sharedInstance.callDelegateWithEvent(event: event)
    }
    
    func saveLocationChanged(coordinate: CLLocationCoordinate2D, timeStamp: Date) {
        HTLogger.shared.verbose("Saving location.changed event")
        let eventType = "location.changed"
        
        let htLocation = HyperTrackLocation(locationCoordinate: coordinate, timeStamp: timeStamp, provider: "Simulate")
        guard let userId = Settings.getUserId() else { return }
        
        let event = HyperTrackEvent(
            userId:userId,
            recordedAt:htLocation.recordedAt,
            eventType:eventType,
            location:htLocation
        )
        event.save()
        Settings.setLastKnownLocation(location: htLocation)
        Transmitter.sharedInstance.callDelegateWithEvent(event: event)
    }
    
    func saveStopStarted(coordinate: CLLocationCoordinate2D, timeStamp: Date) {
        HTLogger.shared.info("Saving stop.started event")
        let eventType = "stop.started"
        
        let htLocation = HyperTrackLocation(locationCoordinate: coordinate, timeStamp: timeStamp)
        
        guard let userId = Settings.getUserId() else {
            return
        }
        
        let event = HyperTrackEvent(
            userId:userId,
            recordedAt:timeStamp,
            eventType:eventType,
            location:htLocation,
            data:["stop_id": UUID().uuidString]
        )
        event.save()

        requestManager.postEvents(flush:true)
    }
}
