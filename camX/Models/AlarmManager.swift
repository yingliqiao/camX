//
//  AlarmManager.swift
//  camX
//
//  Created by Liqiao Ying on 2018-05-27.
//  Copyright © 2018 Liqiao Ying. All rights reserved.
//

import Foundation

// Alarm Manager class
class AlarmManager {
    
    static let sharedInstance = AlarmManager()
    
    let timestampFormatter = DateFormatter()
    let timestampFormat = "yyyy-MM-dd HH:mm:ss"
    
    var currentAlarm : Alarm?
    
    var alarms = [Alarm]()
    
    var alarmsHash = ""
    
    var archieveLoaded = false
    
    init() {
        timestampFormatter.dateFormat = timestampFormat
    }
    
    func getSavedAlarms() -> [Alarm] {
        var savedAlarms = [Alarm]()
        for alarm in alarms {
            if alarm.saved {
                savedAlarms.append(alarm)
            }
        }
        return savedAlarms
    }
    
    func alarmsHashURL() -> String {
        return String(format:"%@%@", IPFSManager.urlPrefix, alarmsHash)
    }
}
