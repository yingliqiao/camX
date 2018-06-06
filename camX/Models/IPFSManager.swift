//
//  IPFSManager.swift
//  camX
//
//  Created by Liqiao Ying on 2018-05-27.
//  Copyright © 2018 Liqiao Ying. All rights reserved.
//

import Foundation

import SwiftBase58
import SwiftMultihash
import SwiftIpfsApi

class IPFSManager {
    
    static let host = "ipfs.infura.io"
    static let urlPrefix = "https://ipfs.infura.io/ipfs/"
    static let port = 5001
    static let version = "/api/v0/"
    static let ssl = true
    
    static let sharedInstance = IPFSManager()
    
    func saveAlarmImage(_ alarm: Alarm) {
        do {
            let api = try IpfsApi(host: IPFSManager.host, port: IPFSManager.port, version: IPFSManager.version, ssl: IPFSManager.ssl)
            let imageData = UIImagePNGRepresentation(alarm.image!)
            try api.add(imageData!) {
                result in
                alarm.imageHash = b58String(result[0].hash!)
                NotificationCenter.default.post(name: .IPFSSaveAlarmImage, object: self, userInfo: nil)
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func saveAlarmMetadata(_ alarm: Alarm) {
        do {
            let api = try IpfsApi(host: IPFSManager.host, port: IPFSManager.port, version: IPFSManager.version, ssl: IPFSManager.ssl)
            let metadata = alarm.alarmMetadata().data(using: .utf8)
            try api.add(metadata!) {
                result in
                alarm.metadataHash = b58String(result[0].hash!)
                NotificationCenter.default.post(name: .IPFSSaveAlarmMetadata, object: self, userInfo: nil)
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func updateAlarms() {
        do {
            let api = try IpfsApi(host: IPFSManager.host, port: IPFSManager.port, version: IPFSManager.version, ssl: IPFSManager.ssl)
            let encodedData = try? JSONEncoder().encode(AlarmManager.sharedInstance.getSavedAlarms())
            try api.add(encodedData!) {
                result in
                AlarmManager.sharedInstance.alarmsHash = b58String(result[0].hash!)
                NotificationCenter.default.post(name: .IPFSAlarmsUpdated, object: self, userInfo: nil)
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func retrieveAlarms() {
        do {
            let api = try IpfsApi(host: IPFSManager.host, port: IPFSManager.port, version: IPFSManager.version, ssl: IPFSManager.ssl)
            let multihash = try fromB58String(AlarmManager.sharedInstance.alarmsHash)
            try api.cat(multihash) {
                result in
                let alarms = try? JSONDecoder().decode([Alarm].self, from: Data(fromArray: result))
                NotificationCenter.default.post(name: .IPFSAlarmMetadataRetrieved, object: self, userInfo: nil)
                if alarms != nil {
                    for alarm in alarms! {
                        alarm.saved = true
                        AlarmManager.sharedInstance.alarms.append(alarm)
                    }
                    self.retrieveAlarmImages(alarms!)
                } else {
                    NotificationCenter.default.post(name: .IPFSAlarmImagesRetrieved, object: self, userInfo: nil)
                }
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func retrieveAlarmImages(_ alarms: [Alarm]) {
        let group = DispatchGroup()
        
        do {
            let api = try IpfsApi(host: IPFSManager.host, port: IPFSManager.port, version: IPFSManager.version, ssl: IPFSManager.ssl)
            for alarm in alarms {
                group.enter()
                let multihash = try fromB58String(alarm.imageHash)
                try api.cat(multihash) {
                    result in
                    alarm.image = UIImage(data: Data(fromArray: result))
                    group.leave()
                }
            }
        } catch {
            print(error.localizedDescription)
        }
        
        group.notify(queue: .main) {
            NotificationCenter.default.post(name: .IPFSAlarmImagesRetrieved, object: self, userInfo: nil)
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}
