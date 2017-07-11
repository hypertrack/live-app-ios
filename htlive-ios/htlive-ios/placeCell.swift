//
//  placeItem.swift
//  htlive-ios
//
//  Created by Vibes on 7/11/17.
//  Copyright © 2017 PZRT. All rights reserved.
//

import Foundation
import UIKit

class placeCell : UITableViewCell {
    
    @IBOutlet weak var startTime: UILabel!
    @IBOutlet weak var endTime: UILabel!
    @IBOutlet weak var activityIcon: UIImageView!
    @IBOutlet weak var status: UILabel!
    @IBOutlet weak var stats: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
}
