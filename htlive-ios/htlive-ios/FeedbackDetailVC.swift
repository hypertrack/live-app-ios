//
//  FeedbackDetailVC.swift
//  htlive-ios
//
//  Created by ravi on 9/5/17.
//  Copyright © 2017 PZRT. All rights reserved.
//

import UIKit
import XLForm
import HyperTrack
class FeedbackDetailVC: XLFormViewController {
    
    var activity : HTActivity? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = activity?.activityType


        var feedback = UserDefaults.standard.string(forKey: (activity?.activityUUID)!)
        if let feedback = feedback{

        }else{
            self.navigationItem.rightBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .save, target: self, action:#selector(saveFeedback))
        }
        let form : XLFormDescriptor
        var section : XLFormSectionDescriptor
        var row : XLFormRowDescriptor
        
        form = XLFormDescriptor(title: activity?.activityType)
        
        section = XLFormSectionDescriptor.formSection()
        
        // Selector Picker View
        row = XLFormRowDescriptor(tag: "type", rowType:XLFormRowDescriptorTypeSelectorPickerView, title:"Activity")
        row.selectorOptions = ["walking", "running", "cycling", "driving", "stationary"]
        row.value = activity?.activityType
        section.addFormRow(row)
        form.addFormSection(section)

        section = XLFormSectionDescriptor.formSection()
        // Starts
        row = XLFormRowDescriptor(tag: "starts", rowType: XLFormRowDescriptorTypeDateTimeInline, title: "Starts")
        row.value = activity?.startTime
        section.addFormRow(row)
        
        // Ends
        row = XLFormRowDescriptor(tag: "ends", rowType: XLFormRowDescriptorTypeDateTimeInline, title: "Ends")
        row.value = activity?.endTime
        section.addFormRow(row)
        
        form.addFormSection(section)

        section = XLFormSectionDescriptor.formSection()

        row = XLFormRowDescriptor(tag: "numOfSteps", rowType: XLFormRowDescriptorTypeText, title:"Steps")
        row.cellConfigAtConfigure["textField.textAlignment"] =  NSTextAlignment.right.rawValue
        row.isRequired = true
        row.value = activity?.numOfSteps
        section.addFormRow(row)
        
        
        
        row = XLFormRowDescriptor(tag: "distance", rowType: XLFormRowDescriptorTypeText, title:"Step Distance")
        row.cellConfigAtConfigure["textField.textAlignment"] =  NSTextAlignment.right.rawValue
        row.isRequired = true
        row.value = activity?.distance
        section.addFormRow(row)

        form.addFormSection(section)

        
        section = XLFormSectionDescriptor.formSection()
        form.addFormSection(section)
        
        // Notes
        row = XLFormRowDescriptor(tag: "comments", rowType:XLFormRowDescriptorTypeTextView)
        row.cellConfigAtConfigure["textView.placeholder"] = "Any Other Comments"
        section.addFormRow(row)
        
        self.form = form

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

  
    func saveFeedback(){
        let feedback = ActivityFeedback.init(uuid: (self.activity?.activityUUID)!)
        
        var type = self.form.formRow(withTag: "type")?.value  as? String
        if type != activity?.activityType{
            feedback.editedType = type
            feedback.feedbackType = "edited"
            feedback.isTypeAccurate = false
        }
        
        var startTime = self.form.formRow(withTag: "starts")?.value as? Date
        if startTime?.timeIntervalSince1970 != activity?.startTime?.timeIntervalSince1970 {
            feedback.editedStartTime = startTime
            feedback.feedbackType = "edited"
            feedback.isStartTimeAccurate = false
        }
        
        var endTime = self.form.formRow(withTag: "ends")?.value as? Date
        if endTime != nil && activity?.endTime == nil{
            feedback.editedEndTime = endTime
            feedback.feedbackType = "edited"
            feedback.isEndTimeAccurate = false
        }else if endTime?.timeIntervalSince1970 != activity?.endTime?.timeIntervalSince1970{
            feedback.editedEndTime = endTime
            feedback.feedbackType = "edited"
            feedback.isEndTimeAccurate = false
        }
        
        var numOfSteps = self.form.formRow(withTag: "numOfSteps") as? Int
        if numOfSteps != activity?.numOfSteps {
            feedback.editedNumOfSteps = numOfSteps
            feedback.feedbackType = "edited"
            feedback.isNumOfStepsAccurate = false
        }
        
        var distance = self.form.formRow(withTag: "distance") as? Int
        if numOfSteps != activity?.numOfSteps {
            feedback.editedDistance = numOfSteps
            feedback.feedbackType = "edited"
            feedback.isDistanceAccurate = false
        }
       
        var userComments = self.form.formRow(withTag: "comments") as? String
        if userComments != nil &&   userComments != ""{
            feedback.userComments = userComments
            feedback.feedbackType = "edited"
        }
        
        if feedback.feedbackType == "edited"{
            RequestService.shared.sendActivityFeedback(feedback: feedback)
        }
        
        let alert = UIAlertController(title: "Feedback Noted", message: "Your feedback is saved.", preferredStyle: .alert)
        
        let ok: UIAlertAction = UIAlertAction.init(title: "OK", style: .cancel) { (action) in
            self.navigationController?.popViewController(animated: true)
        }
        alert.addAction(ok)
        
        self.present(alert, animated: true, completion: nil)
        
    }

   
}
