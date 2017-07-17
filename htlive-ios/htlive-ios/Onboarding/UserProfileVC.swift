//
//  UserProfileVC.swift
//  htlive-ios
//
//  Created by Piyush on 17/07/17.
//  Copyright © 2017 PZRT. All rights reserved.
//

import Foundation

class UserProfileVC: UIViewController {
    
    @IBOutlet weak var name: CustomTextField!
    
    @IBOutlet weak var phone: CustomTextField!
    
    @IBAction func proceed(_ sender: Any) {
        
        guard name.text != "" else { name.shake(); return }
        guard phone.text != "" else { phone.shake(); return }
        
        self.performSegue(withIdentifier: "showPlaceline", sender: self)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        name.becomeFirstResponder()
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
