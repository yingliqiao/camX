//
//  AlarmCollectionViewCell.swift
//  camX
//
//  Created by Liqiao Ying on 2018-05-27.
//  Copyright © 2018 Liqiao Ying. All rights reserved.
//

import UIKit

class AlarmCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var timestampLabel: UILabel!
    @IBOutlet weak var cameraLabel: UILabel!
    @IBOutlet weak var objectLabel: UILabel!
    @IBOutlet weak var modelLabel: UILabel!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.contentView.layer.borderWidth = 2.0
        self.contentView.layer.cornerRadius = 20.0
        self.contentView.layer.borderColor = UIColor.darkGray.cgColor
        self.contentView.layer.masksToBounds = true
    }
    
    override var isSelected: Bool {
        willSet {
            if self.isSelected {
                self.contentView.backgroundColor = UIColor.darkGray
            } else {
                self.contentView.backgroundColor = UIColor.black
            }
        }
    }
}
