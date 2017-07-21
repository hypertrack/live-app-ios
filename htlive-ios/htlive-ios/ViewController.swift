//
//  ViewController.swift
//  htlive-ios
//
//  Created by Vibes on 7/4/17.
//  Copyright © 2017 PZRT. All rights reserved.
//

import UIKit
import HyperTrack
import FSCalendar
import MessageUI

let pink = UIColor(red:1.00, green:0.51, blue:0.87, alpha:1.0)

class ViewController: UIViewController {

    @IBOutlet weak var calendarHeight: NSLayoutConstraint!
    @IBOutlet weak var calendar: FSCalendar!
    @IBOutlet weak var placeLineTable: UITableView!
    @IBOutlet weak var dateLabel: UILabel!
    
    
    @IBOutlet weak var placeLineTitle: UILabel!
    
    var segments: [HyperTrackActivity] = []
    var selectedIndexPath : IndexPath? = nil
    var noResults = false
    
    
    @IBOutlet weak var calendarArrow: UIImageView!
    @IBAction func calendarTap(_ sender: Any) {
        
        guard calendarTop.constant != 0 else {
       
            collapseCalendar()
            return
        }
        
        expandCalendar()
        
    }
    
    @IBOutlet weak var calendarTop: NSLayoutConstraint!
    
    @IBAction func onLiveLocationButtonClick(sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let liveLocationController = storyboard.instantiateViewController(withIdentifier: "ShareVC") as! ShareVC
        self.present(liveLocationController, animated:true, completion: nil)
    }
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        calendarTop.constant = -300
        calendar.layer.opacity = 0
        
        placeLineTable.register(UINib(nibName: "placeCell", bundle: nil), forCellReuseIdentifier: "placeCell")
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.userCreated), name: NSNotification.Name(rawValue:HTLiveConstants.userCreatedNotification), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.onForegroundNotification), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(onTap))
        tap.numberOfTapsRequired = 5
        placeLineTitle.isUserInteractionEnabled = true
        placeLineTitle.addGestureRecognizer(tap)


    }
    
    func onForegroundNotification(_ notification: Notification){
        getPlaceLineData()
    }
    
    func userCreated(_ notification: Notification) {
        getPlaceLineData()
    }

    
    override func viewWillAppear(_ animated: Bool) {
        getPlaceLineData()
    }
    
    
    
    func getPlaceLineData(){
        if(HyperTrack.getUserId() != nil) {
            HyperTrack.getPlaceline { (placeLine, error) in
            guard let fetchedPlaceLine = placeLine else { return }
            if let segments = fetchedPlaceLine.segments {
                self.segments = segments.reversed()
                if segments.count == 0 {
                    self.noResults = true
                } else {
                    self.noResults = false
                }
                    self.placeLineTable.reloadData()
                }
                
            }
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
}

extension ViewController : UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard segments.count != 0 else { return 1 }
        return segments.count
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
       return 72
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    func getTopVisibleRow() {
        
        let array = placeLineTable.indexPathsForVisibleRows
        print(array?[0].row)
        
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "placeCell", for: indexPath) as! placeCell
        cell.layer.backgroundColor = UIColor.clear.cgColor
        if segments.count != 0 {
            cell.setStats(activity: segments[indexPath.row])
        } else {
            
            if self.noResults {
                cell.noResults()
            } else {
                cell.loading()
            }
        }
        cell.selectionStyle = .none
        
        if(selectedIndexPath?.row != indexPath.row) || (cell.status.text == "Loading Placeline.."){
            cell.normalize()
        }
        return cell
        
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let cell = placeLineTable.cellForRow(at: indexPath) as? placeCell else { return }
        placeLineTable.scrollToRow(at: indexPath, at: .middle, animated: true)
        
        cell.select()
        selectedIndexPath = indexPath
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        
        let cell = tableView.cellForRow(at: indexPath) as? placeCell
        cell?.deselect()
    }
    
    
}


extension ViewController : FSCalendarDataSource, FSCalendarDelegate {
    
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        
//        let currentDate = Date()
//        guard date > currentDate else { return }
        self.dateLabel.text = date.toString(dateFormat: "dd MMMM")
        self.noResults = false
        self.segments = []
        self.placeLineTable.reloadData()
        getPlacelineForDate(date: date)
        collapseCalendar()
        
        if monthPosition == .previous || monthPosition == .next {
            calendar.setCurrentPage(date, animated: true)
        }
    }
    
    func collapseCalendar() {
        
        calendarTop.constant = -300
        UIView.animate(withDuration: 0.2, animations: {
            self.view.layoutIfNeeded()
            self.calendar.layer.opacity = 0
            self.calendarArrow.transform = self.calendarArrow.transform.rotated(by: CGFloat(Double.pi))
        })
        
    }
    
    func expandCalendar() {
        calendarTop.constant = 0
        UIView.animate(withDuration: 0.2, animations: {
            self.view.layoutIfNeeded()
            self.calendar.layer.opacity = 1
            self.calendarArrow.transform = self.calendarArrow.transform.rotated(by: CGFloat(-Double.pi))
        })
    }
    
    func getPlacelineForDate(date : Date) {
        
        self.segments = []
        self.placeLineTable.reloadData()
        
        HyperTrack.getPlaceline(date: date) { (placeLine, error) in
            guard let fetchedPlaceLine = placeLine else { return }
            if let segments = fetchedPlaceLine.segments {
                self.segments = segments.reversed()
                
                if segments.count == 0 {
                    self.noResults = true
                } else {
                    self.noResults = false
                }
                
                self.placeLineTable.reloadData()
            }
        }
        
    }

}

extension ViewController: MFMailComposeViewControllerDelegate{
   
    func onTap(sender:UITapGestureRecognizer) {
        
        let mailComposeViewController = configuredMailComposeViewController()
        if MFMailComposeViewController.canSendMail() {
            self.present(mailComposeViewController, animated: true, completion: nil)
        } else {
            self.showSendMailErrorAlert()
        }
    }
    
    func configuredMailComposeViewController() -> MFMailComposeViewController {
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self
        mailComposerVC.setToRecipients(["ravi@hypertrack.io"])
        let subject = "Hypertrack logs" + HyperTrack.getUserId()!
        mailComposerVC.setSubject(subject)
        mailComposerVC.setMessageBody("", isHTML: false)
        
        if let baseURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {

            let enumerator = FileManager.default.enumerator(at: baseURL,
                                                            includingPropertiesForKeys: [],
                                                            options: [.skipsHiddenFiles], errorHandler: { (url, error) -> Bool in
                                                                print("directoryEnumerator error at \(url): ", error)
                                                                return true
            })!
            
            
            for case let fileURL as URL in enumerator {
                if(fileURL.absoluteString.hasSuffix("log")){
                    if let fileData = NSData(contentsOfFile: fileURL.path) {
                        mailComposerVC.addAttachmentData(fileData as Data, mimeType: "text/rtf", fileName: "HyperTrack.log")
                    }
                }
            
            }
        }
        
        
        return mailComposerVC
    }
    
    func showSendMailErrorAlert() {
        let sendMailErrorAlert = UIAlertView(title: "Could Not Send Email", message: "Your device could not send e-mail.  Please check e-mail configuration and try again.", delegate: self, cancelButtonTitle: "OK")
        sendMailErrorAlert.show()
    }
    

    
    
    func mailComposeController(controller: MFMailComposeViewController!, didFinishWithResult result: MFMailComposeResult, error: NSError!) {
        controller.dismiss(animated: true, completion: nil)
        
    }
    
    
}
