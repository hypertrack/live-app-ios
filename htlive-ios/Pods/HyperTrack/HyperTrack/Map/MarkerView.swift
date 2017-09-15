//
//  MarkerView.swift
//
//
//  Created by Vibes on 5/18/17.
//
//

import Foundation
import UIKit

class MarkerView : UIView {
    
    @IBOutlet weak var heroMarkerIcon: UIImageView!
    
    @IBOutlet weak var radiationCircle: UIImageView!
    
    @IBOutlet weak var radiationSize: NSLayoutConstraint!
    
    @IBOutlet weak var annotationLabel : UILabel!
    
    @IBOutlet weak var subtitleLabel : UILabel!

    override func awakeFromNib() {
        radiate()
    }
    
    func radiate() {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(0), execute: {
            
            UIView.animate(withDuration: 2, delay: 0, options: [.repeat], animations: {
                self.radiationCircle.transform = CGAffineTransform(scaleX: 30, y: 30)
                self.radiationCircle.alpha = 0
            }, completion: { (hello) in
                self.radiationCircle.alpha = 1
                self.radiationCircle.transform = CGAffineTransform(scaleX: 0, y: 0)
            })
        })
    }
    
    func stopRadiation() {
        radiationCircle.layer.removeAllAnimations()
    }
}
