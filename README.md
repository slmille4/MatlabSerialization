# MatlabSerialization
A serialization class for sending data from Swift to MATLAB. MatlabSerialization is based on, is compatible with, and requires Christian Kothe’s [Fast serialize / deserialize class]( https://www.mathworks.com/matlabcentral/fileexchange/34564-fast-serialize-deserialize?focused=5215237&tab=function
)

MatlabSerialization transforms Swift Foundation objects into a byte array for rapid data transfer into MATLAB via a tcp/ip socket. CoreML data type MLMultiArray is used to store matices. IMPORTANT: Swift is row-major while MATLAB is column-major so matrices will be transposed when imported.

## Basic translations:
- MLMultiArray -> Matrix
- Dictionary<String:Any> -> 1x1 Struct
- MatlabEncodableArray protocol -> 1xN Struct
- Array<Any> -> 1xN Cell Array

## Limitations:
Only 2D cell/struct arrays (no limitation for matrics)
No complex numbers

Functionality will be added according to interest. Email suggestions to slmille4 at gmail dot com or submit a merge request.

## Basic usage:
```Swift
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
```
