//
//  SettingModelTableViewController.swift
//  camX
//
//  Created by Liqiao Ying on 2018-05-20.
//  Copyright © 2018 Liqiao Ying. All rights reserved.
//

import UIKit

class SettingModelTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)

        self.updateCellCheckmark(cell: cell, row: indexPath.row)
        
        return cell;
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
            case 0:
                SettingManager.sharedInstance.updateYoloModel(model: .None)
            case 2:
                SettingManager.sharedInstance.updateYoloModel(model: .TinyYolo)
            default:
                SettingManager.sharedInstance.updateYoloModel(model: .Yolo2)
        }
        
        for i in 0...2 {
            let indexPath = IndexPath.init(row: i, section: 0)
            let cell = super.tableView(tableView, cellForRowAt: indexPath)
            self.updateCellCheckmark(cell: cell, row: i)
        }
        
        navigationController?.popViewController(animated: true)
    }
    
    func updateCellCheckmark(cell: UITableViewCell, row: Int) {
        if row == 0 {
            cell.accessoryType = SettingManager.sharedInstance.getYoloModel() == .None ? .checkmark : .none
        } else if row == 1 {
            cell.accessoryType = SettingManager.sharedInstance.getYoloModel() == .Yolo2 ? .checkmark : .none
        } else {
            cell.accessoryType = SettingManager.sharedInstance.getYoloModel() == .TinyYolo ? .checkmark : .none
        }

    }
}
