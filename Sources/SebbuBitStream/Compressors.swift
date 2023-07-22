//
//  Compressors.swift
//  
//
//  Created by Sebastian Toivonen on 8.8.2021.
//
//  Copyright © 2021 Sebastian Toivonen. All rights reserved.

import Foundation

public struct FloatCompressor {
    public let minValue: Float
    public let maxValue: Float
    public let bits: Int
    public let maxBitValue: Double

    public init(minValue: Float, maxValue: Float, bits: Int) {
        self.minValue = minValue
        self.maxValue = maxValue
        self.bits = bits
        self.maxBitValue = pow(2.0, Double(bits)) - 1 // for 8 bits, highest value is 255, not 256
    }

    @inlinable
    public func write(_ value: Float, to stream: inout WritableBitStream) {
        let ratio = Double((value - minValue) / (maxValue - minValue))
        let clampedRatio = max(0.0, min(1.0, ratio))
        let bitPattern = UInt32(clampedRatio * maxBitValue)
        stream.append(bitPattern, numberOfBits: bits)
    }

    @inlinable
    public func read(from stream: inout ReadableBitStream) throws -> Float {
        let bitPattern = try stream.read(numberOfBits: bits) as UInt32

        let ratio = Float(Double(bitPattern) / maxBitValue)
        return  ratio * (maxValue - minValue) + minValue
    }
}

public struct DoubleCompressor {
    public let minValue: Double
    public let maxValue: Double
    public let bits: Int
    public let maxBitValue: Double

    public init(minValue: Double, maxValue: Double, bits: Int) {
        self.minValue = minValue
        self.maxValue = maxValue
        self.bits = bits
        self.maxBitValue = pow(2.0, Double(bits)) - 1 // for 8 bits, highest value is 255, not 256
    }

    @inlinable
    public func write(_ value: Double, to stream: inout WritableBitStream) {
        let ratio = (value - minValue) / (maxValue - minValue)
        let clampedRatio = max(0.0, min(1.0, ratio))
        let bitPattern = UInt64(clampedRatio * maxBitValue)
        stream.append(bitPattern, numberOfBits: bits)
    }

    @inlinable
    public func read(from stream: inout ReadableBitStream) throws -> Double {
        let bitPattern = try stream.read(numberOfBits: bits) as UInt64

        let ratio = Double(bitPattern) / maxBitValue
        return  ratio * (maxValue - minValue) + minValue
    }
}


//Warning: This isn't really great... Use only for relatively small integers / ranges
public struct IntCompressor {
    public let minValue: Int
    public let maxValue: Int

    @usableFromInline
    internal let absoluteMinValue: UInt
    
    public let bits: Int
    
    public init(minValue: Int, maxValue: Int) {
        assert(minValue < maxValue)
        self.minValue = minValue
        self.maxValue = maxValue
        
        self.absoluteMinValue = minValue.magnitude
        
        let absoluteMaxValue = maxValue <= 0 ? minValue.magnitude - maxValue.magnitude : minValue.magnitude + maxValue.magnitude
        self.bits = UInt.bitWidth - absoluteMaxValue.leadingZeroBitCount
    }
    
    @inlinable
    public func write(_ value: Int, to bitStream: inout WritableBitStream) {
        assert(value >= minValue)
        assert(value <= maxValue)
        let (partialValue, overflow) = value.subtractingReportingOverflow(minValue)
        let storedValue: UInt
        if overflow {
            storedValue = Int.max.magnitude + Int.min.distance(to: partialValue).magnitude
        } else {
            storedValue = UInt(partialValue)
        }
        bitStream.append(storedValue, numberOfBits: bits)
    }
    
    @inlinable
    public func read(from bitStream: inout ReadableBitStream) throws -> Int {
        let storedValue: UInt = try bitStream.read(numberOfBits: bits)
        if storedValue <= Int.max.magnitude {
            return Int(storedValue) + minValue
        } else {
            return Int(storedValue - absoluteMinValue) + 1
        }
    }
}
