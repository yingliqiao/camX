//
//  BlockchainViewController.swift
//  camX
//
//  Created by Liqiao Ying on 2018-05-28.
//  Copyright © 2018 Liqiao Ying. All rights reserved.
//

import UIKit

class BlockchainViewController: UIViewController {

    @IBOutlet weak var ipfsLoadingView: UIActivityIndicatorView!
    @IBOutlet weak var ipfsSaveButton: UIButton!
    @IBOutlet weak var ipfsMetadataHashLabel: UILabel!
    @IBOutlet weak var ipfsMetadataHashURLButton: UIButton!
    
    @IBOutlet weak var ipfsAlarmsHashLabel: UILabel!
    @IBOutlet weak var ipfsAlarmsHashURLButton: UIButton!
    
    @IBOutlet weak var ethereumTxHashLabel: UILabel!
    @IBOutlet weak var ethereumTxHashURLButton: UIButton!
    
    let alarm = AlarmManager.sharedInstance.currentAlarm!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.updateUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ipfsImageSaved), name:.IPFSSaveAlarmImage, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ipfsMetadataSaved), name:.IPFSSaveAlarmMetadata, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ipfsAlarmsUpdated), name:.IPFSAlarmsUpdated, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: .IPFSSaveAlarmImage, object: nil)
        NotificationCenter.default.removeObserver(self, name: .IPFSSaveAlarmMetadata, object: nil)
        NotificationCenter.default.removeObserver(self, name: .IPFSAlarmsUpdated, object: nil)
    }
    
    func updateUI() {
        alarm.saved ? ipfsSaveButton.setTitle("Delete Alarm", for: .normal) : ipfsSaveButton.setTitle("Save Alarm", for: .normal)
        ipfsMetadataHashURLButton.isHidden = (alarm.metadataHash == "")
        ipfsAlarmsHashURLButton.isHidden = (AlarmManager.sharedInstance.alarmsHash == "")
        ethereumTxHashURLButton.isHidden = (alarm.txHash == "")
        
        ipfsMetadataHashLabel.text = String(format: "Metadata Hash: %@", self.alarm.metadataHash)
        ipfsAlarmsHashLabel.text = String(format: "Saved Alarms Hash: %@", AlarmManager.sharedInstance.alarmsHash)
        ethereumTxHashLabel.text = String(format:"Tx Hash: %@", self.alarm.txHash)
    }
    
    @IBAction func ipfsMetadataHashURLButtonClicked(_ sender: Any) {
        let url = URL(string: alarm.metadataHashURL())
        UIApplication.shared.open(url!)
    }
    
    @IBAction func ipfsAlarmsHashURLButtonClicked(_ sender: Any) {
        let url = URL(string: AlarmManager.sharedInstance.alarmsHashURL())
        UIApplication.shared.open(url!)
    }
    
    @IBAction func ethereumTxHashURLButtonClicked(_ sender: Any) {
        let url = URL(string: String(format: "%@%@", EthereumManager.txAddress, alarm.txHash))
        UIApplication.shared.open(url!)
    }
    
    @IBAction func ipfsSaveButtonClicked(_ sender: Any) {
        ipfsLoadingView.startAnimating()
        
        if !alarm.saved {
            IPFSManager.sharedInstance.saveAlarmImage(alarm)
        } else {
            alarm.saved = false
            IPFSManager.sharedInstance.updateAlarms()
        }
    }
    
    @objc func ipfsImageSaved() {
        IPFSManager.sharedInstance.saveAlarmMetadata(alarm)
    }
    
    @objc func ipfsMetadataSaved() {
        alarm.saved = true
        IPFSManager.sharedInstance.updateAlarms()
    }
    
    @objc func ipfsAlarmsUpdated() {
        alarm.txHash = EthereumManager.sharedInstance.addHash(hash: AlarmManager.sharedInstance.alarmsHash)
        DispatchQueue.main.async {
            self.updateUI()
            
            self.ipfsLoadingView.stopAnimating()
        }
    }
}
