//
//  SettingIPFSViewController.swift
//  camX
//
//  Created by Mobile Developer on 2018-05-30.
//  Copyright © 2018 Mobile Developer. All rights reserved.
//

import UIKit

class SettingIPFSViewController: UIViewController {

    @IBOutlet weak var ipfsGatewayLabel: UILabel!
    @IBOutlet weak var ipfsRPCLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        ipfsGatewayLabel.text = String(format:"Gateway: https://%@", IPFSManager.host)
        ipfsRPCLabel.text = String(format:"RPC: https://%@:%d", IPFSManager.host, IPFSManager.port)
    }
}
