//
//  Camera.swift
//  camX
//
//  Created by Liqiao Ying on 2018-04-30.
//  Copyright © 2018 Liqiao Ying. All rights reserved.
//

// Camera model class
class Camera: Codable {
    
    // Camera types enum
    enum CameraType: String, Codable {
        case ONVIF
        case IP
    }
    
    // Camera name
    var name: String
    
    // Camera ip address
    var ip: String
    
    // Camera user name
    var user: String
    
    // Camera user password
    var password: String
    
    // Camera type
    var type: CameraType
    
    // Constructor
    init(name: String, ip: String, username: String, password: String, type: CameraType) {
        self.name = name
        self.ip = ip
        self.user = username
        self.password = password
        self.type = type
    }
}
