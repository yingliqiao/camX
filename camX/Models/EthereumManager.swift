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
    static let smartContractAddress = "0x8Ed602A002D4A9dB12567F225c2c5ae6fB5551E4"
    
    // Rinkeby Test Network - smart contract web address
    static let smartContractURL = String(format:"%@%@", rinkebyAddress, smartContractAddress)
    
    // Rinkeby Test Network = smart contract application binary interface
    static let ipfsContractABI = "[{\"constant\": false,\"inputs\": [{\"name\": \"_udid\",\"type\": \"string\"},{\"name\": \"_value\",\"type\": \"string\"}],\"name\": \"saveHash\",\"outputs\": [],\"payable\": true,\"stateMutability\": \"payable\",\"type\": \"function\"},{\"constant\": false,\"inputs\": [],\"name\": \"toggleContractActive\",\"outputs\": [],\"payable\": false,\"stateMutability\": \"nonpayable\",\"type\": \"function\"},{\"constant\": false,\"inputs\": [{\"name\": \"_newOwner\",\"type\": \"address\"}],\"name\": \"transferOwner\",\"outputs\": [],\"payable\": false,\"stateMutability\": \"nonpayable\",\"type\": \"function\"},{\"constant\": false,\"inputs\": [{\"name\": \"_amount\",\"type\": \"uint256\"}],\"name\": \"withdraw\",\"outputs\": [],\"payable\": false,\"stateMutability\": \"nonpayable\",\"type\": \"function\"},{\"inputs\": [],\"payable\": false,\"stateMutability\": \"nonpayable\",\"type\": \"constructor\"},{\"payable\": false,\"stateMutability\": \"nonpayable\",\"type\": \"fallback\"},{\"anonymous\": false,\"inputs\": [{\"indexed\": false,\"name\": \"_owner\",\"type\": \"address\"},{\"indexed\": false,\"name\": \"_newOwner\",\"type\": \"address\"}],\"name\": \"LogTransferOwner\",\"type\": \"event\"},{\"anonymous\": false,\"inputs\": [{\"indexed\": false,\"name\": \"_owner\",\"type\": \"address\"},{\"indexed\": false,\"name\": \"_amount\",\"type\": \"uint256\"}],\"name\": \"LogWithdraw\",\"type\": \"event\"},{\"anonymous\": false,\"inputs\": [{\"indexed\": false,\"name\": \"_sender\",\"type\": \"address\"},{\"indexed\": false,\"name\": \"_value\",\"type\": \"string\"}],\"name\": \"LogSaveHash\",\"type\": \"event\"},{\"constant\": true,\"inputs\": [],\"name\": \"fee\",\"outputs\": [{\"name\": \"\",\"type\": \"uint256\"}],\"payable\": false,\"stateMutability\": \"view\",\"type\": \"function\"},{\"constant\": true,\"inputs\": [{\"name\": \"_udid\",\"type\": \"string\"}],\"name\": \"getHash\",\"outputs\": [{\"name\": \"_sender\",\"type\": \"address\"},{\"name\": \"_value\",\"type\": \"string\"}],\"payable\": false,\"stateMutability\": \"view\",\"type\": \"function\"},{\"constant\": true,\"inputs\": [],\"name\": \"getOwner\",\"outputs\": [{\"name\": \"_owner\",\"type\": \"address\"}],\"payable\": false,\"stateMutability\": \"view\",\"type\": \"function\"}]"
    
    let userDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    let keystoreManager: KeystoreManager
    let keystore: EthereumKeystoreV3
    
    let web3Rinkeby = Web3(infura: .rinkeby, accessToken: EthereumManager.accessToken)
    let contractAddress = Address(EthereumManager.smartContractAddress)
    let walletAddress = Address(EthereumManager.walletAddress)
    
    var options = Web3Options.default;
    
    static let sharedInstance = EthereumManager()
    
    init() {
        keystoreManager = KeystoreManager.managerForPath(userDir + "/keystore")!
        keystore = keystoreManager.walletForAddress((keystoreManager.addresses[0])) as! EthereumKeystoreV3
        web3Rinkeby.addKeystoreManager(keystoreManager)
        
        options.gasLimit = BigUInt(100000)
        options.value = BigUInt(0)
        options.from = keystore.addresses.first!
    }
    
    func getWalletBalance() -> String {
        guard let balance = try? web3Rinkeby.eth.getBalance(address: walletAddress) else { return "UNKNOWN ETH" }
        let formattedBalance = balance.string(unitDecimals: 18, decimals: 9, decimalSeparator: ",")
        print(String(format: "ETHEREUM - wallet balance:%@ ETH", formattedBalance))
        return String(format: "%@ ETH", formattedBalance)
    }
    
    func getGasPrice() -> String {
        guard let price = try? web3Rinkeby.eth.getGasPrice() else { return "UNKNOWN ETH" }
        let formattedPrice = price.string(unitDecimals: 18, decimals: 9, decimalSeparator: ",")
        print(String(format: "ETHEREUM - gas price:%@ ETH", formattedPrice))
        return String(format: "%@ ETH", formattedPrice)
    }
    
    func saveHash(hash: String) -> String {
        // Key, Hash
        options.value = BigUInt(1000000000000000);
        let parameters = [SettingManager.sharedInstance.uuID, hash] as [AnyObject]
        guard let intermediateSend = try? web3Rinkeby.contract(EthereumManager.ipfsContractABI, at: contractAddress).method("saveHash", parameters:parameters, options: options) else { return "UNKNOWN HASH" }
        guard let response = try? intermediateSend.send(password: EthereumManager.rinkebyPassword) else { return "UNKNOWN HASH" }
        return response.hash
    }
    
    func getHash() -> String {
        // Key
        let parameters = [SettingManager.sharedInstance.uuID] as [AnyObject]
        guard let intermediateCall = try? web3Rinkeby.contract(EthereumManager.ipfsContractABI, at: contractAddress).method("getHash", parameters: parameters, options: options) else { return "UNKNOWN HASH" }
        guard let response = try? intermediateCall.call(options: options) else { return "UNKNOWN HASH" }
        return response["1"] as! String
    }
}
