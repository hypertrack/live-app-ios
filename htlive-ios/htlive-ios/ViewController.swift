//
//  ViewController.swift
//  htlive-ios
//
//  Created by Vibes on 7/4/17.
//  Copyright © 2017 PZRT. All rights reserved.
//

import UIKit
import HyperTrack

class ViewController: UIViewController {

    @IBOutlet weak var placeLineTable: UITableView!
    var segments: [HyperTrackActivity] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        placeLineTable.register(UINib(nibName: "placeCell", bundle: nil), forCellReuseIdentifier: "placeCell")
        
        HyperTrack.initialize("pk_10c06a1abad0cbb0067ab18cf75805f4a270ffce")
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
        return segments.count
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
       return 72
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "placeCell", for: indexPath) as! placeCell
        cell.layer.backgroundColor = UIColor.clear.cgColor
        if segments.count != 0 {
                cell.setStats(activity: segments[indexPath.row])
            }
        return cell
        
    }
}
