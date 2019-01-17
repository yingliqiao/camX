## Welcome to cam X

[cam X](https://onvif-spotlight.bemyapp.com/#/projects/5b059d5d1b428b000497e09d) is an iOS project written in Swift that I built for [ONVIF Open Source Spotlight Challenge](https://onvif-challenge.bemyapp.com/)

It's a proof of concept project to demonstrate how Deep Learning, IPFS and Blockchain can be applied together in practice. 

cam X uses FFmpeg library to decode and stream live video from cameras use ONVIF protocol, HTTP, RTSP or iOS device build-in cameras. It equips with Tiny Yolo and Yolo 2 deep learning object detection models as video analytics engine on camera. Users are given options to pick any object class to detect or raise alarm. Users manually pick alarm to save to IPFS. iOS device UUID used as key to store alarm hash to Ethereum Rinkeby Test Network via a simple lookup smart contract.

I posted an article on Medium to explain the project in details [Deep Learning + IPFS + Ethereum Blockchain in practice](https://medium.com/coinmonks/deep-learning-ipfs-ethereum-blockchain-in-practice-7ef6665330dd)

## Installation

1. Run [FFmpeg-iOS-build-script](https://github.com/kewlbear/FFmpeg-iOS-build-script) to build FFmpeg library for iOS

2. Run 'pod update' in root directory to install [ONVIFCamera](https://github.com/rvi/ONVIFCamera) library and [web3swift](https://github.com/BANKEX/web3swift) library.

3. Install Carthage and run 'carthage update --platform iOS' to install [swift-ipfs-api](https://github.com/ipfs/swift-ipfs-api)

4. Run download.sh shell script to download pre-trained CoreML models: Tiny Yolo and Yolo 2.

5. Then you can build the project in Xcode. You need minimum iOS 11.0 to run the app.

## User Guide

See [cam X](https://onvif-spotlight.bemyapp.com/#/projects/5b059d5d1b428b000497e09d) page for detailed slides and screenshots.
Alternatively, I made demo videos on [network cameras](https://youtu.be/DV081JC3cjY) and [iPad Pro backward facing camera](https://youtu.be/I_9fAaTosmg)

## Screenshots
![Video](https://res.cloudinary.com/ideation/image/upload/w_1920,h_1124,dpr_1/z1xrhdjenoyht5locyf8.png)
![Alarm](https://res.cloudinary.com/ideation/image/upload/w_1920,h_1124,dpr_1/nus9pusqao4fvusfmuvu.png)
![IPFS](https://res.cloudinary.com/ideation/image/upload/w_1920,h_1124,dpr_1/wfrm11ysdyyxbd8tjgn9.png)
![Transaction](https://res.cloudinary.com/ideation/image/upload/w_1920,h_1124,dpr_1/v2nueabfkkauwa7rj0xp.png)
