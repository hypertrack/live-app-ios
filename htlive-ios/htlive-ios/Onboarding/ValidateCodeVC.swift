//
//  ValidateCodeVC.swift
//  htlive-ios
//
//  Created by Arjun Attam on 17/07/17.
//  Copyright © 2017 PZRT. All rights reserved.
//

import Foundation
import Alamofire
import HyperTrack

class ValidateCodeVC: UIViewController {
    
    let baseUrl = "https://api.hypertrack.com/api/v1/"
    
    @IBOutlet weak var verificationCode: UITextField!
    
    @IBAction func verifyCode(_ sender: Any) {
        validateHyperTrackCode()
    }
    
    @IBAction func resendCode(_ sender: Any) {
        // TODO: wait for some time before this can be enabled?
        resendHyperTrackCode()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        verificationCode.becomeFirstResponder()
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func makeRequest(urlSuffix:String, body:[String:Any], completionHandler: @escaping (_ error: HyperTrackError?) -> Void) {
        guard let userId = HyperTrack.getUserId() else {
            // TODO: handle no user id
            return
        }
        
        guard let token = HyperTrack.getPublishableKey() else {
            // TODO: handle no publishable key
            return
        }
        
        let url = "\(baseUrl)users/\(userId)/\(urlSuffix)/"
        let headers = ["Authorization": "token \(token)"]
        
        Alamofire.request(url, method: .post, parameters: body, encoding: JSONEncoding.default, headers: headers).validate().responseJSON { response in
            switch response.result {
            case .success:
                print("Validation Successful")
            case .failure(let error):
                print(error)
                print(String(data: response.data!, encoding: .utf8))
            }
        }
    }

    func validateHyperTrackCode() {
        // method to validate 4 digit code at HyperTrack

        if let code = verificationCode.text {
            let body = ["verification_code": code]
            
            makeRequest(urlSuffix: "validate_code", body: body, completionHandler: { (error) in
                if ((error) != nil) {
                    // Handle error
                }
            })
        }
    }
    
    func resendHyperTrackCode() {
        // method to call the resend verification API

        makeRequest(urlSuffix: "send_verification", body: [:], completionHandler: { (error) in
            if (error != nil) {
                // Handle error
            }
        })
    }
}
