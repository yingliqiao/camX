//
//  AlarmCollectionViewController.swift
//  camX
//
//  Created by Liqiao Ying on 2018-05-27.
//  Copyright © 2018 Liqiao Ying. All rights reserved.
//

import UIKit

fileprivate let sectionInsets = UIEdgeInsets(top:50.0, left: 20.0, bottom: 50.0, right: 20.0)

class AlarmCollectionViewController: UICollectionViewController, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var loadingView: UIActivityIndicatorView!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    var fullscreenView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadingView.layer.zPosition = .greatestFiniteMagnitude
        
        if !AlarmManager.sharedInstance.archieveLoaded {
            loadingView.startAnimating()
            AlarmManager.sharedInstance.alarmsHash = EthereumManager.sharedInstance.getHash()
            if AlarmManager.sharedInstance.alarmsHash != "" {
                DispatchQueue.global(qos: .background).async {
                    IPFSManager.sharedInstance.retrieveAlarms()
                }
            } else {
                loadingView.stopAnimating()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ipfsAlarmMedadataRetrieved), name:.IPFSAlarmMetadataRetrieved, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ipfsAlarmImagesRetrieved), name:.IPFSAlarmImagesRetrieved, object: nil)
        
        saveButton.isEnabled = false
        self.collectionView?.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: .IPFSAlarmMetadataRetrieved, object: nil)
        NotificationCenter.default.removeObserver(self, name: .IPFSAlarmImagesRetrieved, object: nil)
        
        if loadingView.isAnimating {
            loadingView.stopAnimating()
        }
        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func ipfsAlarmMedadataRetrieved() {
        DispatchQueue.main.async {
            self.collectionView?.reloadData()
        }
    }
    @objc func ipfsAlarmImagesRetrieved() {
        DispatchQueue.main.async {
            self.collectionView?.reloadData()
            AlarmManager.sharedInstance.archieveLoaded = true
            self.loadingView.stopAnimating()
        }
    }
    
    @IBAction func imageTapped(_ sender: UITapGestureRecognizer) {
        let tappedPoint = sender.location(in: self.collectionView)
        let tappedCellPath = self.collectionView?.indexPathForItem(at: tappedPoint)
        if (tappedCellPath != nil) {
            let cell = self.collectionView?.cellForItem(at: tappedCellPath!) as! AlarmCollectionViewCell
            let imageView = cell.imageView
            fullscreenView = UIImageView(image: imageView!.image)
            fullscreenView.frame = UIScreen.main.bounds
            fullscreenView.backgroundColor = .black
            fullscreenView.contentMode = .scaleAspectFit
            self.view.addSubview(fullscreenView)
            
            let closeButton = UIButton(frame: CGRect(x:fullscreenView.frame.width - 50, y:50, width:25, height:25))
            closeButton.setImage(#imageLiteral(resourceName: "CloseIcon"), for: .normal)
            closeButton.addTarget(self, action: #selector(dismissFullscreenImage), for: .touchUpInside)
            self.view.addSubview(closeButton)
            
            self.navigationController?.isNavigationBarHidden = true
            self.tabBarController?.tabBar.isHidden = true
        }
    }
    
    @objc func dismissFullscreenImage(sender: UIButton!) {
        self.navigationController?.isNavigationBarHidden = false
        self.tabBarController?.tabBar.isHidden = false
        sender.removeFromSuperview();
        fullscreenView.removeFromSuperview()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionViewLayout.invalidateLayout()
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return AlarmManager.sharedInstance.alarms.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AlarmCell", for: indexPath) as! AlarmCollectionViewCell
        let alarm = AlarmManager.sharedInstance.alarms[indexPath.row]
        
        cell.contentView.layer.borderColor = alarm.saved ? UIColor.green.cgColor : UIColor.darkGray.cgColor
        cell.contentView.backgroundColor = cell.isSelected ? UIColor.darkGray : UIColor.black
        
        cell.cameraLabel.text = alarm.camera
        cell.objectLabel.text = String(format:"Alarm: %@", alarm.object)
        cell.modelLabel.text = String(format:"Model: %@", alarm.model)
        cell.timestampLabel.text = alarm.timestamp
        cell.imageView.image = alarm.image
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        saveButton.isEnabled = true
        
        let cell = collectionView.cellForItem(at: indexPath) as! AlarmCollectionViewCell
        cell.isSelected = true
        
        let alarm = AlarmManager.sharedInstance.alarms[indexPath.row]
        AlarmManager.sharedInstance.currentAlarm = alarm
    }
    
    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.isSelected = false
    }
    
    // MARK: UICollectionViewDelegate
    
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
}

extension AlarmCollectionViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let itemsPerRow: CGFloat = UIDevice.current.orientation == .portrait ? 2 : 4
        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow
        
        return CGSize(width: widthPerItem, height: widthPerItem)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
}
