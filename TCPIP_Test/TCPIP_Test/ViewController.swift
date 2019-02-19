//
//  ViewController.swift
//  Neural Time
//
//  Created by Steve on 5/8/18.
//  Copyright © 2018 Steve. All rights reserved.
//
import CoreML
import UIKit
import MatlabSerialization

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let dict:[String:Any] = ["A":["a":[1.0,2.0,3.0],"b":["a","b","c"]],"B":["a":1.0,"b":2.0,"c":3.0]]
        let m = try!MatlabSerialization.data(withMatlabObject: dict)

        let task = URLSession.shared.streamTask(withHostName: "172.20.10.2", port: 54000)
        task.resume()
        task.write(m, timeout:10.0) { error in
            if error != nil {
                print(error!.localizedDescription)
                task.closeWrite()
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
