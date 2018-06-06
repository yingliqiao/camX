//
//  EthereumManager.swift
//  camX
//
//  Created by Liqiao Ying on 2018-05-28.
//  Copyright © 2018 Liqiao Ying. All rights reserved.
//

import Foundation
import web3swift
import BigInt

class EthereumManager {
    
    // Rinkeby Test Network - access token
    static let accessToken = "IRNEugwWM31ONeCfB8lD"
    
    // Rinkeby Test Network - web address
    static let rinkebyAddress = "https://rinkeby.etherscan.io/address/"
    
    // Rinkeby Test Network - transaction receipt address
    static let txAddress = "https://rinkeby.etherscan.io/tx/"
    
    // Rinkeby Test Network - wallet address
    static let walletAddress = "0x31c2562b566d5199cbb7e00b14f64bcda5fe2e92"
    
    // Rinkeby Test Network - wallet web address
    static let walletURL = String(format:"%@%@", rinkebyAddress, walletAddress)
    
    // Rinkeby Test Network - private key
    static let rinkebyPrivateKey = "C6fa1296ae69f88627d8b3e02dab56a90332b0911dc5a654df0a61b552be265b"
    
    // Rinkeby Test Network - password
    static let rinkebyPassword = "onvif0603"
    
    // Rinkeby Test Network - smart contract address
    static let smartContractAddress = "0xC83Be6EaB676e9dA7845a08B006A8f9d3f8A534D"
    
    // Rinkeby Test Network - smart contract web address
    static let smartContractURL = String(format:"%@%@", rinkebyAddress, smartContractAddress)
    
    // Rinkeby Test Network = smart contract application binary interface
    static let ipfsContractABI = "[{\"constant\":true,\"inputs\":[{\"name\":\"key\",\"type\":\"string\"}],\"name\":\"getHash\",\"outputs\":[{\"name\":\"\",\"type\":\"string\"}],\"payable\":false,\"stateMutability\":\"view\",\"type\":\"function\"},{\"constant\":false,\"inputs\":[{\"name\":\"key\",\"type\":\"string\"},{\"name\":\"value\",\"type\":\"string\"}],\"name\":\"addHash\",\"outputs\":[],\"payable\":false,\"stateMutability\":\"nonpayable\",\"type\":\"function\"}]"
    
    let userDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    let keystoreManager: KeystoreManager
    let keystore: EthereumKeystoreV3
    
    let web3Rinkeby = Web3.InfuraRinkebyWeb3(accessToken: EthereumManager.accessToken)
    let contractAddress = EthereumAddress(EthereumManager.smartContractAddress)
    let walletAddress = EthereumAddress(EthereumManager.walletAddress)
    
    var options = Web3Options.defaultOptions()
    
    static let sharedInstance = EthereumManager()
    
    init() {
        keystoreManager = KeystoreManager.managerForPath(userDir + "/keystore")!
        keystore = keystoreManager.walletForAddress((keystoreManager.addresses![0])) as! EthereumKeystoreV3
        web3Rinkeby.addKeystoreManager(keystoreManager)
        
        options.gasLimit = BigUInt(100000)
        options.value = BigUInt(0)
        options.from = keystore.addresses?.first!
    }
    
    func getWalletBalance() -> String {
        let response = web3Rinkeby.eth.getBalance(address: walletAddress)
        switch response {
            case .failure(_):
                print("ETHEREUM - failed to get wallet balance")
                return ""
            case .success(let result):
                let balance = result
                let formattedBalance = Web3.Utils.formatToEthereumUnits(balance, toUnits: .eth, decimals: 9)
                print(String(format: "ETHEREUM - wallet balance:%@ ETH", formattedBalance!))
                return String(format: "%@ ETH", formattedBalance!)
        }
    }
    
    func getGasPrice() -> String {
        let response = web3Rinkeby.eth.getGasPrice()
        switch response {
            case .failure(_):
                print("ETHEREUM - failed to get gas price")
                return ""
            case .success(let result):
                let price = result
                let formattedPrice = Web3.Utils.formatToEthereumUnits(price, toUnits: .eth, decimals: 9)
                print(String(format: "ETHEREUM - gas price:%@ ETH", formattedPrice!))
                return String(format: "%@ ETH", formattedPrice!)
        }
    }
    
    func addHash(hash: String) -> String {
        // Key, Hash
        let parameters = [SettingManager.sharedInstance.uuID, hash] as [AnyObject]
        let intermediateSend = web3Rinkeby.contract(EthereumManager.ipfsContractABI, at: contractAddress, abiVersion: 2)!.method("addHash", parameters:parameters, options: options)!
        let response = intermediateSend.send(password: EthereumManager.rinkebyPassword)
        guard case .success(let sendResult) = response else { return "" }
        return sendResult["txhash"]!
    }
    
    func getHash() -> String {
        // Key
        let parameters = [SettingManager.sharedInstance.uuID] as [AnyObject]
        let intermediateCall = web3Rinkeby.contract(EthereumManager.ipfsContractABI, at: contractAddress, abiVersion: 2)!.method("getHash", parameters: parameters, options: options)!
        let response = intermediateCall.call(options: options)
        guard case .success(let callResult) = response else { return ""}
        return callResult["0"] as! String
    }
}
