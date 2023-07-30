//
//  DataTypes.swift
//  
//
//  Created by Sebastian Toivonen on 8.8.2021.
//
//  Copyright © 2021 Sebastian Toivonen. All rights reserved.

//TODO: Add a #BitStreamCodable macros that gives automatic conformance to BitStreamCodable and implements the init and encode methods automatically
//TODO: Documents these property wrappers
@propertyWrapper
public struct BitUnsigned<T: UnsignedInteger & FixedWidthInteger> {
    public var wrappedValue: T = 0
    public let bits: Int
    
    public init(bits: Int) {
        self.bits = bits
    }
    
    public init(maxValue: T) {
        bits = maxValue.bitWidth - maxValue.leadingZeroBitCount
    }
}

@propertyWrapper
public struct BitSigned {
    public var wrappedValue: Int = 0
    public let min: Int
    public let max: Int
    
    public init(min: Int, max: Int) {
        self.min = min
        self.max = max
    }
}

@propertyWrapper
public struct BitFloat {
    public var wrappedValue: Float = 0
    public let minValue: Float
    public let maxValue: Float
    public let bits: Int
    
    public init(min: Float, max: Float, bits: Int) {
        self.minValue = min
        self.maxValue = max
        self.bits = bits
    }
}

@propertyWrapper
public struct BitDouble {
    public var wrappedValue: Double = 0
    public let minValue: Double
    public let maxValue: Double
    public let bits: Int
    
    public init(min: Double, max: Double, bits: Int) {
        self.minValue = min
        self.maxValue = max
        self.bits = bits
    }
}

@propertyWrapper
//TODO: Convert to macro #BitArray(maxCount: UInt, valueBits: Int)
public struct BitArray<Value> where Value: UnsignedInteger {
    public var wrappedValue: Array<Value> = []
    public let countBits: Int
    public let valueBits: Int
    
    public init(maxCount: UInt, valueBits: Int) {
        self.countBits = UInt64.bitWidth - maxCount.leadingZeroBitCount
        self.valueBits = valueBits
    }
}

@propertyWrapper
//TODO: Convert to macro #BoundedArray(maxCount: UInt)
public struct _BoundedArray<Value> where Value: BitStreamCodable {
    public var wrappedValue: Array<Value> = []
    public let bits: Int
    
    public init(maxCount: UInt) {
        bits = UInt64.bitWidth - maxCount.leadingZeroBitCount
    }
}

public extension WritableBitStream {
    /// BitFloat encoding
    @inlinable
    mutating func append(_ value: BitFloat) {
        let floatCompressor = FloatCompressor(minValue: value.minValue, maxValue: value.maxValue, bits: value.bits)
        floatCompressor.write(value.wrappedValue, to: &self)
    }
    
    /// BitDouble encoding
    @inlinable
    mutating func append(_ value: BitDouble) {
        let doubleCompressor = DoubleCompressor(minValue: value.minValue, maxValue: value.maxValue, bits: value.bits)
        doubleCompressor.write(value.wrappedValue, to: &self)
    }
    
    /// BitUnsigned encoding
    @inlinable
    @_specialize(exported: true, kind: full, where T == UInt8)
    @_specialize(exported: true, kind: full, where T == UInt16)
    @_specialize(exported: true, kind: full, where T == UInt32)
    @_specialize(exported: true, kind: full, where T == UInt64)
    @_specialize(exported: true, kind: full, where T == UInt)
    mutating func append<T>(_ value: BitUnsigned<T>) where T: UnsignedInteger {
        append(value.wrappedValue, numberOfBits: value.bits)
    }
    
    /// BitSigned encoding
    @inlinable
    mutating func append(_ value: BitSigned) {
        let intCompressor = IntCompressor(minValue: value.min, maxValue: value.max)
        intCompressor.write(value.wrappedValue, to: &self)
    }
    
    /// BitArray encoding
    @inlinable
    @_specialize(exported: true, kind: full, where T == UInt8)
    @_specialize(exported: true, kind: full, where T == UInt16)
    @_specialize(exported: true, kind: full, where T == UInt32)
    @_specialize(exported: true, kind: full, where T == UInt64)
    @_specialize(exported: true, kind: full, where T == UInt)
    mutating func append<T>(_ value: BitArray<T>) where T: UnsignedInteger {
        append(UInt32(value.wrappedValue.count), numberOfBits: value.countBits)
        for element in value.wrappedValue {
            append(element, numberOfBits: value.valueBits)
        }
    }
    
    /// BoundedArray encoding
    @inlinable
    static func << <T>(bitStream: inout WritableBitStream, value: _BoundedArray<T>) where T: BitStreamCodable {
        bitStream.append(value)
    }
    
    @inlinable
    mutating func append<T>(_ value: _BoundedArray<T>) where T: BitStreamCodable {
        append(value.wrappedValue, numberOfCountBits: value.bits)
    }
}

public extension ReadableBitStream {
    /// BitFloat decoding
    @inlinable
    mutating func read(_ value: inout BitFloat) throws {
        let floatCompressor = FloatCompressor(minValue: value.minValue, maxValue: value.maxValue, bits: value.bits)
        value.wrappedValue = try floatCompressor.read(from: &self)
    }
    
    /// BitDouble decoding
    @inlinable
    mutating func read(_ value: inout BitDouble) throws {
        let doubleCompressor = DoubleCompressor(minValue: value.minValue, maxValue: value.maxValue, bits: value.bits)
        value.wrappedValue = try doubleCompressor.read(from: &self)
    }
    
    /// BitUnsigned decoding
    @inlinable
    @_specialize(exported: true, kind: full, where T == UInt8)
    @_specialize(exported: true, kind: full, where T == UInt16)
    @_specialize(exported: true, kind: full, where T == UInt32)
    @_specialize(exported: true, kind: full, where T == UInt64)
    @_specialize(exported: true, kind: full, where T == UInt)
    mutating func read<T>(_ value: inout BitUnsigned<T>) throws where T: UnsignedInteger {
        value.wrappedValue = try self.read(numberOfBits: value.bits)
    }
    
    /// BitSigned decoding
    @inlinable
    mutating func read(_ value: inout BitSigned) throws {
        let intCompressor = IntCompressor(minValue: value.min, maxValue: value.max)
        value.wrappedValue = try intCompressor.read(from: &self)
    }
    
    /// Array with chosen bit value for count decoding
    @inlinable
    @_specialize(exported: true, kind: full, where T == UInt8)
    @_specialize(exported: true, kind: full, where T == UInt16)
    @_specialize(exported: true, kind: full, where T == UInt32)
    @_specialize(exported: true, kind: full, where T == UInt64)
    @_specialize(exported: true, kind: full, where T == UInt)
    mutating func read<T>(_ value: inout BitArray<T>) throws where T: UnsignedInteger {
        let count = Int(try self.read(numberOfBits: value.countBits) as UInt32)
        value.wrappedValue.removeAll(keepingCapacity: true)
        value.wrappedValue.reserveCapacity(count)
        for _ in 0..<count {
            value.wrappedValue.append(try self.read(numberOfBits: value.valueBits))
        }
    }
    
    /// Array with chosen bit value for count count decoding, generic
    @inlinable
    @inline(__always)
    mutating func read<T>(_ value: inout _BoundedArray<T>) throws where T: BitStreamCodable {
        value.wrappedValue = try read(numberOfCountBits: value.bits)
    }
}

