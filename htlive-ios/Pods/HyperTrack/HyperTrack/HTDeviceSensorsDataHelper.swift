//
//  HTMotionHelper.swift
//  HyperTrack
//
//  Created by Ravi Jain on 8/5/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import UIKit
import CoreMotion

protocol HTDeviceSensorDelegate : class {
    func didRecieveGyroData(gyroData:CMGyroData)
    func didRecieveAccelerometerData(accelerometerData:CMAccelerometerData)
    func didRecieveDeviceMotionData(deviceMotionData:CMDeviceMotion)
}

class HTDeviceSensorsDataHelper: NSObject {
    
    let motionManager = CMMotionManager()
    weak var delegate : HTDeviceSensorDelegate? = nil
    
    func getAccelerometerUpdates(onlyOnce: Bool,
                                 withHandler handler: @escaping CMAccelerometerHandler){
        
        if(self.motionManager.isAccelerometerAvailable){
            self.motionManager.accelerometerUpdateInterval = 0.1
            self.motionManager.startAccelerometerUpdates(to: OperationQueue.main) { (data, error) in
                handler(data,error)
                if let data  = data {
                    if let delegate = self.delegate{
                        delegate.didRecieveAccelerometerData(accelerometerData: data)
                    }
                }
               
                if (onlyOnce){
                    self.stopAccelerometerUpdates()
                }
            }
        }else{
            let error = CustomError.init(localizedTitle: "AccelerometerDataNotAvailable", localizedDescription: "", code: 0)
            handler(nil,error)
        }
    }

    
    
    func getGyroUpdates(onlyOnce : Bool,
                        withHandler handler: @escaping CMGyroHandler){
       
        if(self.motionManager.isGyroAvailable){
            self.motionManager.gyroUpdateInterval = 0.1
            self.motionManager.startGyroUpdates(to: OperationQueue.main, withHandler: { (data, error) in
                handler(data,error)
                if let data  = data {
                    if let delegate = self.delegate{
                        delegate.didRecieveGyroData(gyroData: data)
                    }
                }
                if (onlyOnce){
                    self.stopGyroUpdates()
                }
            })
        }else{
            let error = CustomError.init(localizedTitle: "GyroDataNotAvailable", localizedDescription: "", code: 0)
            handler(nil,error)
        }
    }
    
    func getDeviceMotionUpdates(onlyOnce : Bool,
                                  withHandler handler: @escaping CMDeviceMotionHandler){
        if(self.motionManager.isDeviceMotionActive){
            self.motionManager.deviceMotionUpdateInterval = 0.1
            self.motionManager.startDeviceMotionUpdates(to: OperationQueue.main, withHandler: { (data, error) in
                handler(data,error)
                if let data  = data {
                    if let delegate = self.delegate{
                        delegate.didRecieveDeviceMotionData(deviceMotionData: data)
                    }
                }

                if (onlyOnce){
                    self.stopDeviceMotionUpdates()
                }

            })
        }else{
            let error = CustomError.init(localizedTitle: "DeviceMotionDataNotAvailable", localizedDescription: "", code: 0)
            handler(nil,error)
        }
    }
    
    
    func stopAccelerometerUpdates(){
        self.motionManager.stopAccelerometerUpdates()
    }
    
    func stopGyroUpdates(){
        self.motionManager.stopGyroUpdates()
    }
    
    func stopDeviceMotionUpdates() {
        self.motionManager.stopDeviceMotionUpdates()
    }
    
    func stopmagnetometerUpdates() {
        self.motionManager.stopMagnetometerUpdates()
    }

}


struct CustomError: Error {
    
    var localizedTitle: String
    var localizedDescription: String
    var code: Int
    
    init(localizedTitle: String?, localizedDescription: String, code: Int) {
        self.localizedTitle = localizedTitle ?? "Error"
        self.localizedDescription = localizedDescription
        self.code = code
    }
}
