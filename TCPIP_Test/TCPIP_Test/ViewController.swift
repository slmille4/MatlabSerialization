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

//    override func viewDidLoad() {
//        super.viewDidLoad()//"10.131.107.227"
//        // Do any additional setup after loading the view, typically from a nib.
//        let task = URLSession.shared.streamTask(withHostName: "127.0.0.1", port: 55000)
//        //let url = URL(string:)!
//        let str = "Hello Matlab\n"
//        task.resume()
//        //let data = NSData(base64Encoded: <#T##String#>, options: <#T##NSData.Base64DecodingOptions#>)
//        //        session.uploadTask(request, bodyData:)
//        task.write(str.data(using: .utf8)!, timeout:10.0) { error in
//            //print(error!.localizedDescription)
//            task.closeWrite()
//        }
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        var dict:[String:Any] = ["a":[[1,2,3,4],[5,6,7,8],[9,10,11,12]]]
        let dict:[String:Any] = ["A":["a":[1.0,2.0,3.0],"b":["a","b","c"]],"B":["a":1.0,"b":2.0,"c":3.0]]
//        guard let mlMultiArray = try? MLMultiArray(shape:[2,3,3], dataType:.int32) else {
//            fatalError("Unexpected runtime error. MLMultiArray")
//        }
//        let arr = [Float32](arrayLiteral:1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18)
//        for (index, element) in arr.enumerated() {
//            mlMultiArray[index] = NSNumber(value:element)
//        }
//        dict["b"] = mlMultiArray
//        let b: [String:Any] = ["A":[1,2,3,4],"B":[5,6,7,8],"C":[9,10,11,12]]

//        dict["b"] = b
        let m = try!MatlabSerialization.data(withMatlabObject: dict)

        // Do any additional setup after loading the view, typically from a nib.
        let task = URLSession.shared.streamTask(withHostName: "172.20.10.2", port: 54000)
        task.resume()
        //let data = NSData(base64Encoded: <#T##String#>, options: <#T##NSData.Base64DecodingOptions#>)
//        session.uploadTask(request, bodyData:)
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

