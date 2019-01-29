//
//  AudioBufferConverter.swift
//  MatlabSerialization
//
//  Created by Steve on 8/12/18.
//  Copyright © 2018 Steve. All rights reserved.
//

import CoreAudio
import CoreML

public func convertAudioBufferList(_ bufferList: UnsafeMutablePointer<AudioBufferList>, alignment: Int) -> MLMultiArray? {
    let buffers = UnsafeMutableAudioBufferListPointer(bufferList)

    let mDataByteSize = Int(buffers[0].mDataByteSize)
    let bufferSizeBytes = mDataByteSize*buffers.count
    let pointer = UnsafeMutableRawPointer.allocate(byteCount: bufferSizeBytes, alignment: alignment)
    var cursor = pointer
    
    let bufferSize = mDataByteSize / alignment
    for i in buffers {
        cursor.copyMemory(from: i.mData!, byteCount: Int(i.mDataByteSize))
        cursor = cursor.advanced(by: bufferSizeBytes)
    }
    
//    cursor.copyMemory(from: outputBuffer[1].mData!, byteCount: bufferSizeBytes)
//    cursor = cursor.advanced(by: bufferSizeBytes)
//    cursor.copyMemory(from: outputBuffer[2].mData!, byteCount: bufferSizeBytes)
//    cursor = cursor.advanced(by: bufferSizeBytes)
//    cursor.copyMemory(from: outputBuffer[3].mData!, byteCount: bufferSizeBytes)
    
    let mlm = try? MLMultiArray(dataPointer: pointer, shape: [NSNumber(value: buffers.count),NSNumber(value: bufferSize)], dataType: .float32, strides: [NSNumber(value: bufferSize),1], deallocator: { free($0) })
    
    return mlm
}
