//
//  CustomShareView.swift
//  htlive-ios
//
//  Created by Ravi Jain on 7/25/17.
//  Copyright © 2017 PZRT. All rights reserved.
//

import UIKit

protocol CustomShareViewDelegate : class {
    func didClickOnShare(view : CustomShareView)
    func didClickOnMessenger(view : CustomShareView)
    func didClickOnWhatsapp(view : CustomShareView)
    func didClickOnMessages(view : CustomShareView)
    func didClickCloseButton(view : CustomShareView)

}


class CustomShareView: UIView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    var linkText : String?
    weak var shareDelegate : CustomShareViewDelegate? = nil
    
    
    @IBOutlet weak var linkView: UIView!
    
    @IBOutlet weak var linkLabel: UILabel!
    
    @IBOutlet weak var etaLabel: UILabel!
    
    @IBOutlet weak var copyLinkButton: UIButton!
    

    @IBAction func copyLink(_ sender: Any) {
        UIPasteboard.general.string = self.linkText
        self.copyLinkButton.setTitle("Copied!", for: UIControlState.normal)
        self.copyLinkButton.backgroundColor = UIColor.white
        self.copyLinkButton.setTitleColor(UIColor.black, for: UIControlState.normal)
    }
    
    
    @IBAction func closeShare(_ sender: Any) {
   
        if let delegate = shareDelegate{
            delegate.didClickCloseButton(view: self)
        }
    
        UIView.animate(withDuration: 0.5) {
            
            self.removeFromSuperview()
        }
    
    }
    @IBAction func onShareClicked(_ sender: Any) {
       if let delegate = shareDelegate{
            delegate.didClickOnShare(view: self)
        }
        
    }
    
    @IBAction func onWhatsAppClick(_ sender: Any) {
   
        if let delegate = shareDelegate{
            delegate.didClickOnWhatsapp(view: self)
        }

    }
    
    
    @IBAction func onMessengerClicked(_ sender: Any) {
   
        if let delegate = shareDelegate{
            delegate.didClickOnMessenger(view: self)
        }

    }
    
    @IBAction func onMessagesClick(_ sender: Any) {
        if let delegate = shareDelegate{
            delegate.didClickOnMessages(view: self)
        }

    }
    
    
    override func awakeFromNib() {

        linkView?.layer.cornerRadius =  (self.linkView?.frame.height)! / (4.0)
        linkView?.layer.masksToBounds = true
        
        copyLinkButton?.layer.cornerRadius =  (self.copyLinkButton?.frame.height)! / (4.0)
        copyLinkButton?.layer.masksToBounds = true
        copyLinkButton?.setTitle("Copy", for:UIControlState.normal)
    }
   
}
