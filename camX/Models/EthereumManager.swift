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
    
    func addHash(hash: String) -> String {
        // Key, Hash
        let parameters = [SettingManager.sharedInstance.uuID, hash] as [AnyObject]
        guard let intermediateSend = try? web3Rinkeby.contract(EthereumManager.ipfsContractABI, at: contractAddress).method("addHash", parameters:parameters, options: options) else { return "UNKNOWN HASH" }
        guard let response = try? intermediateSend.send(password: EthereumManager.rinkebyPassword) else { return "UNKNOWN HASH" }
        return response.hash
    }
    
    func getHash() -> String {
        // Key
        let parameters = [SettingManager.sharedInstance.uuID] as [AnyObject]
        guard let intermediateCall = try? web3Rinkeby.contract(EthereumManager.ipfsContractABI, at: contractAddress).method("getHash", parameters: parameters, options: options) else { return "UNKNOWN HASH" }
        guard let response = try? intermediateCall.call(options: options) else { return "UNKNOWN HASH" }
        return response["0"] as! String
    }
}
