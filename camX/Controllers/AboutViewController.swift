//
//  AboutViewController.swift
//  camX
//
//  Created by Mobile Developer on 2018-05-30.
//  Copyright © 2018 Mobile Developer. All rights reserved.
//

import UIKit

class AboutViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    @IBAction func linkedInButtonClicked(_ sender: Any) {
        let url = URL(string: Config.linkedInURL)
        UIApplication.shared.open(url!)
    }
    
    @IBAction func gmailButtonClicked(_ sender: Any) {
        let url = URL(string: String(format:"mailto:%@", Config.gmailURL))
        UIApplication.shared.open(url!)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
