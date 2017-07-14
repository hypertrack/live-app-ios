//
//  MKAnnotationView+Transforms.swift
//  HyperTrack
//
//  Created by Anil Giri on 15/05/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import Foundation
import MapKit
import CoreLocation


struct MaxZoomSpan{
  static let latitudeDelta: CLLocationDegrees = 0.0009
  static let longitudeDelta: CLLocationDegrees = 0.0009
}


internal extension MKAnnotationView {

  internal func transformForMapSpan(_ span: MKCoordinateSpan, heading: CLLocationDirection) {
    
    let xSpanRatio = span.latitudeDelta / MaxZoomSpan.latitudeDelta
    let ySpanRatio = span.longitudeDelta / MaxZoomSpan.longitudeDelta
    
    let spanRatio = max(xSpanRatio, ySpanRatio)
    
    if let image = self.image {
        let scaledImage = UIImage(cgImage: image.cgImage!, scale: CGFloat(spanRatio), orientation: UIImageOrientation.up)
        let rotatedImage = scaledImage.imageRotatedByDegrees(degrees: CGFloat(heading))
        self.image = rotatedImage
    }
  }
}

internal extension UIImage {
    
    internal func imageRotatedByDegrees(degrees: CGFloat) -> UIImage {
        
        let degreesToRadians: (CGFloat) -> CGFloat = {
            return $0 * (CGFloat.pi / 180.0)
        }
        
        let finalContainingBox = UIView(frame: CGRect(origin: CGPoint.zero, size: size))
        let rotationTransform = CGAffineTransform(rotationAngle: degreesToRadians(degrees));
        finalContainingBox.transform = rotationTransform
        let rotatedSize = finalContainingBox.frame.size
        
        UIGraphicsBeginImageContext(rotatedSize)
        if let context = UIGraphicsGetCurrentContext() {
            
            context.translateBy(x: rotatedSize.width / 2.0, y: rotatedSize.height / 2.0);
            context.rotate(by: degreesToRadians(degrees))
            context.scaleBy(x: 1.0, y: -1.0)
            
            context.draw(self.cgImage!, in: CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height))
        }
        
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
}
