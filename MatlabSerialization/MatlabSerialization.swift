import CoreML

//public protocol MatlabEncodable {
//    //static var keys: [String]{get}
//}

public protocol MatlabEncodableArray  {
    var columns:[[Any]]{get}
    var keys: [String]{get}
}

public class MatlabSerialization : NSObject {
    public class func data(withMatlabObject value: Any) throws -> Data {
        return try _data(withMatlabObject: value)
    }
    
    internal class func _data(withMatlabObject value: Any) throws -> Data {
        let writer = MatlabWriter()
        return try writer.serializeAny(value)
    }
}

private struct MatlabWriter {
    func encodeScalar<T>(_ value: T) -> Data {
        //return Data(bytes: &value, count: MemoryLayout.size(ofValue: value) )
        return withUnsafeBytes(of: value) { Data($0) }
    }
    
    func encodeArray<T>(_ value:[T]) -> Data  {
        return value.withUnsafeBufferPointer {Data(buffer: $0)}
    }

    func serializeArray(_ arrayAny:[Any],_ transpose:Bool = false) throws -> Data {
        var m = Data()
        var type:UInt8
        if arrayAny.count == 0 {
            m.append(encodeArray([UInt8](arrayLiteral: 33,2)))
            m.append(encodeArray([UInt32](arrayLiteral: 1,0)))
        } else if let arrayTyped = arrayAny as? [String], arrayTyped.contains(where: {$0.count>1}) {
            type = 36
            m.append(encodeScalar(type))
            m.append(try serializeString(arrayTyped.reduce("",+)))
            m.append(serializeNumericArray(arrayTyped.map{UInt32($0.count)}, transpose))
            m.append(serializeLogical(arrayTyped.map{$0.isEmpty} ))
        } else if !arrayAny.contains(where: {$0 is [Any]}) {//all scalar elements
            switch arrayAny as Any {
            case let arrayTyped as [Int32]://all scalar elements
                type = 34
                m.append(encodeScalar(type))
                m.append(serializeNumericArray(arrayTyped, transpose))
            case let arrayTyped as [Int]://all scalar elements
                type = 34
                m.append(encodeScalar(type))
                m.append(serializeNumericArray(arrayTyped, transpose))
            case let arrayTyped as [Int64]://all scalar elements
                type = 34
                m.append(encodeScalar(type))
                m.append(serializeNumericArray(arrayTyped, transpose))
            case let arrayTyped as [Float]:
                type = 34
                m.append(encodeScalar(type))
                m.append(serializeNumericArray(arrayTyped, transpose))
            case let arrayTyped as [Double]:
                type = 34
                m.append(encodeScalar(type))
                m.append(serializeNumericArray(arrayTyped, transpose))
            case let arrayTyped as [Bool]:
                type = 39
                m.append(encodeScalar(type))
                m.append(serializeLogical(arrayTyped, transpose))
            case let arrayTyped as [Dictionary<String,Any>]:
                m = try serializeArrayTyped(arrayTyped:arrayTyped,f:serializeDictionary, transpose)
            default:
                m = try serializeHeterogenousArray(array: arrayAny, transpose)
            }
        } else {
            m = try serializeHeterogenousArray(array: arrayAny, transpose)
        }
        return m
    }
    
//    func serializeDictArray(_ array:[Dictionary<String,Any>]) {
//
//    }
    
    func serializeArrayTyped<T>(arrayTyped:[T], f:(T) throws -> Data,_ transpose:Bool = false) throws -> Data {
        var m = Data()
        let size: [UInt32] = transpose ? [UInt32(arrayTyped.count),1] : [1,UInt32(arrayTyped.count)]
        m.append(encodeArray([33,2] as [UInt8]))
        m.append(encodeArray(size))
        for i in arrayTyped {
            m.append(try f(i))
        }
        return m
    }
    
    func serializeLogical(_ array:[Bool],_ transpose:Bool = false) -> Data {
        var m = Data()
        let size: [UInt32] = transpose ? [UInt32(array.count),1] : [1,UInt32(array.count)]
        m.append(encodeArray([133,2] as [UInt8]))
        m.append(encodeArray(size))
        m.append(encodeArray(array))
        return m
    }
    
    func serializeHeterogenousArray(array:[Any],_ transpose:Bool = false) throws -> Data {
        var m = Data()
        let size: [UInt32] = transpose ? [UInt32(array.count),1] : [1,UInt32(array.count)]
        m.append(encodeArray([33,2] as [UInt8]))
        m.append(encodeArray(size))
        for i in array {
            m.append(try serializeAny(i))
        }
        return m
    }
    
    func serializeScalar<T>(_ value: T) -> Data {
        var m = Data()
        guard let tag = scalarClass2Tag(value) else { return m }
        
        m.append(tag)
        m.append(encodeScalar(value))
        return m
    }
    
    func serializeAny(_ object: Any?) throws -> Data {
        var m = Data()
        switch object {
        case let str as String:
            m = try serializeString(str)
        case let num as Double:
            m = serializeScalar(num)
        case let num as Float:
            m = serializeScalar(num)
        case let num as Int8:
            m = serializeScalar(num)
        case let num as UInt8:
            m = serializeScalar(num)
        case let num as Int16:
            m = serializeScalar(num)
        case let num as UInt16:
            m = serializeScalar(num)
        case let num as Int32:
            m = serializeScalar(num)
        case let num as UInt32:
            m = serializeScalar(num)
        case is Int, is Int64:
            m = serializeScalar(object as! Int64)
        case let num as UInt64:
            m = serializeScalar(num)
        case let structs as MatlabEncodableArray:
            try m = serializeStructs(structs)
        case let array as Array<Any>:
            try m = serializeArray(array)
        case let dict as Dictionary<String, Any>:
            try m = serializeDictionary(dict)
        case is MLMultiArray:
            m = serializeMLMultiArray(object as! MLMultiArray)
        default:
            print("unsupported type")
        }
        return m
    }
    
    func serializeNumericArray<T>(_ v:[T],_ transpose:Bool = false) -> Data {
        var m = Data()
        guard let type = arrayClass2Tag(v) else {
            return m
        }
        let size: [UInt32] = transpose ? [UInt32(v.count),1] : [1,UInt32(v.count)]
        m.append(encodeArray([type,2] as [UInt8]))
        m.append(encodeArray(size))
        m.append(encodeArray(v))
        return m
    }
    
    func serializeMLMultiArray(_ mlmatrix:MLMultiArray) -> Data {
        var m:Data
        switch mlmatrix.dataType {
        case .double:
            m = encodeMultiArrayInfo(type:17, mlmatrix: mlmatrix)
            let mlmPointer = mlmatrix.dataPointer.bindMemory(to: Double.self, capacity: mlmatrix.count)
            m.append(encodeUnsafeBufferPointer(mlmPointer, count: mlmatrix.count))
        case .float32:
            m = encodeMultiArrayInfo(type:18, mlmatrix: mlmatrix)
            let mlmPointer = mlmatrix.dataPointer.bindMemory(to: Float32.self, capacity: mlmatrix.count)
            m.append(encodeUnsafeBufferPointer(mlmPointer, count: mlmatrix.count))
        case .int32:
            m = encodeMultiArrayInfo(type:23, mlmatrix: mlmatrix)
            let mlmPointer = mlmatrix.dataPointer.bindMemory(to: Int32.self, capacity: mlmatrix.count)
            m.append(encodeUnsafeBufferPointer(mlmPointer, count: mlmatrix.count))
        }
        return m
    }
    
    func encodeUnsafeBufferPointer<T>(_ value:UnsafePointer<T>, count:Int) -> Data {
        let buffer = UnsafeBufferPointer(start: value, count: count)
        return Data(buffer:buffer)
    }
    
    func encodeMultiArrayInfo(type:UInt8, mlmatrix:MLMultiArray) -> Data {
        var m = Data()
        m.append(encodeArray([UInt8](arrayLiteral: type,UInt8(mlmatrix.shape.count)) ))
        m.append(encodeArray(mlmatrix.shape.map{$0.uint32Value}.reversed()))
        return m
    }
    
//    func serializeMultiBuffer<T:MultiArrayType>(_ mlmPointer:UnsafePointer<T>) -> Data {
//        var m = Data()
//
////        m.append(encodeArray([UInt8](arrayLiteral: type,UInt8(mlmatrix.shape.count)) ))
////        m.append(encodeArray(mlmatrix.shape))
////        //let test = mlmatrix.shape.map{$0.uint32Value}
////        m.append(encodeArray(mlmatrix.shape.map{$0.uint32Value}))
////        for i in 0..<mlmatrix.count {
////            print([UInt8](encodeScalar(&mlmatrix[i].doubleValue)))
////            m.append(encodeScalar(&mlmatrix[i]))
////        }
//        return Data(buffer:mlmBuffer)
//    }
    
//    func isArrayType<T>(array:[Any?], tType:T.Type) -> Bool {
//        for value in array {
//
////            let arrayType = type(of: value)        // Array<Car>.Type
////            let arrayType2 = type(of: value)
////            //let carType = array.Element.self  // Car.Type
////            let typeStr = String(describing: arrayType)
////            let tS = T.self
////
////            if type(of:value) != tType { return false }
////            if value is T.self {
////                print("T.self")
////            }
//            if type(of:value) == T.self {
//                print("T.Type")
//            }
//            if value is T.Type {
//                print("T.Type")
//            }
//        }
//        return true
//    }
    func serializeStructs(_ structs:MatlabEncodableArray) throws -> Data {
        var m = Data()
        //var typeId:UInt8 = 128
        m.append(128 as UInt8)
        
        let keys = structs.keys
        let columns = structs.columns
        
        let keyCount = [UInt32(keys.count)]
        let keyLengths = keys.map({UInt32($0.count)})
        m.append(encodeArray(keyCount+keyLengths))
        try m.append(encodeStringArray(keys))
//        var bit:UInt8 = 0
        m.append(encodeArray([2,1,UInt32(columns[0].count)] as [UInt32]))
        m.append(encodeScalar(UInt8(0)))
        for arr in columns {
            try m.append(serializeArray(arr, false))//imitate comma separated-list
        }
        
        return m
    }
    
    func serializeDictionary(_ dictionary:[String:Any]) throws -> Data {
        var m = Data()
        //var typeId:UInt8 = 128
        m.append(128 as UInt8)
        
        let keyArray = Array(dictionary.keys)
        let keyCount = [UInt32(keyArray.count)]
        let keyLengths = keyArray.map({UInt32($0.count)})
        m.append(encodeArray(keyCount+keyLengths))
        try m.append(encodeStringArray(keyArray))
        
        let valueArray = Array(dictionary.values)
        m.append(encodeArray([2,1,1] as [UInt32]))
//        var bit:UInt8 = 1
        m.append(encodeScalar(1 as UInt8))
        try m.append(serializeArray(valueArray,true))//transpose to imitate struct2cell
        return m
    }
    
    func serializeString(_ value:String) throws -> Data {
        var m = Data()
//        let type:UInt8 = 0
        m.append(0 as UInt8)
//        var count = UInt32(value.count)
        m.append(encodeScalar(UInt32(value.count)))
        if let data = value.data(using: .ascii, allowLossyConversion: true){
            m.append(data)
        } else {
            throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.propertyListReadCorrupt.rawValue, userInfo: ["NSDebugDescription" : "Can only encode ASCII text"])
        }
        return m
    }
    
    func encodeStringArray(_ value:[String]) throws -> Data {
        var m = Data()
        for s in value {
            if let data = s.data(using: .ascii, allowLossyConversion: true) {
                m.append(data)
            } else {
                throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.propertyListReadCorrupt.rawValue, userInfo: ["NSDebugDescription" : "Can only encode ASCII text"])
            }
        }
        return m
    }
    
    func arrayClass2Tag<T>(_ value:[T]) -> UInt8? {
        var b:UInt8? = nil
        switch value as Any {
        case is [String]: b = 16
        case is [Double]: b = 17
        case is [Float]: b = 18
        case is [Int8]: b = 19
        case is [UInt8]: b = 20
        case is [Int16]: b = 21
        case is [UInt16]: b = 22
        case is [Int32]: b = 23
        case is [UInt32]: b = 24
        case is [Int],is [Int64]: b = 25
        case is [UInt64]: b = 26
        default: print("Unknown class")
        }
        return b
    }
    
    func scalarClass2Tag<T>(_ value:T) -> UInt8? {
        var b:UInt8? = nil
        switch value {
        case is String: b = 0
        case is Double: b = 1
        case is Float: b = 2
        case is Int8: b = 3
        case is UInt8: b = 4
        case is Int16: b = 5
        case is UInt16: b = 6
        case is Int32: b = 7
        case is UInt32: b = 8
        case is Int,is Int64: b = 9
        case is UInt64: b = 10
        default: print("Unknown class")
        }
        return b
    }
}
