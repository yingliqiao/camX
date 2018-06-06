//
//  Alarm.swift
//  camX
//
//  Created by Liqiao Ying on 2018-05-27.
//  Copyright © 2018 Liqiao Ying. All rights reserved.
//

import Foundation

class Alarm: Codable {

    var timestamp: String
    var camera: String
    var object: String
    var model: String
    var image: UIImage?
    
    var saved = false
    
    // IPFS image hash
    var imageHash = ""
    
    // IPFS metadata hash
    var metadataHash = ""
    
    // Ethereum transaction receipt hash
    var txHash = ""
    
    init(timestamp: String, camera: String, object: String, model: String, image: UIImage) {
        
        self.timestamp = timestamp
        self.camera = camera
        self.object = object
        self.model = model
        self.image = image
    }
    
    enum CodingKeys: String, CodingKey {
        case metadataHash
        case timestamp
        case camera
        case object
        case model
        case imageHash
    }
    
    func alarmMetadata() -> String {
        var html = "<!doctype html><html lang=en><title>CamX</title>"
        html += String(format: "<div>%@</div>", self.timestamp)
        html += String(format: "<div>%@</div>", self.camera)
        html += String(format: "<div>%@</div>", self.object)
        html += String(format: "<div>%@</div>", self.model)
        html += String(format: "<div><a href=\"%@\">%@</a></div>", self.imageHashURL(), self.imageHash)
        html += String(format: "<div><img src=\"%@\" style=\"max-height:400px\"/></div>", self.imageHashURL())
        return html
    }
    
    func imageHashURL() -> String {
        return String(format:"%@%@", IPFSManager.urlPrefix, imageHash)
    }
    
    func metadataHashURL() -> String {
        return String(format:"%@%@", IPFSManager.urlPrefix, metadataHash)
    }
}
