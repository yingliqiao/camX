//
//  SettingManager.swift
//  camX
//
//  Created by Liqiao Ying on 2018-05-20.
//  Copyright © 2018 Liqiao Ying. All rights reserved.
//

import Foundation
import CoreML
import web3swift

class SettingManager {
    
    // Device unique identifier
    var uuID = ""
    
    // Whether each Yolo2 object would be detected or not
    var detectsYolo2 = Array<Bool>(repeating: true, count: 80)
    
    // Whether each Tiny Yolo object would be detected or not
    var detectsTinyYolo = Array<Bool>(repeating: true, count: 20)
    
    // Whether each Yolo2 object would raise alarm or not
    var alarmsYolo2 = Array<Bool>(repeating: false, count: 80)
    
    // Whether each Tiny Yolo object would raise alarm or not
    var alarmsTinyYolo = Array<Bool>(repeating: false, count: 20)
    
    // Keep track of last alarm raised time
    var lastAlarmTime = Date.distantPast
    
    // Store one per threshold alarms
    var alarmThreshold = 10
    
    var labels = Config.labelYolo2
    
    // YOLO2 input is 608x608
    var inputWidth = 608
    var inputHeight = 608
    
    let maxBoundingBoxes = 10
    
    var mlModel : MLModel?
    
    var modelName = "YOLO 2"
    
    enum YoloModel: String, Codable {
        case None
        case Yolo2
        case TinyYolo
    }
    
    private var yoloModel = YoloModel.Yolo2
    
    // Singleton instance
    static let sharedInstance = SettingManager()
    
    private init() {
        mlModel = YOLO2.sharedInstance.model.model
    }
    
    func initialize() {
        
        initializeEthereumKeystoreManager()
        
        self.saveUUID()
        self.saveDetectsYolo2()
        self.saveDetectsTinyYolo()
        self.saveAlarmsYolo2()
        self.saveAlarmsTinyYolo()
        self.saveYoloModel()
        self.saveAlarmStorageThreshold()
    }
    
    fileprivate func initializeEthereumKeystoreManager() {
        let userDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let keystoreManager = KeystoreManager.managerForPath(userDir + "/keystore")
        if keystoreManager != nil {
            let privateKeyData = Data.fromHex(EthereumManager.rinkebyPrivateKey)
            let keystore = try! EthereumKeystoreV3(privateKey: privateKeyData!, password: EthereumManager.rinkebyPassword)
            let keydata = try! JSONEncoder().encode(keystore!.keystoreParams)
            FileManager.default.createFile(atPath: userDir + "/keystore"+"/key.json", contents: keydata, attributes: nil)
        }
    }
    
    func restore() {
        self.restoreUUID()
        self.restoreDetectsYolo2()
        self.restoreDetectsTinyYolo()
        self.restoreAlarmsYolo2()
        self.restoreAlarmsTinyYolo()
        self.restoreYoloModel()
        self.restoreAlarmStorageThreshold()
    }
    
    func getDetect(_ index: Int) -> Bool {
        switch yoloModel {
        case .TinyYolo:
            return detectsTinyYolo[index]
        default:
            return detectsYolo2[index]
        }
    }
    
    func setDetect(index: Int, state: Bool) {
        switch yoloModel {
        case .TinyYolo:
            detectsTinyYolo[index] = state
        default:
            detectsYolo2[index] = state
        }
    }
    
    func getAlarm(_ index: Int) -> Bool {
        switch yoloModel {
        case .TinyYolo:
            return alarmsTinyYolo[index]
        default:
            return alarmsYolo2[index]
        }
    }
    
    func setAlarm(index: Int, state: Bool) {
        switch yoloModel {
            case .TinyYolo:
                alarmsTinyYolo[index] = state
            default:
                alarmsYolo2[index] = state
        }
    }
    
    func getYoloModel() -> YoloModel {
        return yoloModel
    }
    
    func updateYoloModel(model: YoloModel) {
        switch model {
            case .None:
                modelName = "None"
            case .TinyYolo:
                modelName = "Tiny YOLO"
                labels = Config.labelsTinyYolo
                inputWidth = 416
                inputHeight = 416
                mlModel = TinyYOLO.sharedInstance.model.model
            default:
                modelName = "YOLO 2"
                labels = Config.labelYolo2
                inputWidth = 608
                inputHeight = 608
                mlModel = YOLO2.sharedInstance.model.model
        }
        yoloModel = model
        self.saveYoloModel()
    }
    
    func saveYoloModel() {
        UserDefaults.standard.set(yoloModel.rawValue, forKey: "YoloModel")
        UserDefaults.standard.synchronize()
    }
    
    func restoreYoloModel() {
        let rawValue = UserDefaults.standard.string(forKey: "YoloModel")!
        yoloModel = YoloModel(rawValue: rawValue)!
        self.updateYoloModel(model: yoloModel)
    }
    
    func saveDetects() {
        switch yoloModel {
        case .TinyYolo:
            self.saveDetectsTinyYolo()
        default:
            self.saveDetectsYolo2()
        }
        // Detect changes alarm states
        saveAlarms()
    }
    
    func saveAlarms() {
        switch yoloModel {
            case .TinyYolo:
                self.saveAlarmsTinyYolo()
            default:
                self.saveAlarmsYolo2()
        }
    }
    
    func saveUUID() {
        uuID = UUID().uuidString
        UserDefaults.standard.set(uuID, forKey: "UUID")
        UserDefaults.standard.synchronize()
    }
    
    func restoreUUID() {
        uuID = UserDefaults.standard.string(forKey: "UUID")!
    }
    
    func saveDetectsYolo2() {
        UserDefaults.standard.set(detectsYolo2, forKey: "DetectsYolo2")
        UserDefaults.standard.synchronize()
    }
    
    func saveDetectsTinyYolo() {
        UserDefaults.standard.set(detectsTinyYolo, forKey: "DetectsTinyYolo")
        UserDefaults.standard.synchronize()
    }
    
    func restoreDetectsYolo2() {
        detectsYolo2 = UserDefaults.standard.array(forKey: "DetectsYolo2")! as! [Bool]
    }
    
    func restoreDetectsTinyYolo() {
        detectsTinyYolo = UserDefaults.standard.array(forKey: "DetectsTinyYolo")! as! [Bool]
    }
    
    func saveAlarmsYolo2() {
        UserDefaults.standard.set(alarmsYolo2, forKey: "AlarmsYolo2")
        UserDefaults.standard.synchronize()
    }
    
    func saveAlarmsTinyYolo() {
        UserDefaults.standard.set(alarmsTinyYolo, forKey: "AlarmsTinyYolo")
        UserDefaults.standard.synchronize()
    }
    
    func restoreAlarmsYolo2() {
        alarmsYolo2 = UserDefaults.standard.array(forKey: "AlarmsYolo2")! as! [Bool]
    }
    
    func restoreAlarmsTinyYolo() {
        alarmsTinyYolo = UserDefaults.standard.array(forKey: "AlarmsTinyYolo")! as! [Bool]
    }
    
    func saveAlarmStorageThreshold() {
        UserDefaults.standard.set(alarmThreshold, forKey: "AlarmThreshold")
        UserDefaults.standard.synchronize()
    }
    
    func restoreAlarmStorageThreshold() {
        alarmThreshold = UserDefaults.standard.integer(forKey: "AlarmThreshold")
    }
}
