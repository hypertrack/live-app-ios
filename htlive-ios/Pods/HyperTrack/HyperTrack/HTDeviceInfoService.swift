//
//  HTDeviceInfoService.swift
//  Pods
//
//  Created by Ravi Jain on 7/13/17.
//
//

import UIKit
import Alamofire
import CoreLocation

class HTDeviceInfoService: NSObject {
    
    let htBatteryLevelString = "htBatteryLevelString"
    let htBatteryStatusString  = "htBatteryStatusString"
    let htRadioInfoString = "htRadioInfoString"
    
    var requestManager: RequestManager
    
    
    override init(){
        requestManager = RequestManager()
        super.init()
        UIDevice.current.isBatteryMonitoringEnabled = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { 
            NotificationCenter.default.addObserver(self, selector: #selector(self.batteryLevelDidChange), name: .UIDeviceBatteryLevelDidChange, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(self.locationConfigDidChange), name: NSNotification.Name(rawValue: HTConstants.LocationPermissionChangeNotification), object: nil)
            self.startNetworkReachabilityObserver()
            self.postEventForLocationConfigChange()
            self.onBatteryChanged()
        }
    }
    
    func getLastKnownInfo(infoType : String?) -> String?{
        var info = UserDefaults.standard.string(forKey: infoType!)
        if(info == nil){
            info = ""
        }
        return info
    }
    
    func saveLastKnownInfo(infoType : String  , value : String ){
        UserDefaults.standard.set(value, forKey: infoType)
        UserDefaults.standard.synchronize()
    }
    
    func batteryState() -> UIDeviceBatteryState{
        return UIDevice.current.batteryState
    }
    
    func startNetworkReachabilityObserver() {
        let reachabilityManager = Alamofire.NetworkReachabilityManager(host: "www.google.com")
        
        var currentState = "notReachable"
        var isConnected = false
        reachabilityManager?.listener = { status in
            
            switch status {
                
            case .notReachable:
                print("The network is not reachable")
                break
            case .unknown :
                currentState = "unknown"
                print("It is unknown whether the network is reachable")
                break
            case .reachable(NetworkReachabilityManager.ConnectionType.ethernetOrWiFi):
                currentState = "ethernetOrWiFi"
                isConnected = true
                print("The network is reachable over the WiFi connection")
                break
                
            case .reachable(NetworkReachabilityManager.ConnectionType.wwan):
                print("The network is reachable over the WWAN connection")
                currentState = "wwan"
                isConnected = true
                break
            }
        }
        
        if(didInfoChangedFor(infoType: htRadioInfoString, newValue: currentState)){
            saveLastKnownInfo(infoType: htRadioInfoString, value: currentState)
            onNetworkStateChanged(state: currentState,isConnected :isConnected)
        }
        
        // start listening
        reachabilityManager?.startListening()
    }
    
    
    var batteryLevel: Float {
        return UIDevice.current.batteryLevel
    }
    
    func batteryLevelDidChange(_ notification: Notification) {
        let batteryLevelString = NSNumber(value: batteryLevel).stringValue
        if(didInfoChangedFor(infoType: htBatteryLevelString, newValue: batteryLevelString)){
            onBatteryChanged()
        }
    }
    
    func postEventForLocationConfigChange(){
        
        var isEnabled = false
        var isPermissionAccepted = false;
        
        if CLLocationManager.locationServicesEnabled() {
            isEnabled = true
            switch(CLLocationManager.authorizationStatus()) {
            case .notDetermined, .restricted, .denied:
                print("No access")
                break
            case .authorizedAlways, .authorizedWhenInUse:
                isPermissionAccepted = true
                print("Access")
                break
            }
        } else {
            print("Location services are not enabled")
        }
        if(Transmitter.sharedInstance.getUserId() != nil){
            let event = HyperTrackEvent(
                userId:Transmitter.sharedInstance.getUserId()!,
                recordedAt:Date(),
                eventType:"device.location_config.changed",
                location:nil,
                data : ["enabled":isEnabled,
                        "permission":isPermissionAccepted,
                        "mock_enabled" : false
                ]
            )
            event.save()
            requestManager.postEvents(flush:true)
        }
        
    }
    
    func locationConfigDidChange(_ notification: Notification) {
        postEventForLocationConfigChange()
    }
    
    
    func onBatteryChanged(){
        let batteryLevelString = NSNumber(value : (batteryLevel * 100.0)).stringValue

        saveLastKnownInfo(infoType: htBatteryLevelString, value: batteryLevelString)

        if(Transmitter.sharedInstance.getUserId() != nil){
            var chargingStatus  = "discharging"
            if(batteryState() == UIDeviceBatteryState.charging){
                chargingStatus = "charging"
            }
            
            let event = HyperTrackEvent(
                userId:Transmitter.sharedInstance.getUserId()!,
                recordedAt:Date(),
                eventType:"device.power.changed",
                location:nil,
                data : ["charging":chargingStatus,
                        "percentage":batteryLevel * 100,
                        "power_saver" : false
                ]
            )
            event.save()
            requestManager.postEvents(flush:true)
        }
    }
    
    
    func onNetworkStateChanged(state: String,isConnected: Bool){
        
        if(Transmitter.sharedInstance.getUserId() != nil){
            let event = HyperTrackEvent(
                userId:Transmitter.sharedInstance.getUserId()!,
                recordedAt:Date(),
                eventType:"device.radio.changed",
                location:nil,
                data : ["network":state,
                        "state":isConnected,
                        ]
            )
            event.save()
            requestManager.postEvents(flush:true)
        }
    }
    
    func didInfoChangedFor(infoType : String, newValue : String) -> Bool{
        var didChange = true
        let lastKnownInfo = getLastKnownInfo(infoType: infoType)
        if(lastKnownInfo != nil){
            if(lastKnownInfo == newValue){
                didChange = false
            }
        }
        return didChange
    }
    
    
    
}
