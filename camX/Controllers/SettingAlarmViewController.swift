//
//  SettingAlarmViewController.swift
//  camX
//
//  Created by Liqiao Ying on 2018-05-24.
//  Copyright © 2018 Liqiao Ying. All rights reserved.
//

import UIKit

class SettingAlarmViewController: UIViewController {

    @IBOutlet weak var alarmThresholdSlider: UISlider!
    @IBOutlet weak var alarmThresholdValue: UILabel!
    
    @IBAction func alarmThresholdChanged(_ sender: UISlider) {
        
        alarmThresholdValue.text = String(Int(alarmThresholdSlider.value))
        SettingManager.sharedInstance.alarmThreshold = Int(alarmThresholdSlider.value)
        SettingManager.sharedInstance.saveAlarmStorageThreshold()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        alarmThresholdSlider.value = Float(SettingManager.sharedInstance.alarmThreshold)
        alarmThresholdValue.text = String(Int(alarmThresholdSlider.value))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
