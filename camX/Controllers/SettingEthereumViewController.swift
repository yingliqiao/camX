//
//  SettingEthereumViewController.swift
//  camX
//
//  Created by Mobile Developer on 2018-05-30.
//  Copyright © 2018 Mobile Developer. All rights reserved.
//

import UIKit

class SettingEthereumViewController: UIViewController {

    @IBOutlet weak var loadingView: UIActivityIndicatorView!
    @IBOutlet weak var walletAddressLabel: UILabel!
    @IBOutlet weak var walletURLButton: UIButton!
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var gasPriceLabel: UILabel!
    @IBOutlet weak var smartContractLabel: UILabel!
    @IBOutlet weak var smartContractURLButton: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadingView.startAnimating()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        walletAddressLabel.text = String(format:"Wallet: %@", EthereumManager.walletAddress)
        balanceLabel.text = String(format:"Balance: %@", EthereumManager.sharedInstance.getWalletBalance())
        gasPriceLabel.text = String(format:"Gas Price: %@", EthereumManager.sharedInstance.getGasPrice())
        smartContractLabel.text = String(format: "Contract: %@", EthereumManager.smartContractAddress)
        
        loadingView.stopAnimating()
    }
    
    @IBAction func walletURLClicked(_ sender: Any) {
        let url = URL(string: EthereumManager.walletURL)
        UIApplication.shared.open(url!)
    }
    
    @IBAction func contractURLClicked(_ sender: Any) {
        let url = URL(string: EthereumManager.smartContractURL)
        UIApplication.shared.open(url!)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
