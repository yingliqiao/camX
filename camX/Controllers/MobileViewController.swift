//
//  MobileViewController.swift
//  camX
//
//  Created by Liqiao Ying on 2018-05-07.
//  Copyright © 2018 Liqiao Ying. All rights reserved.
//

import UIKit
import Vision
import AVFoundation
import CoreMedia
import VideoToolbox

class MobileViewController: UIViewController, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var videoPreview: UIView!
    @IBOutlet weak var timeLabel: UILabel!
    
    var pixelBuffer : CVPixelBuffer?
    
    let logoLayer = CALayer()
    
    var videoCapture: VideoCapture!
    var request: VNCoreMLRequest!
    
    var boundingBoxes = [BoundingBox]()
    var colors: [UIColor] = []
    
    var framesDone = 0
    var frameCapturingStartTime = CACurrentMediaTime()
    
    let semaphore = DispatchSemaphore(value: 2)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tapRecognizer = UITapGestureRecognizer(target:self, action:#selector(handleTap(recognizer:)))
        tapRecognizer.delegate = self
        videoPreview.addGestureRecognizer(tapRecognizer)
        
        setUpLogo()
        
        setUpBoundingBoxes()
        setUpVision()
        setUpCamera()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.videoCapture.stop()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print(#function)
    }
    
    @objc func handleTap(recognizer: UITapGestureRecognizer) {
        let hidden = self.navigationController?.navigationBar.isHidden
        self.navigationController?.setNavigationBarHidden(!hidden!, animated: true)
    }
    
    func setUpLogo() {
        let logo = UIImage(named:"logo")?.cgImage
        logoLayer.contents = logo
    }
    
    // MARK: - Initialization
    
    func setUpBoundingBoxes() {
        for _ in 0..<SettingManager.sharedInstance.maxBoundingBoxes {
            boundingBoxes.append(BoundingBox())
        }
        
        // Make colors for the bounding boxes. There is one color for each class,
        // 80 classes in total.
        for r: CGFloat in [0.2, 0.4, 0.6, 0.85, 1.0] {
            for g: CGFloat in [0.6, 0.7, 0.8, 0.9] {
                for b: CGFloat in [0.6, 0.7, 0.8, 1.0] {
                    let color = UIColor(red: r, green: g, blue: b, alpha: 1)
                    colors.append(color)
                }
            }
        }
    }
    
    func setUpVision() {
        guard let visionModel = try? VNCoreMLModel(for: SettingManager.sharedInstance.mlModel!) else {
            print("Error: could not create Vision model")
            return
        }
        
        request = VNCoreMLRequest(model: visionModel, completionHandler: visionRequestDidComplete)
        
        // NOTE: If you choose another crop/scale option, then you must also
        // change how the BoundingBox objects get scaled when they are drawn.
        // Currently they assume the full input image is used.
        request.imageCropAndScaleOption = .scaleFill
    }
    
    func setUpCamera() {
        videoCapture = VideoCapture()
        videoCapture.delegate = self
        videoCapture.fps = 30
        videoCapture.setUp(sessionPreset: AVCaptureSession.Preset.vga640x480) { success in
            if success {
                // Add the video preview into the UI.
                if let previewLayer = self.videoCapture.previewLayer {
                    self.videoPreview.layer.addSublayer(previewLayer)
                    self.resizePreviewLayer()
                }
                
                // Add the bounding box layers to the UI, on top of the video preview.
                for box in self.boundingBoxes {
                    box.addToLayer(self.videoPreview.layer)
                }
                
                // Once everything is set up, we can start capturing live video.
                self.videoCapture.start()
            }
        }
    }
    
    // MARK: - UI stuff
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        resizePreviewLayer()
    }
    
    func resizePreviewLayer() {
        videoCapture.previewLayer?.frame = videoPreview.bounds
        self.logoLayer.removeFromSuperlayer()
    }
    
    // MARK: - Doing inference
    func predictUsingVision(pixelBuffer: CVPixelBuffer) {
        // Vision will automatically resize the input image.
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer)
        try? handler.perform([request])
    }
    
    func visionRequestDidComplete(request: VNRequest, error: Error?) {
        if let observations = request.results as? [VNCoreMLFeatureValueObservation],
            let features = observations.first?.featureValue.multiArrayValue {
            
            let boundingBoxes = SettingManager.sharedInstance.getYoloModel() == .TinyYolo ?
                TinyYOLO.sharedInstance.computeBoundingBoxes(features: features) : YOLO2.sharedInstance.computeBoundingBoxes(features: features) 
            showOnMainThread(boundingBoxes)
        }
    }
    
    func showOnMainThread(_ boundingBoxes: [Prediction]) {
        DispatchQueue.main.async {
            
            self.show(predictions: boundingBoxes)
            
            let fps = self.measureFPS()
            self.timeLabel.text = String(format: "%@ Object detection - %.2f FPS", SettingManager.sharedInstance.modelName, fps)
            
            self.semaphore.signal()
        }
    }
    
    func measureFPS() -> Double {
        // Measure how many frames were actually delivered per second.
        framesDone += 1
        let frameCapturingElapsed = CACurrentMediaTime() - frameCapturingStartTime
        let currentFPSDelivered = Double(framesDone) / frameCapturingElapsed
        if frameCapturingElapsed > 1 {
            framesDone = 0
            frameCapturingStartTime = CACurrentMediaTime()
        }
        return currentFPSDelivered
    }
    
    func show(predictions: [Prediction]) {
        
        var alarmObjectIndex = -1
        
        for i in 0..<boundingBoxes.count {
            if i < predictions.count {
                let prediction = predictions[i]
                
                if SettingManager.sharedInstance.getDetect(prediction.classIndex) {
                    
                    let width = self.videoPreview.bounds.size.width
                    let height = self.videoPreview.bounds.size.height
                    let scaleX = width / CGFloat(SettingManager.sharedInstance.inputWidth)
                    let scaleY = height / CGFloat(SettingManager.sharedInstance.inputHeight)
                    
                    // Translate and scale the rectangle to our own coordinate system.
                    var rect = prediction.rect
                    rect.origin.x *= scaleX
                    rect.origin.x += self.videoPreview.bounds.origin.x
                    rect.origin.y *= scaleY
                    rect.origin.y += self.videoPreview.bounds.origin.y
                    rect.size.width *= scaleX
                    rect.size.height *= scaleY
                    
                    // Show the bounding box.
                    if SettingManager.sharedInstance.getAlarm(prediction.classIndex) {
                        let label = String(format: "%@ - ALARM", SettingManager.sharedInstance.labels[prediction.classIndex])
                        boundingBoxes[i].show(frame: rect, label: label, color: .red)
                        
                        if Date().timeIntervalSince(SettingManager.sharedInstance.lastAlarmTime) > Double(SettingManager.sharedInstance.alarmThreshold){
                            alarmObjectIndex = prediction.classIndex
                        }
                    } else {
                        let label = String(format: "%@", SettingManager.sharedInstance.labels[prediction.classIndex])
                        let color = colors[prediction.classIndex]
                        boundingBoxes[i].show(frame: rect, label: label, color: color)
                    }
                }
            } else {
                boundingBoxes[i].hide()
            }
        }
        
        if alarmObjectIndex > -1 {
            SettingManager.sharedInstance.lastAlarmTime = Date()
            let image = self.renderAlarmImage()
            if image != nil  {
                //UIImageWriteToSavedPhotosAlbum(image!, nil, nil, nil)
                let alarm = Alarm(timestamp: AlarmManager.sharedInstance.timestampFormatter.string(from: Date()), camera: "Back Facing Camera", object: SettingManager.sharedInstance.labels[alarmObjectIndex], model: SettingManager.sharedInstance.modelName, image: image!)
                AlarmManager.sharedInstance.alarms.insert(alarm, at: 0)
            }
        }
    }
    
    func renderAlarmImage() -> UIImage? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer!)
        let uiImage = UIImage(ciImage: ciImage)
        
        let containerView = UIImageView(frame: self.view.bounds)
        containerView.image = uiImage
        self.videoPreview.addSubview(containerView)
        self.videoPreview.sendSubview(toBack: containerView)
        
        let scale = UIScreen.main.scale
        
        // Take screenshot
        UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, false, scale)
        self.view.drawHierarchy(in: self.view.bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        containerView.removeFromSuperview();
        
        return image
    }
}

extension MobileViewController: VideoCaptureDelegate {
    func videoCapture(_ capture: VideoCapture, didCaptureVideoFrame pixelBuffer: CVPixelBuffer?, timestamp: CMTime) {
        
        DispatchQueue.main.async {
            if !(self.videoPreview.layer.sublayers?.contains(self.logoLayer))! {
                self.logoLayer.frame = CGRect(x: 10, y: 30, width: self.videoPreview.bounds.size.width / 8, height: self.videoPreview.bounds.size.width / 40)
                self.videoPreview.layer.sublayers?.append(self.logoLayer)
            }
        }
        
        
        if SettingManager.sharedInstance.getYoloModel() == .None {
            self.timeLabel.text = "Object detection is off"
            return
        }
        
        semaphore.wait()
        
        self.pixelBuffer = pixelBuffer
        DispatchQueue.global().async {
            //self.predict(pixelBuffer: pixelBuffer)
            self.predictUsingVision(pixelBuffer: pixelBuffer!)
        }
    }
}

