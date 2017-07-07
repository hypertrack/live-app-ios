//
//  HTView.swift
//  HyperTrack
//
//  Created by Vibes on 5/24/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import UIKit
import MapKit

class HTView: UIView {
  @IBOutlet weak var mapView: UIView!
  @IBOutlet weak var reFocusButton: UIButton!
  @IBOutlet weak var backButton: UIButton!
  @IBOutlet weak var destinationView: UIView!
  @IBOutlet weak var statusCard: UIView!
  @IBOutlet weak var status: UILabel!
  @IBOutlet weak var eta: UILabel!
  @IBOutlet weak var distanceLeft: UILabel!
  @IBOutlet weak var phoneButton: UIButton!
  @IBOutlet weak var destination: UILabel!
  @IBOutlet weak var progressView: UIView!
  
  var delegate: HTViewInteractionDelegate?
  
  var progressCircle = CAShapeLayer()
  var currentProgress : Double = 0
  
  @IBAction func phone(_ sender: Any) {
    
  }
  
  @IBAction func back(_ sender: Any) {
    self.delegate?.backButtonClicked(sender)
  }
  
  @IBAction func reFocus(_ sender: Any) {
    self.delegate?.refocusButtonClicked(sender)
  }
  
  override func awakeFromNib() {
    destinationView.shadow()
    statusCard.shadow()
    addProgressCircle()
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
  
  func initMapView(mapSubView: MKMapView, delegate: HTViewInteractionDelegate) {
      self.mapView.addSubview(mapSubView)
      self.delegate = delegate;
    
      self.clearView()
  }
  
  func customize( reFocusButon : Bool, backButton : Bool, statusCard : Bool, destinationCard : Bool) {
    
    self.reFocusButton.isHidden = !reFocusButon
    self.backButton.isHidden = !backButton
    self.statusCard.isHidden = !statusCard
    self.destinationView.isHidden = !destinationCard
    
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

  func updateStats( destination : String , eta : Double, distanceCovered : Double, status : String, timeElapsed : Double, isCompleted: Bool ) {
    self.statusCard.isHidden = false
    
    if isCompleted {
        self.eta.text = "\(Int(timeElapsed)) Min"
    } else {
        self.eta.text = "ETA \(Int(eta)) Min"
    }

    self.distanceLeft.text = "\(distanceCovered) Mi"
    self.status.text = status

    let progress = timeElapsed/(eta+timeElapsed)
    
    animateProgress(to: progress)
    
    UIView.animate(withDuration: 0.15) {
      self.layoutIfNeeded()
    }

    self.destinationView.isHidden = false
    self.destination.text = destination
    self.reFocusButton.isHidden = false
  }
  
    func clearView() {
      self.destinationView.isHidden = true
      self.statusCard.isHidden = true
      self.reFocusButton.isHidden = true
    }
}
