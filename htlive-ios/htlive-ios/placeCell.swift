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
    
    @IBOutlet weak var activityIcon: UIImageView!
    @IBOutlet weak var status: UILabel!
    @IBOutlet weak var stats: UILabel!
    
    @IBOutlet weak var icon: UIImageView!
    
    @IBOutlet weak var placeCard: UIView!
    @IBOutlet weak var circleView: UIView!
    @IBOutlet weak var startLabel: UILabel!

    func loading() {
        self.startLabel.text = "- : -"
        self.stats.text = "Hang tight"
        self.status.text = "Loading Placeline.."
        self.icon.image = nil
        addRefresher()
        
    }
    
    func noResults() {
        self.startLabel.text = "- : -"
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
        guard self.status.text != "Nothing here yet!" else { return }

        
        UIView.transition(with: placeCard, duration: 0.1, options: .transitionCrossDissolve, animations: {
            self.status.textColor = UIColor.white
            self.placeCard.backgroundColor = pink
        }, completion: nil)
        
        circleView.backgroundColor = UIColor.white;
    }
    
    func deselect() {
        
        UIView.transition(with: placeCard, duration: 0.05, options: .transitionCrossDissolve, animations: {
            self.status.textColor = UIColor.black
            self.placeCard.backgroundColor = UIColor.white
        }, completion: nil)
        
        circleView.backgroundColor = pink

        
    }
    
    func normalize() {
        circleView.backgroundColor = pink
        self.status.textColor = UIColor.black
        self.placeCard.backgroundColor = UIColor.white
    }
    
    func setStats(activity : HyperTrackActivity?) {
        
        if activity == nil {
            self.stats.text = ""
            self.startLabel.text = ""
            self.icon.image = nil
            return
        }
        
        if let activity = activity {
            self.stats.text = ""
            self.startLabel.text = activity.startedAt?.toString(dateFormat: "h:mm a")
            self.icon.image = nil
            
            if activity.activity == nil {
                self.status.text = "Stop"
                self.icon.image = #imageLiteral(resourceName: "stop")
                self.stats.text = activity.place?.address
                
            } else {
                
                self.status.text = activity.activity?.firstCharacterUpperCase()
                if activity.activity == "walk" { self.icon.image = #imageLiteral(resourceName: "walk") }
                if activity.activity == "drive" { self.icon.image = #imageLiteral(resourceName: "driving")}
                if activity.activity == "stop" { self.icon.image = #imageLiteral(resourceName: "stop")}

                if activity.activity == "" {
                    self.status.text = "Unknown"
                }
                else if activity.activity == "unknown"{
                    self.status.text = "Unknown"
                }
                
                guard let distance = activity.distance else { return }
                let distanceKM : Double = (Double(distance)/1000.0).roundTo(places: 1)
                var subtitleText = ""
                
                if let startedAt = activity.startedAt {
                    var timeElapsed: Double?
                    
                    if activity.endedAt != nil {
                        timeElapsed = startedAt.timeIntervalSince(activity.endedAt!)
                    } else {
                        timeElapsed = startedAt.timeIntervalSinceNow
                    }
                    
                    let timeElapsedMinutes = Int(floor((-1 * Double(timeElapsed!))))
                    let timeText = self.stringFromTimeInterval(interval: timeElapsedMinutes)
                    
//                    var timeText = "\(timeElapsedMinutes.description) min  "
//                    if (timeElapsedMinutes < 1){
//                        timeText =   "\(Int(-1 * timeElapsed!).description ) sec  "
//                    }
                    subtitleText = subtitleText + timeText
                }
               
                if (activity.activity == "unknown" || activity.activity == ""){
                    if let reason = activity.reason{
                        var reasonStr = activity.reason
                        if reason == "sdk_inactive"{
                            reasonStr = "tracking inactive"
                        }else if reason == "no_activity_permission"{
                            reasonStr = "no activity permission"
                        }
                        else if reason == "diabled"{
                            reasonStr = "location disabled"
                        }else if reason == "no_permission"{
                            reasonStr = "no location permission"
                        }
                        self.stats.text = subtitleText + " | " + (reasonStr ?? "")
                        return
                    }
                    
                    self.stats.text = subtitleText
                    return
                }
                else if (activity.type != "stop")  {
                    subtitleText = subtitleText + " | " + "\(distanceKM.description) km"
                }else{
                    if let address = activity.place?.address{
                        if address != ""{
                            subtitleText = subtitleText + " | " + address
                        }
                    }
                }
                
                self.stats.text = subtitleText
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        circleView.backgroundColor = pink
        circleView.asCircle()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    func stringFromTimeInterval(interval: Int) -> String {
        
        let ti = NSInteger(interval)
        let ms = ti * 1000
        let seconds = ti % 60
        let minutes = (ti / 60) % 60
        let hours = (ti / 3600)
        
        if hours != 0{
            return String(format: "%d hours %d mins",hours, minutes)
        }
        else if minutes != 0{
            return String(format: "%d mins", minutes)
        }
        else if seconds != 0 {
            return String(format: "%d secs", seconds)
        }
        
        return String(format: "%d hours %d mins % secs",hours, minutes, seconds)

    }
}


extension Double {
    /// Rounds the double to decimal places value
    func roundTo(places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}


extension UIView{
    func asCircle(){
        self.layer.cornerRadius = self.frame.width / 2;
        self.layer.masksToBounds = true
    }
}

extension String {
    func firstCharacterUpperCase() -> String {
        let lowercaseString = self.lowercased()
        if lowercaseString.lengthOfBytes(using: .utf8) > 0{
            let index = self.index(self.startIndex, offsetBy: 1)
            var subString = self.substring(to: index)
            if subString != nil {
                subString = subString.uppercased()
            }
            
            let endStringIndex = self.index(self.startIndex, offsetBy: 1)
            var endString =  self.substring(from: endStringIndex)  // playground
            if endString != nil {
                endString = endString.lowercased()
            }
            
            return subString + endString
        }
        
        return self
    }
}
