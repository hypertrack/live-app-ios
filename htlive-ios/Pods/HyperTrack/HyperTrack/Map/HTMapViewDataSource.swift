//
//  HTMapViewDataSource.swift
//  Pods
//
//  Created by Ravi Jain on 04/06/17.
//
//

import UIKit
import MapKit

class HTMapViewDataSource: NSObject {
    
    var shouldBindView = true
    var isInitialLocationPlaced = false
    var isOrderStatusBarEnabled = true
    var isDynamicZoomDisabled = false
    var isTrafficEnabled = true
    
    var mapViewModelList = [String:HTMapViewModel]()
    
    func getMapViewModel(actionId : String) -> HTMapViewModel?{
        return mapViewModelList[actionId]
    }
    
    func getMapViewModel(userId : String) -> HTMapViewModel?{
        return mapViewModelList[userId]
    }
    
    func addMapViewModel(_ actionId : String){
        let mapViewModel = HTMapViewModel()
        mapViewModelList[actionId] = mapViewModel
    }
    
    func removeMapViewModel(actionId : String){
        if  mapViewModelList[actionId] != nil {
            mapViewModelList.removeValue(forKey: actionId)
        }
    }
    
    func clearAllMapViewModels(){
        mapViewModelList.removeAll()
    }

    func setHeroMarker(userId:String,annotation:HTMapAnnotation?){
        var mapViewModel = self.getMapViewModel(userId:userId)
        if (mapViewModel == nil){
            addMapViewModel(userId)
            mapViewModel = self.getMapViewModel(userId:userId)
        }
        mapViewModel?.heroMarker = annotation
        mapViewModel?.type = HTConstants.AnnotationType.USER
    }
    
    func getDestinationMarker(actionId:String) -> HTMapAnnotation?{
        if let mapViewModel = self.getMapViewModel(actionId: actionId){
            return mapViewModel.destinationMarker
        }
        return nil
    }
    
    func setDestinationMarker(actionId:String,annotation:HTMapAnnotation?){
        var mapViewModel = self.getMapViewModel(actionId:actionId)
        if (mapViewModel == nil){
            addMapViewModel(actionId)
            mapViewModel = self.getMapViewModel(actionId:actionId)
        }
        mapViewModel?.destinationMarker = annotation
        mapViewModel?.type = HTConstants.AnnotationType.ACTION
    }
}
