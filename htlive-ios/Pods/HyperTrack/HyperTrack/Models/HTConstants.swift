//
//  HTConstants.swift
//  Pods
//
//  Created by Ravi Jain on 04/06/17.
//
//

import UIKit

struct HTConstants {
    enum UseCases : Int {
        case TYPE_SINGLE_USER_SINGLE_ACTION = 0
        case TYPE_SINGLE_USER_MULTIPLE_ACTION = 1
        case TYPE_MULTIPLE_USER_MULTIPLE_ACTION = 2
        case TYPE_MULTIPLE_USER_MULTIPLE_ACTION_SAME_PLACE = 3
    }
    
    enum AnnotationType : Int {
        case ACTION  = 0
        case USER = 1
    }
    
    enum MarkerType: Int {
        case DESTINATION_MARKER = 0
        case HERO_MARKER = 1
        case HERO_MARKER_WITH_ETA = 2
    }
}
