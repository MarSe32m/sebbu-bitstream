//
//  BitStream + Foundation.swift
//  
//
//  Created by Sebastian Toivonen on 8.8.2021.
//
//  Copyright © 2021 Sebastian Toivonen. All rights reserved.

import Foundation
import SebbuBitStream

public extension WritableBitStream {
    @inlinable
    mutating func append(_ value: Data) {
        appendBytes([UInt8](value))
    }
    
    @inline(__always)
    mutating func append(_ value: UUID) {
        value.encode(to: &self)
    }
    
    @inlinable
    @inline(__always)
    mutating func append(_ value: CGFloat) {
        append(Double(value))
    }
}

public extension ReadableBitStream {
    @inline(__always)
    mutating func read() throws(BitStreamError) -> UUID {
        return try UUID(from: &self)
    }
    
    @inlinable
    mutating func read() throws(BitStreamError) -> CGFloat {
        return CGFloat(try read() as Double)
    }
}

extension UUID: BitStreamCodable {
    public init(from bitStream: inout ReadableBitStream) throws(BitStreamError) {
        let uuid: uuid_t = (
            try bitStream.read(),
            try bitStream.read(),
            try bitStream.read(),
            try bitStream.read(),
            try bitStream.read(),
            try bitStream.read(),
            try bitStream.read(),
            try bitStream.read(),
            try bitStream.read(),
            try bitStream.read(),
            try bitStream.read(),
            try bitStream.read(),
            try bitStream.read(),
            try bitStream.read(),
            try bitStream.read(),
            try bitStream.read()
        )
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
    func read(from bitStream: inout ReadableBitStream) throws(BitStreamError) -> CGFloat {
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
    func read(from bitStream: inout ReadableBitStream) throws(BitStreamError) -> CGPoint {
        try CGPoint(x: read(from: &bitStream) as CGFloat, y: read(from: &bitStream) as CGFloat)
    }
    
    @inlinable
    func read(from bitStream: inout ReadableBitStream) throws(BitStreamError) -> CGVector {
        try CGVector(dx: read(from: &bitStream) as CGFloat, dy: read(from: &bitStream) as CGFloat)
    }
}
#endif
