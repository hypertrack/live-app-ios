//
//  HTRequestManager.swift
//  HyperTrack
//
//  Created by Tapan Pandita on 24/02/17.
//  Copyright © 2017 HyperTrack, Inc. All rights reserved.
//

import Foundation
import Alamofire
import Gzip


struct JSONArrayEncoding: ParameterEncoding {
    /// Returns a `JSONArrayEncoding` instance with default writing options.
    public static var `default`: JSONArrayEncoding { return JSONArrayEncoding() }
    
    func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
        var urlRequest = urlRequest.urlRequest
        let array = parameters?["array"]
        
        let data = try JSONSerialization.data(withJSONObject: array as! [Any], options: [])
        
        if urlRequest?.value(forHTTPHeaderField: "Content-Type") == nil {
            urlRequest?.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        urlRequest?.httpBody = data
        
        return urlRequest!
    }
}

struct GZippedJSONEncoding: ParameterEncoding {
    public static var `default`: GZippedJSONEncoding { return GZippedJSONEncoding() }
    
    func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
        var encodedRequest = try JSONEncoding.default.encode(urlRequest, with: parameters)
        encodedRequest.setValue("gzip", forHTTPHeaderField: "Content-Encoding")
        encodedRequest.httpBody = try encodedRequest.httpBody?.gzipped()
        return encodedRequest
    }
}


struct GZippedJSONArrayEncoding: ParameterEncoding {
    public static var `default`: GZippedJSONArrayEncoding { return GZippedJSONArrayEncoding() }
    
    func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
        var encodedRequest = try JSONArrayEncoding.default.encode(urlRequest, with: parameters)
        encodedRequest.setValue("gzip", forHTTPHeaderField: "Content-Encoding")
        encodedRequest.httpBody = try encodedRequest.httpBody?.gzipped()
        return encodedRequest
    }
}


class HTTPRequest {
    var arrayParams:[Any]?
    var jsonParams:[String:Any]?
    var urlParams:[String:String]?
    let method:HTTPMethod
    var headers:[String:String]
    let urlPath:String
    let baseURL:String = "https://api.hypertrack.com/api/v1/"
    let sdkVersion:String? = Settings.sdkVersion
    let osVersion:String = UIDevice.current.systemVersion
    
    init(method:HTTPMethod, urlPath:String, jsonParams:[String:Any]) {
        self.jsonParams = jsonParams
        self.method = method
        self.urlPath = urlPath
        
        let publishableKey = Settings.getPublishableKey()! as String
        self.headers = [
            "Authorization": "token \(publishableKey)",
            "Content-Type": "application/json",
            "User-Agent": "HyperTrack iOS SDK/\(sdkVersion) (\(osVersion))",
            "App-ID": "\(Bundle.main.bundleIdentifier)",
            "Device-ID": "\(Settings.uniqueInstallationID)"
        ]
    }
    
    init(method:HTTPMethod, urlPath:String, arrayParams:[Any]) {
        self.arrayParams = arrayParams
        self.method = method
        self.urlPath = urlPath
        
        let publishableKey = Settings.getPublishableKey()! as String
        self.headers = [
            "Authorization": "token \(publishableKey)",
            "Content-Type": "application/json",
            "User-Agent": "HyperTrack iOS SDK/\(sdkVersion) (\(osVersion))",
            "App-ID": "\(Bundle.main.bundleIdentifier)",
            "Device-ID": "\(Settings.uniqueInstallationID)"
        ]
    }
    
    init(method:HTTPMethod, urlPath:String, urlParams:[String:String]) {
        self.urlParams = urlParams
        self.method = method
        self.urlPath = urlPath
        
        let publishableKey = Settings.getPublishableKey()! as String
        self.headers = [
            "Authorization": "token \(publishableKey)",
            "Content-Type": "application/json",
            "User-Agent": "HyperTrack iOS SDK/\(sdkVersion) (\(osVersion))",
            "App-ID": "\(Bundle.main.bundleIdentifier)",
            "Device-ID": "\(Settings.uniqueInstallationID)"
        ]
    }
    
    func buildURL() -> String {
        return self.baseURL + self.urlPath
    }
    
    func makeRequest(completionHandler: @escaping (DataResponse<Any>) -> Void) {
        if let array = self.arrayParams {
            Alamofire.request(
                self.buildURL(),
                method: self.method,
                parameters:["array":array],
                encoding:GZippedJSONArrayEncoding.default,
                headers:self.headers
                ).validate().responseJSON(completionHandler:completionHandler)
        } else if let json = self.jsonParams {
            Alamofire.request(
                self.buildURL(),
                method:self.method,
                parameters:json,
                encoding:GZippedJSONEncoding
                    .default,
                headers:self.headers
                ).validate().responseJSON(completionHandler:completionHandler)
        }
    }
}


class RequestManager {
    let eventsDatabaseManager:EventsDatabaseManager
    var timer: Timer
    let serialQueue: DispatchQueue
    
    init() {
        self.eventsDatabaseManager = EventsDatabaseManager()
        self.timer = Timer()
        self.serialQueue = DispatchQueue(label: "requestsQueue")
    }
    
    func startTimer() {
        self.timer = Timer.scheduledTimer(timeInterval: 90.0, target: self, selector: #selector(self.postEvents) , userInfo: Date(), repeats: true)
    }
    
    func resetTimer(batchDuration: Double) {
        self.timer = Timer.scheduledTimer(timeInterval: batchDuration, target: self, selector: #selector(self.postEvents) , userInfo: Date(), repeats: true)
    }
    
    func stopTimer() {
        // TODO: Need to stop when all data is posted to backend
        self.timer.invalidate()
    }
    
    func fire() {
        self.timer.fire()
    }
    
    @objc func postEvents(flush:Bool = true) {
        self.serialQueue.async {
            guard let userId = Settings.getUserId() else { return }
            guard let events = self.eventsDatabaseManager.getEvents(userId: userId) else { return }
            
            var eventsDict:[[String:Any]] = []
            var eventIds:[Int64] = []
            
            for (id, event) in events {
                eventsDict.append(event.toDict())
                eventIds.append(id)
            }
            
            if eventsDict.isEmpty {
                return
            }
            
            HTTPRequest(method:.post, urlPath:"sdk_events/bulk/", arrayParams:eventsDict).makeRequest { response in
                switch response.result {
                case .success:
                    self.eventsDatabaseManager.bulkDelete(ids: eventIds)
                    debugPrint("Events pushed successfully: ", eventIds.count)
                    // Flush data
                    if flush {
                        self.postEvents(flush:true)
                    }
                case .failure(let error):
                    debugPrint(error, response)
                }
            }
        }
    }
    
    func getAction(_ actionId: String, completionHandler: @escaping (_ action: HyperTrackAction?, _ error: HyperTrackError?) -> Void) {
        let urlPath = "actions/\(actionId)/detailed/"
        HTTPRequest(method:.get, urlPath:urlPath, jsonParams:[:]).makeRequest { response in
            switch response.result {
            case .success:
                let action = HyperTrackAction.fromJson(data: response.data)
                completionHandler(action, nil)
            case .failure:
                // TODO: Generate better error here depending on response code
                let htError = HyperTrackError(HyperTrackErrorType.serverError)
                completionHandler(nil, htError)
            }
        }
    }
    
    func fetchDetailsForActions(_ actionIDs: [String], completionHandler: @escaping (_ actions: [HyperTrackAction]?, _ error: HyperTrackError?) -> Void) {
        
        let actionsToTrack = actionIDs.joined(separator: ",")
        let urlPath = "actions/track/?id=\(actionsToTrack)"
        HTTPRequest(method:.get, urlPath:urlPath, jsonParams:[:]).makeRequest { response in
            switch response.result {
            case .success:
                let actions = HyperTrackAction.multiActionsFromJSONData(data: response.data)
                completionHandler(actions, nil)
            case .failure:
                // TODO: Generate better error here depending on response code
                let htError = HyperTrackError(HyperTrackErrorType.serverError)
                completionHandler(nil, htError)
            }
        }
    }
    
    func fetchDetailsForActionsByShortCodes(_ shortCodes: [String], completionHandler: @escaping (_ actions: [HyperTrackAction]?, _ error: HyperTrackError?) -> Void) {
        
        let actionsToTrack = shortCodes.joined(separator: ",")
        let urlPath = "actions/track/?short_code=\(actionsToTrack)"
        HTTPRequest(method:.get, urlPath:urlPath, jsonParams:[:]).makeRequest { response in
            switch response.result {
            case .success:
                let actions = HyperTrackAction.multiActionsFromJSONData(data: response.data)
                completionHandler(actions, nil)
            case .failure:
                // TODO: Generate better error here depending on response code
                let htError = HyperTrackError(HyperTrackErrorType.serverError)
                completionHandler(nil, htError)
            }
        }
    }
    
    func assignAction(_ action:[String:Any], completionHandler: @escaping (_ action: HyperTrackAction?, _ error: HyperTrackError?) -> Void) {
        HTTPRequest(method:.post, urlPath:"actions/", jsonParams:action).makeRequest { response in
            switch response.result {
            case .success:
                do {
                    let json = try JSONSerialization.jsonObject(with: response.data!, options:[])
                    guard let jsonDict = json as? [String : Any] else {
                        let htError = HyperTrackError(HyperTrackErrorType.jsonError)
                        completionHandler(nil, htError)
                        return
                    }
                    
                    let action = HyperTrackAction.fromDict(dict: jsonDict)
                    completionHandler(action, nil)
                } catch {
                    debugPrint("Error serializing user: ", error.localizedDescription)
                }
            case .failure:
                // TODO: Generate better error here depending on response code
                let htError = HyperTrackError(HyperTrackErrorType.serverError)
                completionHandler(nil, htError)
            }
        }
    }
    
    func createUser(_ user:[String:Any], completionHandler: ((_ user: HyperTrackUser?, _ error: HyperTrackError?) -> Void)?) {
        HTTPRequest(method:.post, urlPath:"users/", jsonParams:user).makeRequest { response in
            switch response.result {
            case .success:
                do {
                    let json = try JSONSerialization.jsonObject(with: response.data!, options:[])
                    guard let jsonDict = json as? [String : Any] else {
                        let htError = HyperTrackError(HyperTrackErrorType.jsonError)
                        guard let completionHandler = completionHandler else { return }
                        completionHandler(nil, htError)
                        return
                    }
                    
                    let name: String
                    let phone: String
                    let photo: String
                    
                    if (jsonDict["name"] != nil) {
                        name = jsonDict["name"] as! String
                    } else {
                        name = ""
                    }
                    
                    if (jsonDict["phone"] as? String) == nil {
                        phone = ""
                    } else {
                        phone = jsonDict["phone"] as! String
                    }
                    
                    if (jsonDict["photo"] as? String) == nil {
                        photo = ""
                    } else {
                        photo = jsonDict["photo"] as! String
                    }
                    
                    let user = HyperTrackUser(id: jsonDict["id"] as! String, name: name, phone: phone, photo: photo)
                    
                    guard let completionHandler = completionHandler else { return }
                    completionHandler(user, nil)
                } catch {
                    debugPrint("Error serializing user: ", error.localizedDescription)
                }
            case .failure:
                // TODO: Generate better error here depending on response code
                let htError = HyperTrackError(HyperTrackErrorType.serverError)
                guard let completionHandler = completionHandler else { return }
                completionHandler(nil, htError)
            }
        }
    }
}
