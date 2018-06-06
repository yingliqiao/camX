//
//  SettingTableViewController.swift
//  camX
//
//  Created by Liqiao Ying on 2018-05-20.
//  Copyright © 2018 Liqiao Ying. All rights reserved.
//

import UIKit

class SettingTableViewController: UITableViewController {
    
    @IBOutlet weak var modelSettingValue: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.updateCells()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Table view data source
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.textColor = UIColor.white
    }
    
    func updateCells() {
        var indexPath = IndexPath(row: 0, section: 0)
        var cell = super.tableView(tableView, cellForRowAt: indexPath)
        cell.detailTextLabel?.text = SettingManager.sharedInstance.modelName
        
        indexPath = IndexPath(row: 0, section: 1)
        cell = super.tableView(tableView, cellForRowAt: indexPath)
        cell.detailTextLabel?.text = String(SettingManager.sharedInstance.alarmThreshold)
    }
}
