//
//  HTStatusCardView.swift
//  Pods
//
//  Created by Ravi Jain on 29/06/17.
//
//

import UIKit

protocol HTStausCardDelegate : class  {
    func didClickedOnActionButton()
}

class HTStatusCardView: UIView {
    
    @IBOutlet weak var status: UILabel!
    @IBOutlet weak var eta: UILabel!
    @IBOutlet weak var distanceLeft: UILabel!
    @IBOutlet weak var phoneButton: UIButton!
    @IBOutlet weak var destination: UILabel!
    @IBOutlet weak var progressView: UIView!
    @IBOutlet weak var arrow: UIImageView!
    @IBOutlet weak var tripIcon: UIImageView!
    
    var expandedCard : ExpandedCard? = nil
    var completedView : CompletedView?
    @IBOutlet weak var touchView: UIView!
    var progressCircle = CAShapeLayer()
    var currentProgress : Double = 0
    var isCardExpanded = false
    weak var statusCardDelegate : HTStausCardDelegate?
    
    override func awakeFromNib() {
        self.shadow()
        addProgressCircle()
        addExpandedCard()
    }
    
    @IBAction func phone(_ sender: Any) {
        if statusCardDelegate != nil {
            self.statusCardDelegate?.didClickedOnActionButton()
        }
    }
    
    func addExpandedCard() {
        let bundle = Settings.getBundle()!
        let expandedCard: ExpandedCard = bundle.loadNibNamed("ExpandedCard", owner: self, options: nil)?.first as! ExpandedCard
        self.expandedCard = expandedCard
        self.addSubview(expandedCard)
        self.sendSubview(toBack: expandedCard)
        self.expandedCard?.frame = CGRect(x: 0, y: 90, width: self.frame.width, height: 155)
        self.clipsToBounds = true
    }
    
    func addCompletedView (){
        let bundle = Settings.getBundle()!
        let completedView: CompletedView = bundle.loadNibNamed("CompletedView", owner: self, options: nil)?.first as! CompletedView
        completedView.alpha = 0
        
        self.addSubview(completedView)
        self.bringSubview(toFront: completedView)
        self.bringSubview(toFront: phoneButton)
        
        completedView.frame = CGRect(x: 0, y: 90, width: self.frame.width, height: 155)
        self.completedView = completedView
        self.clipsToBounds = true
    }
    
    func addProgressCircle() {
        
        let circlePath = UIBezierPath(ovalIn: progressView.bounds.insetBy(dx: 5 / 2.0, dy: 5 / 2.0))
        
        progressCircle = CAShapeLayer ()
        progressCircle.path = circlePath.cgPath
        progressCircle.strokeColor = htblack.cgColor
        progressCircle.fillColor = grey.cgColor
        progressCircle.lineWidth = 2.5
        
        progressView.layer.insertSublayer(progressCircle, at: 0)
        
        animateProgress(to: 0)
    }
    
    public func reloadWithUpdatedInfo(_ statusInfo:HTStatusCardInfo){
        self.completedView?.removeFromSuperview()
        // Make InfoView visible
        self.isHidden = false
        
        var progress: Double = 1.0
        
        if let image = statusInfo.infoCardImage {
            phoneButton.setBackgroundImage(image, for: .normal)
        
        } else {
            let bundle = Bundle(for: HTStatusCardView.self)
            let image =  UIImage.init(named: "phone", in: bundle, compatibleWith: nil)
            phoneButton.setBackgroundImage(image, for: .normal)
            
        }
        
        if (statusInfo.showActionDetailSummary) {
            // Update eta & distance data
            self.eta.text = "\(Int(statusInfo.timeElapsedMinutes)) min"
            self.distanceLeft.text = "\(statusInfo.distanceCovered) \(statusInfo.distanceUnit)"
            
            if (statusInfo.distanceLeft != nil) {
                progress = statusInfo.distanceCovered / (statusInfo.distanceCovered + statusInfo.distanceLeft!)
            }
            
        } else {
            if (statusInfo.etaMinutes != nil) {
                self.eta.text = "ETA \(Int(statusInfo.etaMinutes!)) min"
            } else {
                self.eta.text = " "
            }
            
            if (statusInfo.distanceLeft != nil) {
                if (eta != nil) {
                    self.distanceLeft.text = "(\(statusInfo.distanceLeft!) mi)"
                } else {
                    self.distanceLeft.text = "\(statusInfo.distanceLeft!) mi"
                }
            } else {
                self.distanceLeft.text = ""
            }
        }
        
        self.status.text = statusInfo.status
        animateProgress(to: progress)
        
        UIView.animate(withDuration: 0.15) {
            self.layoutIfNeeded()
        }
        
        if let expandedCard = self.expandedCard {
            
            expandedCard.name.text = statusInfo.userName
            
            if let photo = statusInfo.photoUrl {
                /*
                 if (self.downloadedPhotoUrl == nil) || (self.downloadedPhotoUrl != photo) {
                 expandedCard.photo.image = getImage(photoUrl: photo)
                 }
                 */
            }
            
            if (statusInfo.showActionDetailSummary) {
                self.completeActionView(startTime: statusInfo.startTime, endTime: statusInfo.endTime,
                                        origin: statusInfo.startAddress, destination: statusInfo.completeAddress,
                                        timeElapsed: statusInfo.timeElapsedMinutes,
                                        distanceCovered: statusInfo.distanceCovered,
                                        showExpandedCardOnCompletion: statusInfo.showExpandedCardOnCompletion)
            } else {
                let timeInSeconds = Int(statusInfo.timeElapsedMinutes * 60.0)
                let hours = timeInSeconds / 3600
                let minutes = (timeInSeconds / 60) % 60
                let seconds = timeInSeconds % 60
                
                expandedCard.timeElapsed.text = String(format: "%0.2d:%0.2d:%0.2d", hours, minutes, seconds)
                expandedCard.distanceTravelled.text = "\(statusInfo.distanceCovered) \(statusInfo.distanceUnit)"
                
                if (statusInfo.speed != nil) {
                    if (statusInfo.distanceUnit == "mi") {
                        expandedCard.speed.text = "\(statusInfo.speed!) mph"
                    } else {
                        expandedCard.speed.text = "\(statusInfo.speed!) kmph"
                    }
                } else {
                    expandedCard.speed.text = "--"
                }
                
                if (statusInfo.battery != nil) {
                    expandedCard.battery.text = "\(Int(statusInfo.battery!))%"
                } else {
                    expandedCard.battery.text = "--"
                }
                
                let lastUpdatedMins = Int(-1 * Double(statusInfo.lastUpdated.timeIntervalSinceNow) / 60.0)
                
                if (lastUpdatedMins < 1) {
                    expandedCard.lastUpdated.text = "Last updated: few seconds ago"
                } else {
                    expandedCard.lastUpdated.text = "Last updated: \(lastUpdatedMins) min ago"
                }
            }
        }
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
    }
    
    private func completeActionView(startTime: Date?, endTime: Date?,
                                    origin: String?, destination: String?,
                                    timeElapsed: Double, distanceCovered: Double,
                                    showExpandedCardOnCompletion: Bool) {
        //   guard statusCardEnabled else { return }
        
        addCompletedView()
        completedView?.completeUpdate(startTime: startTime, endTime: endTime, origin: origin, destination: destination)
        
        //        if (showExpandedCardOnCompletion) {
        self.touchView.isHidden = true
        self.isCardExpanded = true
        self.completedView?.alpha = 1
        self.arrow.alpha = 0
    }
    
    func setIsExpanded(_ isExpanded : Bool){
        if(isExpanded){
        }
        else{
        }
    }
}
