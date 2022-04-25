//
//  ViewController.swift
//  XKLocation
//
//  Created by kenneth on 04/22/2022.
//  Copyright (c) 2022 kenneth. All rights reserved.
//

import UIKit
import XKLocation

class ViewController: UIViewController {
    
    lazy var locateHelper = XKLocation()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        locateHelper.errorCallback = {
            [weak self] error in
            print(error)
        }
        locateHelper.authorizationStatusCallback = {
            [weak self] status in
            print(status)
        }
        locateHelper.locationUpdateCallback = {
            [weak self] placemark in
            print("")
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0) {
//            self.locateHelper.start()
            XKLocation.fetchCoordinate(address: "北京市三里屯") { placemark, error in
                print("")
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

