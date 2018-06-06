//
//  EditCameraViewController.swift
//  camX
//
//  Created by Liqiao Ying on 2018-05-22.
//  Copyright © 2018 Liqiao Ying. All rights reserved.
//

import UIKit

class EditCameraViewController: UIViewController {

    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var ipTextField: UITextField!
    @IBOutlet weak var userTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var onvifSwitch: UISwitch!
    
    var indexPath: Array<Int>?
    var cameraIndex = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cameraIndex = (indexPath == nil) ? -1 : indexPath![1]
        self.onvifSwitch.isOn = (indexPath == nil) ? true : ((indexPath![0] == 0) ? true : false)
        self.title = (cameraIndex == -1) ?  "Add Camera" : "Edit Camera"
        
        self.onvifSwitch.isEnabled = (cameraIndex == -1) ? true : false
        
        saveButton.action = #selector(saveButtonClicked)
        
        if cameraIndex > -1 {
            let camera = self.onvifSwitch.isOn ? CameraManager.sharedInstance.onvifCameras[cameraIndex] :
                                                 CameraManager.sharedInstance.ipCameras[cameraIndex]
            
            nameTextField.text = camera.name
            ipTextField.text = camera.ip
            userTextField.text = camera.user
            passwordTextField.text = camera.password
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func saveButtonClicked() {
        
        let name = nameTextField.text ?? "New Camera"
        let ip = ipTextField.text ?? ""
        let user = userTextField.text ?? ""
        let password = passwordTextField.text ?? ""
        let cameraType: Camera.CameraType = onvifSwitch.isOn ? .ONVIF : .IP
        
        let camera = Camera(name: name, ip: ip, username: user, password: password, type: cameraType)
        if cameraIndex == -1 {
            CameraManager.sharedInstance.addCamera(camera)
        } else {
            CameraManager.sharedInstance.editCamera(camera, index: cameraIndex)
        }
        
        CameraManager.sharedInstance.saveCameras(type: cameraType)
        
        navigationController?.popViewController(animated: true)
    }
}
