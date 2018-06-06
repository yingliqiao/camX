//
//  Config.swift
//  camX
//
//  Created by Liqiao Ying on 2018-04-30.
//  Copyright © 2018 Liqiao Ying. All rights reserved.
//

struct Config {
    
    // SOAPEngine license key
    static let soapLicenseKey = "nU8Yi3Turrn42DmbDIelGDPvYzatf4ZJTE6SF2GwHtZFcaGzSM+JxCE+YyK7M69KOo58YsA4scb/WqeaKklRgA=="
    
    // YOLO2 - The labels for the 80 classes
    static let labelYolo2: [String] = [
        "person", "bicycle", "car", "motorbike", "aeroplane", "bus", "train", "truck", "boat", "traffic light",
        "fire hydrant", "stop sign", "parking meter", "bench", "bird", "cat", "dog", "horse", "sheep", "cow",
        "elephant", "bear", "zebra", "giraffe", "backpack", "umbrella", "handbag", "tie", "suitcase", "frisbee",
        "skis", "snowboard", "sports ball", "kite", "baseball bat", "baseball glove", "skateboard", "surfboard", "tennis racket", "bottle",
        "wine glass", "cup", "fork", "knife", "spoon", "bowl", "banana", "apple", "sandwich", "orange",
        "broccoli", "carrot", "hot dog", "pizza", "donut", "cake", "chair", "sofa", "pottedplant", "bed",
        "diningtable", "toilet", "tvmonitor", "laptop", "mouse", "remote", "keyboard", "cell phone", "microwave", "oven",
        "toaster", "sink", "refrigerator", "book", "clock", "vase", "scissors", "teddy bear", "hair drier", "toothbrush"
    ]
    
    // TinyYOLO - The labels for the 20 classes.
    static let labelsTinyYolo: [String] = [
        "aeroplane", "bicycle", "bird", "boat", "bottle", "bus", "car", "cat", "chair", "cow",
        "diningtable", "dog", "horse", "motorbike", "person", "pottedplant", "sheep", "sofa", "train", "tvmonitor"
    ]
    
    static let linkedInURL = "https://www.linkedin.com/in/liqiaoying/"
    
    static let gmailURL = "benhero@gmail.com"
}

