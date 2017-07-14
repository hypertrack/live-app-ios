//
//  CompletedView.swift
//  HyperTrack
//
//  Created by Vibes on 5/31/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import Foundation

class CompletedView : UIView {
    
    @IBOutlet weak var startTime: UILabel!
    @IBOutlet weak var endTime: UILabel!
    @IBOutlet weak var origin: UILabel!
    @IBOutlet weak var destination: UILabel!
    
    func completeUpdate(startTime : Date?, endTime : Date?, origin : String?, destination : String?) {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm a, MMM dd"
        
        if (startTime == nil) {
            self.startTime.text = "--"
        } else {
            self.startTime.text = dateFormatter.string(from: startTime!)
        }
        
        if (endTime == nil) {
            self.endTime.text = "--"
        } else {
            self.endTime.text = dateFormatter.string(from: endTime!)
        }
        
        if (origin == nil) {
            self.origin.text = "--"
        } else {
            self.origin.text = origin
        }
        
        if (destination == nil) {
            self.destination.text = "--"
        } else {
            self.destination.text = destination
        }
    }
}
