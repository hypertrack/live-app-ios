//
//  HTStatusCardInfo.swift
//  Pods
//
//  Created by Ravi Jain on 30/06/17.
//
//

import UIKit

class HTStatusCardInfo: NSObject {

    var userName: String = ""
    var lastUpdated: Date = Date()
    var speed: Int?
    var battery: Int?
    var photoUrl: URL?
    var etaMinutes: Double? = nil
    var distanceLeft: Double? = nil
    var distanceCovered: Double = 0
    var distanceUnit = "mi"
    var status: String = ""
    var timeElapsedMinutes: Double = 0
    var showActionDetailSummary = false
    var showActionPolylineSummary = false
    var showExpandedCardOnCompletion = true
    var startAddress: String?
    var completeAddress: String?
    var endTime: Date?
    var startTime: Date?
    var markerUserName : String?
    var infoCardImage: UIImage?
    var isCurrentUser = false
    var isCompletedOrCanceled = false
}
