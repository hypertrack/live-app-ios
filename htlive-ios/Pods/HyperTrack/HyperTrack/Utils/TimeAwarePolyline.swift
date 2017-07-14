//
//  TimeAwarePolyline.swift
//  HyperTrack
//
//  Created by Anil Giri on 10/05/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import Foundation
import CoreLocation

struct TimeAwarePolyline {
    
    public let stringRepresentation: String
    public let locations: [TimedCoordinates]?
    let prec: Double
    
    public init(_ string: String, precision: Double = 1e5) {
        stringRepresentation = string
        locations = timedCoordinatesFrom(polyline: string)
        prec = precision
    }
    
    public init(_ timedCoordinates: [TimedCoordinates], precision: Double = 1e5) {
        locations = timedCoordinates
        stringRepresentation = timeAwarePolylineFrom(timedCoordinates)
        prec = precision
    }
}

enum TimeAwarePolylineError: Error {
    case malFormedPolylineError
    case positionOutOfBoundsError
}

internal struct TimedCoordinates {
    var location: CLLocationCoordinate2D
    var timeStamp: Date
}

internal func timedCoordinatesToString(coordinate: TimedCoordinates) -> String {
    return "\(coordinate.location.latitude),\(coordinate.location.longitude),\(coordinate.timeStamp.iso8601)"
}

internal func timedCoordinatesFromString(coordinateString: String) -> TimedCoordinates {
    let components = coordinateString.components(separatedBy: ",")
    let location = CLLocationCoordinate2DMake(Double(components[0])!, Double(components[1])!)
    let timeStamp = components[2].dateFromISO8601!
    return TimedCoordinates(location: location, timeStamp: timeStamp)
}

internal func timedCoordinatesToStringArray(coordinates: [TimedCoordinates]) -> String {
    var stringArray:[String] = []
    
    for coordinate in coordinates {
        stringArray.append(timedCoordinatesToString(coordinate: coordinate))
    }
    
    return stringArray.joined(separator: ";")
}

internal func timedCoordinatesFromStringArray(coordinatesString: String) -> [TimedCoordinates] {
    let stringArray = coordinatesString.components(separatedBy: ";")
    var coordinates:[TimedCoordinates] = []
    
    for coordinateString in stringArray {
        coordinates.append(timedCoordinatesFromString(coordinateString: coordinateString))
    }
    
    return coordinates
}

internal func timedCoordinatesFrom(polyline: String, precision: Double = 1e5) -> [TimedCoordinates]? {
    
    let stringData = polyline.data(using: String.Encoding.utf8)!
    
    let byteArray = (stringData as NSData).bytes.assumingMemoryBound(to: Int8.self)
    let length = Int(stringData.count)
    var position = Int(0)
    
    var timedCoordinates = [TimedCoordinates]()
    
    var latitude = 0.0
    var longitude = 0.0
    var date = Date(timeIntervalSince1970: 0)
    
    while position < length {
        do {
            
            let currentDiff = try timedCoordinatesDiffFrom(byteArray: byteArray, length: length, position: position)
            latitude += currentDiff.coordinatesDiff.latitude
            longitude += currentDiff.coordinatesDiff.longitude
            date = date.addingTimeInterval(currentDiff.timeDiff * precision) // The extraction method divides all values by precison, but time is stored as is. So multiply back
            position = currentDiff.nextPostion
        } catch {
            return nil
        }
        
        timedCoordinates.append(TimedCoordinates(location: CLLocationCoordinate2DMake(latitude, longitude), timeStamp: date))
    }
    
    return timedCoordinates
}

internal func timeAwarePolylineFrom(_ timedCoordinates: [TimedCoordinates], precision: Double = 1e5) -> String {
    return "" // TODO: Implement Encoding
}


// MARK Private

func timedCoordinatesDiffFrom(byteArray: UnsafePointer<Int8>, length: Int, position: Int, precision: Double = 1e5) throws -> (coordinatesDiff: CLLocationCoordinate2D, timeDiff: TimeInterval, nextPostion: Int ) {
    
    let latitudeComponent = try decodedSingleDimensionFrom(byteArray: byteArray, length: length, position: position)
    let longitudeComponent = try decodedSingleDimensionFrom(byteArray: byteArray, length: length, position: latitudeComponent.nextPosition)
    let timeComponent = try decodedSingleDimensionFrom(byteArray: byteArray, length: length, position: longitudeComponent.nextPosition)
    
    let nextPosition = timeComponent.nextPosition
    return (CLLocationCoordinate2DMake(latitudeComponent.value, longitudeComponent.value), timeComponent.value, nextPosition)
}

func decodedSingleDimensionFrom(byteArray: UnsafePointer<Int8>, length: Int, position: Int, precision: Double = 1e5) throws -> (value: Double, nextPosition: Int) {
    
    guard position < length else { throw TimeAwarePolylineError.positionOutOfBoundsError }
    
    var currentPosition = position
    let bitMask = Int8(0x1F)
    
    var coordinate: Int64 = 0
    
    var currentCharacter: Int8
    var componentCount: Int64 = 0
    var component: Int64 = 0
    
    repeat {
        currentCharacter = byteArray[currentPosition] - 63
        component = Int64(currentCharacter & bitMask)
        coordinate |= (component << (5*componentCount))
        currentPosition += 1
        componentCount += 1
    } while ((currentCharacter & 0x20) == 0x20) && (currentPosition < length)
    
    if (componentCount == 6) && ((currentCharacter & 0x20) == 0x20) {
        throw TimeAwarePolylineError.malFormedPolylineError
    }
    
    if (coordinate & 0x01) == 0x01 {
        coordinate = ~(coordinate >> 1)
    } else {
        coordinate = coordinate >> 1
    }
    
    return (Double(coordinate) / precision, currentPosition)
}
