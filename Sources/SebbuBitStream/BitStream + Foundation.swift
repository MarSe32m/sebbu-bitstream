//
//  BitStream + Foundation.swift
//  
//
//  Created by Sebastian Toivonen on 8.8.2021.
//
//  Copyright © 2021 Sebastian Toivonen. All rights reserved.

#if canImport(Foundation)
import Foundation
public extension WritableBitStream {
    @inlinable
    mutating func append(_ value: Data) {
        append([UInt8](value))
    }
    
    @inline(__always)
    mutating func append(_ value: UUID) {
        value.encode(to: &self)
    }
    
    @inlinable
    @inline(__always)
    mutating func packData(withCrc: Bool = false) -> Data {
        return Data(packBytes(withCrc: withCrc))
    }
    
    @inlinable
    @inline(__always)
    mutating func append(_ value: CGFloat) {
        append(Double(value))
    }
}

public extension ReadableBitStream {
    @inlinable
    init(data: Data) {
        self.init(bytes: [UInt8](data))
    }

    @inlinable
    mutating func read() throws -> Data {
        return Data(try read() as [UInt8])
    }
    
    @inline(__always)
    mutating func read() throws -> UUID {
        return try UUID(from: &self)
    }
    
    @inlinable
    mutating func read() throws -> CGFloat {
        return CGFloat(try read() as Double)
    }
}

extension UUID: BitStreamCodable {
    public init(from bitStream: inout ReadableBitStream) throws {
        let data: [UInt8] = try (0..<16).map {_ in try bitStream.read()}
        if data.count != 16 {
            throw BitStreamError.encodingError
        }
        
        let uuid: uuid_t = (data[0], data[1], data[2], data[3],
                            data[4], data[5], data[6], data[7],
                            data[8], data[9], data[10], data[11],
                            data[12], data[13], data[14], data[15])
        self = UUID(uuid: uuid)
    }
    
    public func encode(to bitStream: inout WritableBitStream) {
        bitStream.append(uuid.0)
        bitStream.append(uuid.1)
        bitStream.append(uuid.2)
        bitStream.append(uuid.3)
        bitStream.append(uuid.4)
        bitStream.append(uuid.5)
        bitStream.append(uuid.6)
        bitStream.append(uuid.7)
        bitStream.append(uuid.8)
        bitStream.append(uuid.9)
        bitStream.append(uuid.10)
        bitStream.append(uuid.11)
        bitStream.append(uuid.12)
        bitStream.append(uuid.13)
        bitStream.append(uuid.14)
        bitStream.append(uuid.15)
    }
}

public extension DoubleCompressor {
    @inlinable
    func write(_ value: CGFloat, to bitStream: inout WritableBitStream) {
        write(Double(value), to: &bitStream)
    }
    
    @inlinable
    func read(from bitStream: inout ReadableBitStream) throws -> CGFloat {
        try CGFloat(read(from: &bitStream) as Double)
    }
}

#if canImport(CoreGraphics)
import CoreGraphics

public extension DoubleCompressor {
    @inlinable
    func write(_ value: CGPoint, to bitStream: inout WritableBitStream) {
        write(value.x, to: &bitStream)
        write(value.y, to: &bitStream)
    }
    
    @inlinable
    func write(_ value: CGVector, to bitStream: inout WritableBitStream) {
        write(value.dx, to: &bitStream)
        write(value.dy, to: &bitStream)
    }
    
    @inlinable
    func read(from bitStream: inout ReadableBitStream) throws -> CGPoint {
        try CGPoint(x: read(from: &bitStream) as CGFloat, y: read(from: &bitStream) as CGFloat)
    }
    
    @inlinable
    func read(from bitStream: inout ReadableBitStream) throws -> CGVector {
        try CGVector(dx: read(from: &bitStream) as CGFloat, dy: read(from: &bitStream) as CGFloat)
    }
}
#endif

#endif
