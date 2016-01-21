//
//  ViewController.swift
//  AllHelper
//
//  Created by Tengfei on 16/1/17.
//  Copyright © 2016年 tengfei. All rights reserved.
//

import UIKit
import Alamofire

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
//        Alamofire.request(.GET, "https://httpbin.org/get")
        Alamofire.request(.GET, "http://japi.juhe.cn/joke/content/list.from?key=79cd72cadcdc3a2739cbb84d1364dd6d&page=2&pagesize=10&sort=asc&time=1418745237", parameters: ["foo": "bar"])
            .responseJSON { response in
                print(response.request)  // original URL request
                print(response.response) // URL response
                print(response.data)     // server data
                print(response.result)   // result of response serialization
                
                if let JSON = response.result.value {
                    print("JSON: \(JSON)")
                }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

