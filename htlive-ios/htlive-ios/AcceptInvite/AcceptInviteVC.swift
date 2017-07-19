//
//  AcceptInviteVC.swift
//  htlive-ios
//
//  Created by Piyush on 17/07/17.
//  Copyright © 2017 PZRT. All rights reserved.
//

import Foundation

class AcceptInviteVC : UIViewController {
    
    public var accountName:String?
    public var accountId:String?
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
        requestService.acceptHyperTrackInvite(accountId: self.accountId!) { (error) in
            if (error != nil) {
                self.showAlert(title: "Error", message: error)
            } else {
                self.inviteDelegate?.didAcceptInvite(currentController: self)
            }
        }
    }
    
    @IBAction func didTapSkipInviteButton(_ sender: Any) {
        self.inviteDelegate?.didSkipInvite(currentController: self)
    }
    
    fileprivate func showAlert(title: String?, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let ok: UIAlertAction = UIAlertAction.init(title: "OK", style: .cancel, handler: nil)
        alert.addAction(ok)
        
        self.present(alert, animated: true, completion: nil)
    }
}
