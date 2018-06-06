//
//  CameraManager.swift
//  camX
//
//  Created by Liqiao Ying on 2018-05-14.
//  Copyright © 2018 Liqiao Ying. All rights reserved.
//

import Foundation

// Camera Manager class
class CameraManager {
    
    // Singleton instance
    static let sharedInstance = CameraManager()
    
    // ONVIF camera list
    var onvifCameras = [Camera]()
    
    // IP camera list
    var ipCameras = [Camera]()
    
    // Add some default cameras to User Defaults
    public func addDefaultCameras() {
        let onvifCamerasPath = Bundle.main.path(forResource: "onvifCameras", ofType: "json")
        let onvifCamerasData = try! Data(contentsOf: URL(fileURLWithPath: onvifCamerasPath!))
        self.onvifCameras = try! JSONDecoder().decode([Camera].self, from: onvifCamerasData)
        self.saveCameras(type: Camera.CameraType.ONVIF)

        let ipCamerasPath = Bundle.main.path(forResource: "ipCameras", ofType: "json")
        let ipCamerasData = try! Data(contentsOf: URL(fileURLWithPath: ipCamerasPath!))
        self.ipCameras = try! JSONDecoder().decode([Camera].self, from: ipCamerasData)
        self.saveCameras(type: Camera.CameraType.IP)
    }
    
    // Add a new camera
    func addCamera(_ camera: Camera) {
        if camera.type == .ONVIF {
            onvifCameras.append(camera)
            saveCameras(type: .ONVIF)
        } else if camera.type == .IP {
            ipCameras.append(camera)
            saveCameras(type: .IP)
        }
    }
    
    // Edit a camera
    func editCamera(_ camera: Camera, index: Int) {
        if camera.type == .ONVIF {
            onvifCameras[index] = camera
            saveCameras(type: .ONVIF)
        } else if camera.type == .IP {
            ipCameras[index] = camera
            saveCameras(type: .IP)
        }
    }
    
    // Save cameras to User Defaults per type
    func saveCameras(type:Camera.CameraType) {
        let encoder = JSONEncoder()
        if type == Camera.CameraType.ONVIF {
            if let encoded = try? encoder.encode(onvifCameras) {
                UserDefaults.standard.set(encoded, forKey: type.rawValue)
            }
        } else {
            if let encoded = try? encoder.encode(ipCameras) {
                UserDefaults.standard.set(encoded, forKey: type.rawValue)
            }
        }
        UserDefaults.standard.synchronize()
    }
    
    // Restore cameras from User Defaults per type
    func restoreCameras(type:Camera.CameraType) {
        let decoder = JSONDecoder()
        if let decodedData = UserDefaults.standard.data(forKey: type.rawValue) {
            if type == Camera.CameraType.ONVIF {
                onvifCameras = try! decoder.decode([Camera].self, from: decodedData)
            } else {
                ipCameras = try! decoder.decode([Camera].self, from: decodedData)
            }
        }
    }
}
