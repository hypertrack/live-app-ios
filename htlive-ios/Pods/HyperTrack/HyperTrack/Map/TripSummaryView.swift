//
//  TripSummaryView.swift
//  HyperTrack
//
//  Created by Ravi Jain on 8/9/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import UIKit

protocol TripSummaryViewDelegate {
    func onDoneClicked(view : TripSummaryView)
}

class TripSummaryView: UIView {

    @IBOutlet weak var myNameLabel: UILabel!
    @IBOutlet weak var myTimeElapsedLabel: UILabel!
    @IBOutlet weak var myDistanceTravelledLabel: UILabel!
    @IBOutlet weak var mySpeedLabel: UILabel!
    @IBOutlet weak var myStatus: UILabel!
    @IBOutlet weak var myImage: UIImageView!

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var timeElapsedLabel: UILabel!
    @IBOutlet weak var distanceTravelledLabel: UILabel!
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var status: UILabel!
    @IBOutlet weak var image: UIImageView!

    var myProgressCircleStrokeColor = pink
    var myProgressCircleFillColor = grey
    @IBOutlet weak var myProgressCentreImage: UIImageView!
    
    @IBOutlet weak var myProgressView: UIView!
    var myProgressCircle = CAShapeLayer()
    var myCurrentProgress : Double = 0

    var progressCircleStrokeColor = pink
    var progressCircleFillColor = grey
    @IBOutlet weak var progressCentreImage: UIImageView!
    
    @IBOutlet weak var progressView: UIView!
    var progressCircle = CAShapeLayer()
    var currentProgress : Double = 0
    var delegate : TripSummaryViewDelegate? = nil
    var action : HyperTrackAction? = nil
    @IBAction func onDoneClicked(_ sender: Any) {
        if let del = self.delegate{
            del.onDoneClicked(view: self)
        }
    }
    
    func updateSection(statusInfo : HTStatusCardInfo,index:Int){
        if (index == 0){
            updateSection1(statusInfo: statusInfo)
        }else if (index == 1){
            updateSection2(statusInfo: statusInfo)
        }
    }
    
    func addProgressCircle() {
        var circlePath = UIBezierPath(ovalIn: progressView.bounds.insetBy(dx: 5 / 2.0, dy:  5 / 2.0))
        
        progressCircle = CAShapeLayer ()
        progressCircle.path = circlePath.cgPath
        progressCircle.strokeColor = progressCircleStrokeColor.cgColor
        progressCircle.fillColor = grey.cgColor
        progressCircle.lineWidth = 2
        
        progressView.layer.insertSublayer(progressCircle, at: 0)
        animateProgress(to: 0,from:0,circle: progressCircle)

        circlePath = UIBezierPath(ovalIn: myProgressView.bounds.insetBy(dx: 5 / 2.0, dy:  5 / 2.0))
        
        myProgressCircle = CAShapeLayer ()
        myProgressCircle.path = circlePath.cgPath
        myProgressCircle.strokeColor = progressCircleStrokeColor.cgColor
        myProgressCircle.fillColor = grey.cgColor
        myProgressCircle.lineWidth = 2
        
        myProgressView.layer.insertSublayer(myProgressCircle, at: 0)
        animateProgress(to: 0,from:0,circle: myProgressCircle)
    }
    
    func animateProgress(to : Double,from: Double, circle : CAShapeLayer ) {
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = from
        animation.toValue = to
        animation.duration = 0.5
        animation.fillMode = kCAFillModeForwards
        animation.isRemovedOnCompletion = false
        
        circle.add(animation, forKey: "ani")
        self.currentProgress = to
        
        UIView.animate(withDuration: 0.15) {
            self.layoutIfNeeded()
        }
        
    }

    
    func updateSection1(statusInfo : HTStatusCardInfo){
        
        self.myNameLabel.text = statusInfo.userName
        self.myImage.image = statusInfo.progressCardImage
        
        if (statusInfo.speed != nil) {
            if (statusInfo.distanceUnit == "mi") {
                self.mySpeedLabel.text = "\(statusInfo.speed!) mph"
            } else {
                self.mySpeedLabel.text = "\(statusInfo.speed!) kmph"
            }
        } else {
            self.mySpeedLabel.text = "--"
        }
        
        self.myProgressCentreImage.image = statusInfo.progressCardImage
        
        if let color = statusInfo.progressStrokeColor{
            myProgressCircle.strokeColor = color.cgColor
        }
        self.myTimeElapsedLabel.text = "\(Int(statusInfo.timeElapsedMinutes)) min"
        self.myDistanceTravelledLabel.text = "\(statusInfo.distanceCovered) \(statusInfo.distanceUnit)"
        
        var progress: Double = 1.0
        
        if(statusInfo.timeElapsedMinutes != 0 && statusInfo.distanceCovered != 0){
            let speed = statusInfo.distanceCovered / statusInfo.timeElapsedMinutes
            if (statusInfo.distanceUnit == "mi") {
                self.mySpeedLabel.text = "\(speed.roundTo(places: 1)) mph"
            } else {
                self.mySpeedLabel.text = "\(speed.roundTo(places: 1)) kmph"
            }
        }

        if (statusInfo.showActionDetailSummary) {
            if (statusInfo.distanceLeft != nil) {
                progress = statusInfo.distanceCovered / (statusInfo.distanceCovered + statusInfo.distanceLeft!)
            }
        }
        
        if (statusInfo.distanceLeft != nil) {
            progress = statusInfo.distanceCovered / (statusInfo.distanceCovered + statusInfo.distanceLeft!)
        }

        animateProgress(to: progress, from: self.myCurrentProgress, circle: self.myProgressCircle)
        self.myCurrentProgress = progress
        
    }
    
    
    func updateSection2(statusInfo : HTStatusCardInfo){
        
        self.nameLabel.text = statusInfo.userName
        self.image.image = statusInfo.progressCardImage
        
        if (statusInfo.speed != nil) {
            if (statusInfo.distanceUnit == "mi") {
                self.speedLabel.text = "\(statusInfo.speed!) mph"
            } else {
                self.speedLabel.text = "\(statusInfo.speed!) kmph"
            }
        } else {
            self.speedLabel.text = "--"
        }
        
        self.progressCentreImage.image = statusInfo.progressCardImage
        
        if let color = statusInfo.progressStrokeColor{
            progressCircle.strokeColor = color.cgColor
        }
        
        
        if(statusInfo.timeElapsedMinutes != 0 && statusInfo.distanceCovered != 0){
            let speed = statusInfo.distanceCovered / statusInfo.timeElapsedMinutes
            if (statusInfo.distanceUnit == "mi") {
                self.speedLabel.text = "\(speed.roundTo(places: 1)) mph"
            } else {
                self.speedLabel.text = "\(speed.roundTo(places: 1)) kmph"
            }
        }
        
        self.timeElapsedLabel.text = "\(Int(statusInfo.timeElapsedMinutes)) min"
        self.distanceTravelledLabel.text = "\(statusInfo.distanceCovered) \(statusInfo.distanceUnit)"
        
        var progress: Double = 1.0
        
        if (statusInfo.showActionDetailSummary) {
            if (statusInfo.distanceLeft != nil) {
                progress = statusInfo.distanceCovered / (statusInfo.distanceCovered + statusInfo.distanceLeft!)
            }
        }
        
        if (statusInfo.distanceLeft != nil) {
            progress = statusInfo.distanceCovered / (statusInfo.distanceCovered + statusInfo.distanceLeft!)
        }

        animateProgress(to: progress, from: self.currentProgress, circle: self.progressCircle)
        self.currentProgress = progress

        
    }
    
    override func awakeFromNib() {
        self.layer.cornerRadius =  (self.frame.width) / (15.0)
        self.layer.masksToBounds = true
        addProgressCircle()
    }

}

