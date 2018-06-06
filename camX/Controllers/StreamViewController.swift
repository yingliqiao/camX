//
//  StreamViewController.swift
//  camX
//
//  Created by Liqiao Ying on 2018-05-01.
//  Copyright © 2018 Liqiao Ying. All rights reserved.
//

import UIKit
import ONVIFCamera

import Vision
import AVFoundation
import CoreMedia
import VideoToolbox

@objcMembers class StreamViewController: UIViewController, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var frameView: UIImageView!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var pixelBuffer: CVPixelBuffer?
    
    let titleView = UITextView()
    let logoLayer = CALayer()
    
    var camera: Camera!
    var onvifCamera: ONVIFCamera = ONVIFCamera(with: "XX", credential: nil)
    
    var ffmpegVideoPlayer :FFmpegVideoPlayer = FFmpegVideoPlayer.sharedInstance()
    var frameTimer :Timer?
    
    var request: VNCoreMLRequest!
    
    var boundingBoxes = [BoundingBox]()
    var colors: [UIColor] = []
    var framesDone = 0
    var frameCapturingStartTime = CACurrentMediaTime()
    
    var isDetecting = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        timeLabel.text = ""
        
        let tapRecognizer = UITapGestureRecognizer(target:self, action:#selector(handleTap(recognizer:)))
        tapRecognizer.delegate = self
        frameView.addGestureRecognizer(tapRecognizer)
        
        frameView.contentMode = .scaleAspectFit;
        
        setUpTitle()
        setUpLogo()
        
        setUpBoundingBoxes()
        setUpVision()
        
        // Add the bounding box layers to the UI, on top of the video preview.
        for box in self.boundingBoxes {
            box.addToLayer(self.frameView.layer)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        
        self.activityIndicator.startAnimating()
        
        if camera.type == Camera.CameraType.ONVIF {
            onvifCamera = ONVIFCamera(with: camera.ip,
                                      credential: (login: camera.user, password: camera.password),
                                      soapLicenseKey: Config.soapLicenseKey)
            onvifCamera.getServices {
                self.getDeviceInformation()
            }
        } else {
            self.playVideo(uri: camera.ip)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.frameTimer?.invalidate()
        self.frameView.image = nil
        
        DispatchQueue.global().async {
            self.ffmpegVideoPlayer.stop()
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        self.titleView.removeFromSuperview()
        self.logoLayer.removeFromSuperlayer()
    }
    
    func handleTap(recognizer: UITapGestureRecognizer) {
        let hidden = self.navigationController?.navigationBar.isHidden
        self.navigationController?.setNavigationBarHidden(!hidden!, animated: true)
    }
    
    func setUpTitle() {
        titleView.backgroundColor = UIColor.black
        titleView.alpha = 0.7
        titleView.textColor = UIColor.white
        titleView.isEditable = false
        titleView.font = CTFontCreateWithName("Menlo" as CFString, 14, nil)
        titleView.text = self.camera.name
        titleView.textAlignment = .center
        titleView.sizeToFit()
    }
    
    func setUpLogo() {
        let logo = UIImage(named:"logo")?.cgImage
        logoLayer.contents = logo
    }
    
    // MARK: ONVIF Camera
    private func getDeviceInformation() {
        onvifCamera.getCameraInformation(callback: { (camera) in
            self.updateProfiles()
        }, error: { (reason) in
        })
    }
    
    private func updateProfiles() {
        if onvifCamera.state == .Connected {
            onvifCamera.getProfiles(profiles: { (profiles) -> () in
                if profiles.count > 0 {
                    self.onvifCamera.getStreamURI(with: profiles.first!.token, uri: { (uri) in
                        self.playVideo(uri: self.onvifCamera.streamURI!)
                    })
                }
            })
        }
    }
    
    func playVideo(uri: String) {
        DispatchQueue.global().async {
            self.ffmpegVideoPlayer.initWithVideo(uri, usesTcp: true)
            
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                
                self.frameTimer = Timer.scheduledTimer(timeInterval: self.ffmpegVideoPlayer.interval, target: self, selector: #selector(self.displayNextFrame), userInfo: nil, repeats: false)
            }
        }
    }
    
    @objc func displayNextFrame() {
        self.frameTimer?.invalidate()
        
        DispatchQueue.global().async {
            self.ffmpegVideoPlayer.stepFrame()
            
            DispatchQueue.main.async {
                self.frameView.image = self.ffmpegVideoPlayer.currentImage()
                
                if self.frameView.image != nil && !(self.frameView.layer.sublayers?.contains(self.logoLayer))! {
                    let imageBounds = self.getImageBounds()
                    self.titleView.frame = CGRect(x: imageBounds.origin.x, y: imageBounds.origin.y,
                                                   width: imageBounds.size.width, height: 34)
                    self.frameView.addSubview(self.titleView)
                    self.logoLayer.frame = CGRect(x: imageBounds.origin.x + 10, y: imageBounds.origin.y + 44, width: imageBounds.size.width / 8, height: imageBounds.size.width / 40)
                    self.frameView.layer.sublayers?.append(self.logoLayer)
                }
                
                if SettingManager.sharedInstance.getYoloModel() == .None {
                    self.timeLabel.text = "Object detection is off"
                } else if self.frameView.image != nil && !self.isDetecting {
                    self.detectObjects()
                }
                
                self.frameTimer = Timer.scheduledTimer(timeInterval: self.ffmpegVideoPlayer.interval, target: self, selector: #selector(self.displayNextFrame), userInfo: nil, repeats: false)
            }
        }
    }
    
    func getImageBounds() -> CGRect {
        let size = self.frameView.bounds.size
        let imageAspectRatio = self.frameView.image!.size.width / self.frameView.image!.size.height
        let viewAspectRatio = size.width / size.height
        let viewX: CGFloat, viewY: CGFloat, viewWidth: CGFloat, viewHeight: CGFloat
        if imageAspectRatio < viewAspectRatio {
            viewHeight = size.height
            viewWidth = size.height * imageAspectRatio
            viewX = (size.width - viewWidth ) / 2
            viewY = 0
        } else {
            viewWidth = size.width
            viewHeight = size.width / imageAspectRatio
            viewX = 0
            viewY = (size.height - viewHeight) / 2
        }
        return CGRect(x: viewX, y: viewY, width: viewWidth, height: viewHeight)
    }
    
    func detectObjects() {
        let image = self.frameView.image!
        pixelBuffer = image.pixelBuffer(width: image.size.width, height: image.size.height)
        DispatchQueue.global().async {
            self.isDetecting = true
            self.predictUsingVision(pixelBuffer: self.pixelBuffer!)
        }
    }
    
    // MARK: Object Detection
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
    
    // MARK: Doing inference
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
            
            if self.viewIfLoaded?.window != nil {
                self.show(predictions: boundingBoxes)
                
                let fps = self.measureFPS()
                self.timeLabel.text = String(format: "%@ Object detection - %.2f FPS", SettingManager.sharedInstance.modelName, fps)
                
                self.isDetecting = false
            }
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
                    let width = self.frameView.contentClippingRect.size.width
                    let height = self.frameView.contentClippingRect.size.height
                    let scaleX = width / CGFloat(SettingManager.sharedInstance.inputWidth)
                    let scaleY = height / CGFloat(SettingManager.sharedInstance.inputHeight)
                    
                    // Translate and scale the rectangle to our own coordinate system.
                    var rect = prediction.rect
                    rect.origin.x *= scaleX
                    rect.origin.x += self.frameView.contentClippingRect.origin.x
                    rect.origin.y *= scaleY
                    rect.origin.y += self.frameView.contentClippingRect.origin.y
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
        
        if alarmObjectIndex > -1 && self.frameView.image != nil {
            SettingManager.sharedInstance.lastAlarmTime = Date()
            let image = self.renderAlarmImage()
            if image != nil  {
                //UIImageWriteToSavedPhotosAlbum(image!, nil, nil, nil)
                let alarm = Alarm(timestamp: AlarmManager.sharedInstance.timestampFormatter.string(from: Date()), camera: self.camera.name, object: SettingManager.sharedInstance.labels[alarmObjectIndex], model: SettingManager.sharedInstance.modelName, image: image!)
                AlarmManager.sharedInstance.alarms.insert(alarm, at: 0)
            }
        }
    }
    
    func renderAlarmImage() -> UIImage? {
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer!)
        let uiImage = UIImage(ciImage: ciImage)
        
        let containerView = UIImageView(frame: self.frameView.bounds)
        containerView.contentMode = .scaleAspectFit
        containerView.image = uiImage
        self.frameView.addSubview(containerView)
        self.frameView.sendSubview(toBack: containerView)
        
        let scale = UIScreen.main.scale
        
        // Take screenshot
        UIGraphicsBeginImageContextWithOptions(self.frameView.bounds.size, false, scale)
        self.frameView.drawHierarchy(in: self.frameView.bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        containerView.removeFromSuperview();
        
        // Cropping
        let imageBounds = self.getImageBounds()
        let cropBounds = CGRect(x: imageBounds.origin.x * scale, y: imageBounds.origin.y * scale,
                                width: imageBounds.size.width * scale, height: imageBounds.size.height * scale)
        let imageRef = image!.cgImage!.cropping(to: cropBounds)
        let croppedImage = UIImage(cgImage: imageRef!)
        return croppedImage
    }
}
