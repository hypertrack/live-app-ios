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
    
    @IBOutlet weak var icon: UIImageView!
    
    @IBOutlet weak var placeCard: UIView!
    
    func loading() {
        
        self.startTime.text = "- : -"
        self.endTime.text = "- : -"
        self.stats.text = "Hang tight"
        self.status.text = "Loading Placeline.."
        self.icon.image = nil
        addRefresher()
        
    }
    
    func noResults() {
        
        self.startTime.text = "- : -"
        self.endTime.text = "- : -"
        self.stats.text = "No placeline today "
        self.status.text = "Nothing here yet!"
        self.icon.image = #imageLiteral(resourceName: "ninja")
        
    }
    
    func addRefresher() {
        
        let refresher = UIActivityIndicatorView(frame : CGRect(x: 100, y: 23, width: 20, height: 20))
        refresher.color = .black
        
        refresher.layer.masksToBounds = false
        refresher.layer.shadowColor = UIColor.white.cgColor
        refresher.layer.shadowOpacity = 0
        refresher.layer.opacity = 0.5
        refresher.layer.shadowOffset = CGSize(width: 0, height: 1)
        refresher.layer.shadowRadius = 0
        
        refresher.layer.shadowPath = UIBezierPath(rect: self.bounds).cgPath
        refresher.layer.shouldRasterize = true
        
        refresher.startAnimating()
        
        self.addSubview(refresher)
        
    }
    
    func select() {
        guard self.status.text != "Loading Placeline.." else { return }
        UIView.transition(with: placeCard, duration: 0.1, options: .transitionCrossDissolve, animations: {
            self.status.textColor = UIColor.white
            self.placeCard.backgroundColor = pink
        }, completion: nil)
        
    
    }
    
    func deselect() {
        
        UIView.transition(with: placeCard, duration: 0.05, options: .transitionCrossDissolve, animations: {
            self.status.textColor = UIColor.black
            self.placeCard.backgroundColor = UIColor.white
        }, completion: nil)
    }
    
    func normalize() {
        
        self.status.textColor = UIColor.black
        self.placeCard.backgroundColor = UIColor.white
    }
    
    func setStats(activity : HyperTrackActivity) {
        
        self.startTime.text = activity.startedAt?.toString(dateFormat: "HH:mm")
        self.endTime.text = activity.endedAt?.toString(dateFormat: "HH:mm")
        if activity.activity == nil {
            
            self.status.text = "Stop"
            self.icon.image = #imageLiteral(resourceName: "stop")
            self.stats.text = activity.place?.address
            
        } else {
            
            self.status.text = activity.activity
            if activity.activity == "Walk" { self.icon.image = #imageLiteral(resourceName: "walk") }
            if activity.activity == "Drive" { self.icon.image = #imageLiteral(resourceName: "driving")}

            
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
