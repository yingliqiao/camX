//
//  CameraTableViewController.swift
//  camX
//
//  Created by Liqiao Ying on 2018-04-25.
//  Copyright © 2018 Liqiao Ying. All rights reserved.
//

import UIKit

class CameraTableViewController: UITableViewController {
    
    @IBOutlet weak var addButton: UIBarButtonItem!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        deleteButton.target = self
        deleteButton.action = #selector(deleteCameraClicked)
        
        CameraManager.sharedInstance.restoreCameras(type: Camera.CameraType.ONVIF)
        CameraManager.sharedInstance.restoreCameras(type: Camera.CameraType.IP)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()
    }
    
    @objc func deleteCameraClicked() {
        tableView.isEditing = !tableView.isEditing
    }
    
    // MARK: Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.textColor = UIColor.white
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "ONVIF Demo Cameras"
        } else if section == 1 {
            return "IP Cameras"
        } else {
            return "Mobile Cameras"
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return CameraManager.sharedInstance.onvifCameras.count
        } else if section == 1 {
            return CameraManager.sharedInstance.ipCameras.count
        } else {
            return 1
        }
    }
   
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CameraCell", for: indexPath)
        if indexPath.section == 0 {
            cell.accessoryType = .detailDisclosureButton
            cell.textLabel?.text = CameraManager.sharedInstance.onvifCameras[indexPath.row].name
            cell.detailTextLabel?.text = CameraManager.sharedInstance.onvifCameras[indexPath.row].ip
        } else if indexPath.section == 1 {
            cell.accessoryType = .detailDisclosureButton
            cell.textLabel?.text = CameraManager.sharedInstance.ipCameras[indexPath.row].name
            cell.detailTextLabel?.text = CameraManager.sharedInstance.ipCameras[indexPath.row].ip
        } else {
            cell.accessoryType = .none
            cell.textLabel?.text = "Back Facing Camera"
            cell.detailTextLabel?.text = "iOS device build-in camera"
        }
        
        return cell;
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            let camera = CameraManager.sharedInstance.onvifCameras[indexPath.row];
            performSegue(withIdentifier: "showStreamVC", sender: camera)
        } else if indexPath.section == 1 {
            let camera = CameraManager.sharedInstance.ipCameras[indexPath.row];
            performSegue(withIdentifier: "showStreamVC", sender: camera)
        } else {
            performSegue(withIdentifier: "showMobileVC", sender: self)
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 2 ? false : true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if indexPath.section == 0 {
                CameraManager.sharedInstance.onvifCameras.remove(at: indexPath.row)
                CameraManager.sharedInstance.saveCameras(type: .ONVIF)
            } else if indexPath.section == 1 {
                CameraManager.sharedInstance.ipCameras.remove(at: indexPath.row)
                CameraManager.sharedInstance.saveCameras(type: .IP)
            }
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        performSegue(withIdentifier: "editCameraVC", sender: [indexPath.section, indexPath.row])
    }
    
    // MARK: Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let camera = sender as? Camera, let controller = segue.destination as? StreamViewController {
            controller.camera = camera
        } else if let indexPath = sender as? Array<Int>, let controller = segue.destination as? EditCameraViewController {
            controller.indexPath = indexPath
        }
    }
}

