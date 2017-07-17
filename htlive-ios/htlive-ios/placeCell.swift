//
//  placeItem.swift
//  htlive-ios
//
//  Created by Vibes on 7/11/17.
//  Copyright © 2017 PZRT. All rights reserved.
//

import Foundation
import UIKit
import HyperTrack

class placeCell : UITableViewCell {
    
    @IBOutlet weak var startTime: UILabel!
    @IBOutlet weak var endTime: UILabel!
    @IBOutlet weak var activityIcon: UIImageView!
    @IBOutlet weak var status: UILabel!
    @IBOutlet weak var stats: UILabel!
    
    
    func setStats(activity : HyperTrackActivity) {
        
        self.startTime.text = activity.startedAt?.toString(dateFormat: "HH:mm")
        self.endTime.text = activity.endedAt?.toString(dateFormat: "HH:mm")
        if activity.activity == nil {
            
            self.status.text = "Stop"
            self.stats.text = "xx min"
            
        } else {
            
            self.status.text = activity.activity
            guard let distance = activity.distance else { return }
            let distanceKM : Double = Double(distance)/1000
            self.stats.text = "\(distanceKM) km"
        }
        
//                print(activity.type)
//                print(activity.distance)
//                print(activity.place?.address)
//                print(activity.activity)
//                print("")
        
    
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
}
