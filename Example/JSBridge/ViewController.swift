//
//  ViewController.swift
//  JSBridge
//
//  Created by sugc on 2021/10/24.
//

import UIKit
import MGJSBridge

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
    }

    override func viewDidAppear(_ animated: Bool) {
        let vc = MGWebController()
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: false, completion: nil)
    }
}

