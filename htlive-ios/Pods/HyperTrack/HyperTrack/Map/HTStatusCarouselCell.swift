//
//  HTStatusCarouselCell.swift
//  Pods
//
//  Created by Ravi Jain on 29/06/17.
//
//

import UIKit

protocol HTStausCardActionDelegate : class  {
    func startSharingLiveLocation(user : HTTrackedUser? ,indexPath: IndexPath?)
    func stopSharingLiveLocation(user: HTTrackedUser?,indexPath: IndexPath)
    func userClickedOnPhone(user : HTTrackedUser?,indexPath:IndexPath)
}

class HTStatusCarouselCell: HTScalingCarouselCell,HTStausCardDelegate {

    var statusCard : HTStatusCardView?
    var button : UIButton?
    var user : HTTrackedUser?
    var indexPath : IndexPath?
    weak var actionDelegate : HTStausCardActionDelegate?
    var statusCardInfo : HTStatusCardInfo?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let bundle = Settings.getBundle()!
        let statusCard: HTStatusCardView = bundle.loadNibNamed("StatusCardView", owner: self, options: nil)?.first as! HTStatusCardView
        self.statusCard = statusCard
        self.statusCard?.statusCardDelegate = self
        mainView = UIView(frame: contentView.bounds)
        statusCard.frame = CGRect(x:0,y:0,width:(statusCard.frame.width),height:contentView.frame.height)
        statusCard.center = contentView.center

        mainView.addSubview(statusCard)
        
        contentView.addSubview(mainView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        mainView.frame = contentView.bounds
        statusCard?.frame =  CGRect(x:0,y:0,width:(statusCard?.frame.width)!,height:contentView.frame.height)
       statusCard?.center = contentView.center
       print(statusCard?.center)
       button?.frame = CGRect(x:0,y:contentView.frame.height - 80,width:contentView.frame.width - 40, height:60)
        button?.center.x = contentView.center.x
    }
    
    func setIsExpanded(_ isExpanded : Bool){
        statusCard?.setIsExpanded(isExpanded)
    }
    
    public func reloadWithUpdatedInfo(_ statusInfo:HTStatusCardInfo){
        self.statusCardInfo = statusInfo
        statusCard?.reloadWithUpdatedInfo(statusInfo)
    }
    
    public func changeToShareLiveLocationButton(){
        mainView.removeFromSuperview()
        if(button == nil){
            button = UIButton.init(frame: CGRect(x:0,y:contentView.frame.height - 80,width:contentView.frame.width - 40, height:60))
            button?.setTitle("Share Live Location", for: [])
            button?.addTarget(self, action: #selector(self.shareLiveLocation), for:.touchUpInside)
            button?.backgroundColor = UIColor(red:CGFloat(211.0/255.0),green:CGFloat(68.0/255.0),blue:CGFloat(168.0/255.0),alpha: CGFloat(1.0))
            button?.center.x = contentView.center.x
           // button?.center = contentView.center
            contentView.addSubview(button!)
        }else{
            button?.frame = CGRect(x:0,y:contentView.frame.height - 80,width:contentView.frame.width - 40, height:60)
            button?.center.x = contentView.center.x
            button?.removeFromSuperview()
            contentView.addSubview(button!)
        }
    }
    
    func shareLiveLocation(){
        if self.actionDelegate != nil {
            self.actionDelegate?.startSharingLiveLocation(user: user, indexPath: indexPath)
        }
        
    }
    public func changeToNormalView(){
        if (button != nil) {
            button?.removeFromSuperview()
        }
        mainView.removeFromSuperview()
      
        mainView.frame = contentView.bounds
        contentView.addSubview(mainView)
    }
    
    func didClickedOnActionButton(){
        if let actionDelegate = self.actionDelegate {
            if (statusCardInfo?.isCurrentUser)! {
                
                if (statusCardInfo?.isCompletedOrCanceled)! {
                    actionDelegate.startSharingLiveLocation(user: user, indexPath: indexPath)
                    
                } else {
                   actionDelegate.stopSharingLiveLocation(user: user, indexPath: indexPath!)
                }
            } else {
                actionDelegate.userClickedOnPhone(user: user, indexPath: indexPath!)
            }
        }
    }
}
