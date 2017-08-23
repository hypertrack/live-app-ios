//
//  AcceptInviteVC.swift
//  htlive-ios
//
//  Created by Piyush on 17/07/17.
//  Copyright © 2017 PZRT. All rights reserved.
//

import Foundation
import HyperTrack
class AcceptInviteVC : UIViewController {
    
    public var accountName:String?
    public var accountId:String?
    public var userId:String?

    @IBOutlet weak var accountNameLabel: UILabel!
    
    var inviteDelegate:HyperTrackInviteDelegate? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.accountNameLabel.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        guard self.accountName != nil, self.accountId != nil else {
            self.showAlert(title: "Error", message: "Something went wrong. Please try again.")
            return
        }
        
        self.accountNameLabel.text = self.accountName!
        self.accountNameLabel.isHidden = false
    }
    
    @IBAction func didTapAcceptInviteButton(_ sender: Any) {
        // Mark the invite accepted on HyperTrack API Server
        let requestService = RequestService.shared
        var oldUserId = HyperTrack.getUserId()
        HyperTrack.setUserId(userId!)
      
        if(oldUserId != userId){
            HyperTrack.stopTracking()
            HyperTrack.startTracking()
        }
        self.view.showActivityIndicator()
        requestService.acceptHyperTrackInvite(accountId: self.accountId!,oldUserId:oldUserId) { (error) in
            self.view.hideActivityIndicator()
            if (error != nil) {
                self.showAlert(title: "Error", message: error)
            } else {
                self.dismiss(animated:true , completion: { 
                    self.inviteDelegate?.didAcceptInvite(currentController: self)
                })
                
            }
        }
    }
    
    @IBAction func didTapSkipInviteButton(_ sender: Any) {
        
        self.dismiss(animated:true , completion: {
            self.inviteDelegate?.didSkipInvite(currentController: self)
        })
    }
    
    fileprivate func showAlert(title: String?, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let ok: UIAlertAction = UIAlertAction.init(title: "OK", style: .cancel, handler: nil)
        alert.addAction(ok)
        
        self.present(alert, animated: true, completion: nil)
    }
}
