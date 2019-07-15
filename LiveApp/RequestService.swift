//
//  RequestService.swift
//  LiveApp
//
//  Created by Dmytro Shapovalov on 6/28/19.
//  Copyright © 2019 Dmytro Shapovalov. All rights reserved.
//

import UIKit
import HyperTrack

typealias JSON = [String: Any]

enum HTEndpoints {
    case getShareLocationLink
}

class RequestService {

    private let appState: AppState
    private let baseUrl = "https://7kcobbjpavdyhcxfvxrnktobjm.appsync-api.us-west-2.amazonaws.com/graphql"
    private let session: URLSession?
    
    init(_ appState: AppState) {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 10
        self.session = URLSession(configuration: configuration)
        self.appState = appState
    }
    
    private func makeHyperTrackRequest(request: URLRequest,
                                       completionHandler: @escaping (_ response: JSON) -> Void) {
        guard let session = self.session else { return }
        let task = session.dataTask(with: request, completionHandler: { (data, response, error) in
            if let data = data, let JSON = try? JSONSerialization.jsonObject(with: data, options: []) as? JSON {
                completionHandler(JSON)
            } else {
                completionHandler([:])
            }
        })
        task.resume()
    }
    
    func getSharedLink(completionHandler: @escaping (_ link: URL?) -> Void) {
        guard let url = URL(string: baseUrl), let pk = appState.pk_key else {
            preconditionFailure("Could not generate URL. ")
        }
        
        let headers = ["X-Api-Key": "da2-nt5vwlflmngjfbe6cbsone4emm"]
        let postParam = ["operationName": "getPublicTrackingIdQuery",
                        "variables": ["deviceId": HyperTrack.deviceID,
                                      "publishableKey": pk],
                        "query": "query getPublicTrackingIdQuery($publishableKey: String!, $deviceId: String!){\n  getPublicTrackingId(publishable_key: $publishableKey, device_id: $deviceId){\n    tracking_id\n  }\n}"] as [String : Any]
        
        if let jsonDict = convertToJSON(param: postParam) {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.allHTTPHeaderFields = headers
            request.httpBody = jsonDict
            
            makeHyperTrackRequest(request: request) { response in
                if let data = response["data"] as? [String: Any],
                    let publicTrackingId = data["getPublicTrackingId"] as? [String: Any],
                    let trackingID = publicTrackingId["tracking_id"] as? String {
                    completionHandler(URL(string: "https://trck.at/\(trackingID)"))
                } else {
                    completionHandler(nil)
                }
            }
        }
    }
}

extension RequestService {
    func convertToJSON(param: [String: Any]) -> Data? {
        do {
            return try JSONSerialization.data(withJSONObject: param,
                                              options: JSONSerialization.WritingOptions(rawValue: 0))
        } catch {
            return nil
        }
    }
}

