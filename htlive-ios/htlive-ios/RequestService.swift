//
//  RequestService.swift
//  htlive-ios
//
//  Created by Arjun Attam on 17/07/17.
//  Copyright © 2017 PZRT. All rights reserved.
//

import Foundation
import HyperTrack
import Alamofire

class RequestService {
    static let shared = RequestService()
    
    let baseUrl = "https://api.hypertrack.com/api/v1/"
    
    func makeHyperTrackRequest(urlSuffix:String, body:[String:Any], completionHandler: @escaping (_ error: String?) -> Void) {
        guard let userId = HyperTrack.getUserId() else {
            // TODO: handle no user id
            completionHandler("Set a user id")
            return
        }
        
        guard let token = HyperTrack.getPublishableKey() else {
            // TODO: handle no publishable key
            completionHandler("Set a publishable key")
            return
        }
        
        let url = "\(baseUrl)users/\(userId)/\(urlSuffix)/"
        let headers = ["Authorization": "token \(token)"]
        
        Alamofire.request(url, method: .post, parameters: body, encoding: JSONEncoding.default, headers: headers).validate().responseJSON { response in
            switch response.result {
            case .success:
                completionHandler(nil)
            case .failure(let error):
                let errorMsg = String(data: response.data!, encoding: .utf8)!
                completionHandler(errorMsg)
            }
        }
    }
    
    func sendHyperTrackCode(completionHandler: @escaping (_ error: String?) -> Void) {
        makeHyperTrackRequest(urlSuffix: "send_verification", body: [:], completionHandler: completionHandler)
    }
    
    func validateHyperTrackCode(code: String, completionHandler: @escaping (_ error: String?) -> Void) {
        let body = ["verification_code": code]
        makeHyperTrackRequest(urlSuffix: "validate_code", body: body, completionHandler: completionHandler)
    }
    
    func acceptHyperTrackInvite(accountId:String,oldUserId:String?,completionHandler: @escaping (_ error: String?) -> Void) {
        let body = ["account_id": accountId,"existing_user_id":oldUserId]
        makeHyperTrackRequest(urlSuffix: "accept_invite", body: body, completionHandler: completionHandler)
    }
}
