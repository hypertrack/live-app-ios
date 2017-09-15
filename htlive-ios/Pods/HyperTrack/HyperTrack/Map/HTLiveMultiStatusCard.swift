//
//  HTLiveMultiStatusCard.swift
//  Pods
//
//  Created by Ravi Jain on 8/3/17.
//
//

import UIKit

class HTLiveMultiStatusCard: UIView {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var etaLabel: UILabel!
    @IBOutlet weak var timeElapsedLabel: UILabel!
    @IBOutlet weak var distanceTravelledLabel: UILabel!
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var batteryLabel : UILabel!
    @IBOutlet weak var section1 : UIView!
    @IBOutlet weak var section2 : UIView!
    @IBOutlet weak var section3 : UIView!

    var progressCircleStrokeColor = pink
    var progressCircleFillColor = grey
    @IBOutlet weak var progressCentreImage: UIImageView!

    @IBOutlet weak var progressView: UIView!
    var progressCircle = CAShapeLayer()
    var currentProgress : Double = 0

    @IBOutlet weak var section1HeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var section2Constraint: NSLayoutConstraint!
    var userId : String?
    var isShrinked = true
    var initialFrame : CGRect? = nil
    var statusDelegate : StatusViewDelegate? = nil
    
    override func awakeFromNib() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapGestureRecognized))
        self.addGestureRecognizer(tapGesture)
        shrink()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
            self.addProgressCircle()
        })
    }
    
    @objc fileprivate func tapGestureRecognized(gestureRecognizer: UITapGestureRecognizer) {
        if(isShrinked){
            expand()
        }else{
            shrink()
        }
    }

    func addProgressCircle() {
        let circlePath = UIBezierPath(ovalIn: progressView.bounds.insetBy(dx: 5 / 2.0, dy:  5 / 2.0))
        
        progressCircle = CAShapeLayer ()
        progressCircle.path = circlePath.cgPath
        progressCircle.strokeColor = progressCircleStrokeColor.cgColor
        progressCircle.fillColor = grey.cgColor
        progressCircle.lineWidth = 2
        
        progressView.layer.insertSublayer(progressCircle, at: 0)
        
        animateProgress(to: 0)
    }
    
    func animateProgress(to : Double) {
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = currentProgress
        animation.toValue = to
        animation.duration = 0.5
        animation.fillMode = kCAFillModeForwards
        animation.isRemovedOnCompletion = false
        
        progressCircle.add(animation, forKey: "ani")
        self.currentProgress = to
        
        UIView.animate(withDuration: 0.15) {
            self.layoutIfNeeded()
        }
        
    }

    
    func shrink(){
        if let delegate = self.statusDelegate {
            delegate.willShrink(view: self)
        }
        isShrinked = true
        self.bringSubview(toFront: section1)
        section3.isHidden = true
        section2.isHidden = true
        self.frame.size.height = 71
        self.frame.origin.y = self.frame.origin.y + (161 - 71)
        section1HeightConstraint =  Constraint.changeMultiplier(section1HeightConstraint, multiplier: 1)
        self.needsUpdateConstraints()
        if let delegate = self.statusDelegate {
            delegate.didShrink(view: self)
        }
    }
    
    func expand(){
        if let delegate = self.statusDelegate {
            delegate.willExpand(view: self)
        }
        isShrinked = false
        
        self.bringSubview(toFront: section1)
        self.frame.size.height = 161
        self.frame.origin.y = self.frame.origin.y - (161 - 71)
        section3.isHidden = false
        section2.isHidden = false
        section1HeightConstraint =  Constraint.changeMultiplier(section1HeightConstraint, multiplier: 71.0/161.0)
        section2Constraint.isActive = true

        section2Constraint = Constraint.changeMultiplier(section2Constraint, multiplier: 45.0/161.0)
        self.needsUpdateConstraints()
        if let delegate = self.statusDelegate {
            delegate.didExpand(view: self)
        }

    }
    
    func updateView(statusInfo : HTStatusCardInfo){
        
        if (statusInfo.speed != nil) {
            if (statusInfo.distanceUnit == "mi") {
                self.speedLabel.text = "\(statusInfo.speed!) mph"
            } else {
                self.speedLabel.text = "\(statusInfo.speed!) kmph"
            }
        } else {
            self.speedLabel.text = "--"
        }
        
        if (statusInfo.battery != nil) {
            self.batteryLabel.text = "\(Int(statusInfo.battery!))%"
        } else {
            self.batteryLabel.text = "--"
        }

        if (statusInfo.etaMinutes != nil) {
            self.etaLabel.text = "\(Int(statusInfo.etaMinutes!)) min away"
        } else {
            self.etaLabel.text = "- min away "
        }

        self.progressCentreImage.image = statusInfo.progressCardImage
        if let color = statusInfo.progressStrokeColor{
            progressCircle.strokeColor = color.cgColor
        }
        
        self.nameLabel.text = statusInfo.markerUserName
        
        if statusInfo.markerUserName == "" {
            self.nameLabel.text = "Friend"
        }

        self.timeElapsedLabel.text = "\(Int(statusInfo.timeElapsedMinutes)) min"
        self.distanceTravelledLabel.text = "\(statusInfo.distanceCovered) \(statusInfo.distanceUnit)"
        
        var progress: Double = 0.0
        
        if (statusInfo.showActionDetailSummary) {
            // Update eta & distance data
            self.etaLabel.text =  statusInfo.display?.statusText

            if (statusInfo.distanceLeft != nil) {
                progress = statusInfo.distanceCovered / (statusInfo.distanceCovered + statusInfo.distanceLeft!)
            }else{
                progress  = 1
            }
            
            
        }
        
        if (statusInfo.distanceLeft != nil) {
            progress = statusInfo.distanceCovered / (statusInfo.distanceCovered + statusInfo.distanceLeft!)
        }
        
        animateProgress(to: progress)
    }
}

struct Constraint {
    static func changeMultiplier(_ constraint: NSLayoutConstraint, multiplier: CGFloat) -> NSLayoutConstraint {
        let newConstraint = NSLayoutConstraint(
            item: constraint.firstItem,
            attribute: constraint.firstAttribute,
            relatedBy: constraint.relation,
            toItem: constraint.secondItem,
            attribute: constraint.secondAttribute,
            multiplier: multiplier,
            constant: constraint.constant)
        
        newConstraint.priority = constraint.priority
        
        NSLayoutConstraint.deactivate([constraint])
        NSLayoutConstraint.activate([newConstraint])
        
        return newConstraint
    }
}
