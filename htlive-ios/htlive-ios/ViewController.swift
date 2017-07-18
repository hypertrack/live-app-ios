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

let pink = UIColor(red:0.83, green:0.27, blue:0.70, alpha:1.0)

class ViewController: UIViewController {

    @IBOutlet weak var calendarHeight: NSLayoutConstraint!
    @IBOutlet weak var calendar: FSCalendar!
    @IBOutlet weak var placeLineTable: UITableView!
    @IBOutlet weak var dateLabel: UILabel!
    var segments: [HyperTrackActivity] = []
    
    @IBOutlet weak var calendarArrow: UIImageView!
    @IBAction func calendarTap(_ sender: Any) {
        
        guard calendarTop.constant != 0 else {
       
            collapseCalendar()
            return
        }
        
        expandCalendar()
        
    }
    
    @IBOutlet weak var calendarTop: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        calendarTop.constant = -300
        calendar.layer.opacity = 0
        
        placeLineTable.register(UINib(nibName: "placeCell", bundle: nil), forCellReuseIdentifier: "placeCell")
        
        HyperTrack.setUserId("2966354f-9ecc-44f8-a28b-3a804d5eb93c")
        HyperTrack.getPlaceline { (placeLine, error) in
            guard let fetchedPlaceLine = placeLine else { return }
            if let segments = fetchedPlaceLine.segments {
                    self.segments = segments
                    self.placeLineTable.reloadData()
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
            cell.loading()
        }
        cell.selectionStyle = .none
        return cell
        
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        print(indexPath)
        guard let cell = placeLineTable.cellForRow(at: indexPath) as? placeCell else { return }
        placeLineTable.scrollToRow(at: indexPath, at: .middle, animated: true)

        cell.select()
        
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        
        print(indexPath)
        let cell = tableView.cellForRow(at: indexPath) as? placeCell
        cell?.deselect()
    }
    
    
}


extension ViewController : FSCalendarDataSource, FSCalendarDelegate {
    
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        print(date)
        self.dateLabel.text = date.toString(dateFormat: "dd MMMM")
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
                self.segments = segments
                self.placeLineTable.reloadData()
            }
        }
        
    }

}
