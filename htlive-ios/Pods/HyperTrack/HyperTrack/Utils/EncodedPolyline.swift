//
//  EncodedPolyline.swift
//  HyperTrack
//
//  Created by Arjun Attam on 26/05/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import Foundation
import CoreLocation

func decodePolyline(_ encodedPolyline: String, precision: Double = 1e5) -> [CLLocationCoordinate2D]? {
  
  let data = encodedPolyline.data(using: String.Encoding.utf8)!
  
  let byteArray = (data as NSData).bytes.assumingMemoryBound(to: Int8.self)
  let length = Int(data.count)
  var position = Int(0)
  
  var decodedCoordinates = [CLLocationCoordinate2D]()
  
  var lat = 0.0
  var lon = 0.0
  
  while position < length {
    
    do {
      let resultingLat = try decodeSingleCoordinate(byteArray: byteArray, length: length, position: &position, precision: precision)
      lat += resultingLat
      
      let resultingLon = try decodeSingleCoordinate(byteArray: byteArray, length: length, position: &position, precision: precision)
      lon += resultingLon
    } catch {
      return nil
    }
    
    decodedCoordinates.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
  }
  
  return decodedCoordinates
}

private func decodeSingleCoordinate(byteArray: UnsafePointer<Int8>, length: Int, position: inout Int, precision: Double = 1e5) throws -> Double {
  
  guard position < length else {
    HTLogger.shared.verbose("Polyline position is less than length")
    return 0.0
  }
  
  let bitMask = Int8(0x1F)
  
  var coordinate: Int32 = 0
  
  var currentChar: Int8
  var componentCounter: Int32 = 0
  var component: Int32 = 0
  
  repeat {
    currentChar = byteArray[position] - 63
    component = Int32(currentChar & bitMask)
    coordinate |= (component << (5*componentCounter))
    position += 1
    componentCounter += 1
  } while ((currentChar & 0x20) == 0x20) && (position < length) && (componentCounter < 6)
  
  if (componentCounter == 6) && ((currentChar & 0x20) == 0x20) {
    HTLogger.shared.verbose("Polyline decoder has an error")
  }
  
  if (coordinate & 0x01) == 0x01 {
    coordinate = ~(coordinate >> 1)
  } else {
    coordinate = coordinate >> 1
  }
  
  return Double(coordinate) / precision
}
