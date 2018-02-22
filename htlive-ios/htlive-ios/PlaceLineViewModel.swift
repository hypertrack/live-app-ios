//
//  PlaceLineViewModel.swift
//  htlive-ios
//
//  Created by Atul Manwar on 22/02/18.
//  Copyright © 2018 PZRT. All rights reserved.
//

import UIKit
import HyperTrack

final class PlaceLineViewModel {
    init() {
    }
    func getPlaceLineData(_ completionHandler: @escaping ((APIResponse<HyperTrackPlaceline>) -> Void)) {
        guard HyperTrack.getUserId() != nil else { return }
        HyperTrack.getPlaceline { (placeline, error) in
            guard let fetchedPlaceline = placeline else {
                completionHandler(.failure(error))
                return
            }
            completionHandler(.success(fetchedPlaceline))
        }
    }
}

enum APIResponse<T> {
    case success(T)
    case failure(HyperTrackError?)
}
