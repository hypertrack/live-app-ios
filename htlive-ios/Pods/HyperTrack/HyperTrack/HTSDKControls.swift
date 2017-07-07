//
//  HTSDKControls.swift
//  HyperTrack
//
//  Created by Tapan Pandita on 09/03/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import Foundation


class HyperTrackSDKControls {
  var batchDuration:Int {
    get {
      return 30 * 60
    }
    set(batchDuration) {
    }
  }

  var minimumDisplacement:Int {
    get {
      return 50
    }
    set(minimumDisplacement) {
    }
  }

  var minimumDuration:Int {
    get {
      return 50
    }
    set(minimumDuration) {
    }
  }

  var ttl:Date {
    get {
      return Date()
    }
    set(ttl) {
    }
  }
}
