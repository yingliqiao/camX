//
//  ObjectTableViewController.swift
//  camX
//
//  Created by Liqiao Ying on 2018-04-25.
//  Copyright © 2018 Liqiao Ying. All rights reserved.
//

import UIKit

class ObjectTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tableView.separatorStyle = SettingManager.sharedInstance.getYoloModel() == .None ? .none : .singleLine
        
        self.tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.textColor = UIColor.white
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return SettingManager.sharedInstance.getYoloModel() == .None ?
            "Object detection is disabled" : String(format: "%@ - detect and alarm filters", SettingManager.sharedInstance.getYoloModel().rawValue)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return SettingManager.sharedInstance.getYoloModel() == .None ? 0 : SettingManager.sharedInstance.labels.count + 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ObjectCell", for: indexPath) as! ObjectTableViewCell
        
        if(indexPath.row == 0) {
            cell.objectLabel.text = "SELECT ALL"
            cell.detectLabel.text = "Detect"
            cell.detectState.isOn = false
            cell.alarmLabel.text = "Alarm"
            cell.alarmState.isOn = false
            cell.separatorInset = UIEdgeInsets(top: 0.0, left: 10.0, bottom: 0.0, right: 10.0)
        } else {
            cell.objectLabel.text = SettingManager.sharedInstance.labels[indexPath.row - 1]
            cell.detectLabel.text = ""
            cell.detectState.isOn = SettingManager.sharedInstance.getDetect(indexPath.row - 1)
            cell.alarmLabel.text = ""
            cell.alarmState.isOn = SettingManager.sharedInstance.getAlarm(indexPath.row - 1)
            cell.separatorInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: .greatestFiniteMagnitude)
        }
        
        cell.detectState.tag = indexPath.row
        cell.detectState.addTarget(self, action: #selector(onDetectSwitchValueChanged), for: .valueChanged)
        cell.detectState.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        
        cell.alarmState.tag = indexPath.row
        cell.alarmState.addTarget(self, action: #selector(onAlarmSwitchValueChanged), for: .valueChanged)
        cell.alarmState.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        
        
        return cell
    }
    
    @objc func onDetectSwitchValueChanged(_ detectStateUISwitch: UISwitch) {
        if detectStateUISwitch.tag == 0 {
            var indexPaths = Array<IndexPath>()
            
            for i in 1...SettingManager.sharedInstance.labels.count {
                SettingManager.sharedInstance.setDetect(index: i-1, state: detectStateUISwitch.isOn)
                
                // Turn off detect also disables alarm
                if !detectStateUISwitch.isOn {
                    SettingManager.sharedInstance.setAlarm(index: i-1, state: false)
                }
                indexPaths.append(IndexPath(row: i, section: 0))
            }
            
            // Turn off select all alarms
            if !detectStateUISwitch.isOn {
                let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as! ObjectTableViewCell
                cell.alarmState.isOn = false
            }
            
            self.tableView.reloadRows(at: indexPaths, with: .none)
        } else {
            SettingManager.sharedInstance.setDetect(index: detectStateUISwitch.tag-1, state: detectStateUISwitch.isOn)
            
            // Turn off detect also disables alarm
            if !detectStateUISwitch.isOn {
                SettingManager.sharedInstance.setAlarm(index: detectStateUISwitch.tag-1, state: false)
                self.tableView.reloadRows(at: [IndexPath(row: detectStateUISwitch.tag, section: 0)], with: .none)
            }
        }
        SettingManager.sharedInstance.saveDetects()
    }
    
    @objc func onAlarmSwitchValueChanged(_ alarmStateUISwitch: UISwitch) {
        if alarmStateUISwitch.tag == 0 {
            var indexPaths = Array<IndexPath>()
            for i in 1...SettingManager.sharedInstance.labels.count {
                SettingManager.sharedInstance.setAlarm(index: i-1, state: alarmStateUISwitch.isOn)
                indexPaths.append(IndexPath(row: i, section: 0))
            }
            self.tableView.reloadRows(at: indexPaths, with: .none)
        } else {
            SettingManager.sharedInstance.setAlarm(index: alarmStateUISwitch.tag-1, state: alarmStateUISwitch.isOn)
        }
        SettingManager.sharedInstance.saveAlarms()
    }
}

