//
//  Compressors.swift
//  
//
//  Created by Sebastian Toivonen on 8.8.2021.
//
//  Copyright © 2021 Sebastian Toivonen. All rights reserved.

/// A float compressor to reduce the number of bits used to encode floating point values
public struct FloatCompressor {
    public let minValue: Float
    public let maxValue: Float
    public let bits: Int
    public let maxBitValue: Double

    /// Initialize a new float compressor.
    ///
    /// - Parameter minValue: The minimum value that the floats are assumed to have.
    /// - Parameter maxValue: The maximum value the the floats are assumed to have.
    /// - Parameter bits: The number of bits used to encode the floats.
    public init(minValue: Float, maxValue: Float, bits: Int) {
        self.minValue = minValue
        self.maxValue = maxValue
        self.bits = bits
        self.maxBitValue = Double(UInt64(1) << bits) - 1 // pow(2.0, bits) - 1 // for 8 bits, highest value is 255, not 256
    }

    /// Write a compressed float into a stream.
    ///
    /// - Parameter value: The float to be compressed and written.
    /// - Parameter to: The stream that the float is written to.
    @inlinable
    public func write(_ value: Float, to stream: inout WritableBitStream) {
        let ratio = Double((value - minValue) / (maxValue - minValue))
        let clampedRatio = max(0.0, min(1.0, ratio))
        let bitPattern = UInt32(clampedRatio * maxBitValue)
        stream.append(bitPattern, numberOfBits: bits)
    }

    /// Write an array of compressed integers into a stream.
    ///
    /// - Parameter value: The integer to be compressed and written.
    /// - Parameter to: The stream that the integer is written to.
    @inlinable
    public func write(_ value: [Float], maxCount: Int, to bitStream: inout WritableBitStream) {
        let bits = UInt64.bitWidth - maxCount.leadingZeroBitCount
        bitStream.append(UInt32(value.count), numberOfBits: bits)
        for element in value {
            write(element, to: &bitStream)
        }
    }
    
    /// Read and decompress a float value from a stream.
    ///
    /// - Parameter from: The stream that the value is read from.
    ///
    /// - Returns: The decompressed float value.
    @inlinable
    public func read(from stream: inout ReadableBitStream) throws -> Float {
        let bitPattern = try stream.read(numberOfBits: bits) as UInt32

        let ratio = Float(Double(bitPattern) / maxBitValue)
        return  ratio * (maxValue - minValue) + minValue
    }
    
    /// Read and decompress an array of integer values from a stream.
    ///
    /// - Parameter from: The stream that the value is read from.
    ///
    /// - Returns: The decompressed integer value.
    @inlinable
    public func read(maxCount: Int, from bitStream: inout ReadableBitStream) throws -> [Float] {
        let bits = UInt64.bitWidth - maxCount.leadingZeroBitCount
        let count = try Int(bitStream.read(numberOfBits: bits) as UInt32)
        var result: [Float] = []
        if count == 0 { return result }
        for _ in 0..<count {
            try result.append(read(from: &bitStream))
        }
        return result
    }
}

/// A double compressor to reduce the number of bits used to encode double floating point values
public struct DoubleCompressor {
    public let minValue: Double
    public let maxValue: Double
    public let bits: Int
    public let maxBitValue: Double

    /// Initialize a new double compressor.
    ///
    /// - Parameter minValue: The minimum value that the doubles are assumed to have.
    /// - Parameter maxValue: The maximum value the the doubles are assumed to have.
    /// - Parameter bits: The number of bits used to encode the doubles.
    public init(minValue: Double, maxValue: Double, bits: Int) {
        self.minValue = minValue
        self.maxValue = maxValue
        self.bits = bits
        self.maxBitValue = Double(UInt64(1) << bits) - 1 // pow(2.0, bits) - 1 // for 8 bits, highest value is 255, not 256
    }
    
    /// Write a compressed double into a stream.
    ///
    /// - Parameter value: The double to be compressed and written.
    /// - Parameter to: The stream that the double is written to.
    @inlinable
    public func write(_ value: Double, to stream: inout WritableBitStream) {
        let ratio = (value - minValue) / (maxValue - minValue)
        let clampedRatio = max(0.0, min(1.0, ratio))
        let bitPattern = UInt64(clampedRatio * maxBitValue)
        stream.append(bitPattern, numberOfBits: bits)
    }
    
    /// Write an array of compressed integers into a stream.
    ///
    /// - Parameter value: The integer to be compressed and written.
    /// - Parameter to: The stream that the integer is written to.
    @inlinable
    public func write(_ value: [Double], maxCount: Int, to bitStream: inout WritableBitStream) {
        let bits = UInt64.bitWidth - maxCount.leadingZeroBitCount
        bitStream.append(UInt32(value.count), numberOfBits: bits)
        for element in value {
            write(element, to: &bitStream)
        }
    }
    
    /// Read and decompress a double value from a stream.
    ///
    /// - Parameter from: The stream that the value is read from.
    ///
    /// - Returns: The decompressed double value.
    @inlinable
    public func read(from stream: inout ReadableBitStream) throws -> Double {
        let bitPattern = try stream.read(numberOfBits: bits) as UInt64

        let ratio = Double(bitPattern) / maxBitValue
        return  ratio * (maxValue - minValue) + minValue
    }
    
    /// Read and decompress an array of integer values from a stream.
    ///
    /// - Parameter from: The stream that the value is read from.
    ///
    /// - Returns: The decompressed integer value.
    @inlinable
    public func read(maxCount: Int, from bitStream: inout ReadableBitStream) throws -> [Double] {
        let bits = UInt64.bitWidth - maxCount.leadingZeroBitCount
        let count = try Int(bitStream.read(numberOfBits: bits) as UInt32)
        var result: [Double] = []
        if count == 0 { return result }
        for _ in 0..<count {
            try result.append(read(from: &bitStream))
        }
        return result
    }
}

/// An integer compressor to reduce the number of bits used to encode signed integer.
public struct IntCompressor {
    /// The minimum value that the compressed integers are assumed to have.
    public let minValue: Int
    
    /// The maximum value that the compressed integers are assumed to have.
    public let maxValue: Int

    @usableFromInline
    internal let absoluteMinValue: UInt
    
    /// The number of bits used to encode the compressed integer values.
    /// This is calculated based on the minimum and maximum values.
    public let bits: Int
    
    /// Initialize a new integer compressor.
    /// - Parameter minValue: The minimum value that the compressed integers are assumed to have.
    /// - Parameter maxValue: The maximum value that the compressed integers are assumed to have.
    public init(minValue: Int, maxValue: Int) {
        assert(minValue < maxValue)
        self.minValue = minValue
        self.maxValue = maxValue
        
        self.absoluteMinValue = minValue.magnitude
        
        let absoluteMaxValue = maxValue <= 0 ? minValue.magnitude - maxValue.magnitude : minValue.magnitude + maxValue.magnitude
        self.bits = UInt.bitWidth - absoluteMaxValue.leadingZeroBitCount
    }
    
    /// Write a compressed integer into a stream.
    ///
    /// - Parameter value: The integer to be compressed and written.
    /// - Parameter to: The stream that the integer is written to.
    @inlinable
    public func write<T>(_ value: T, to bitStream: inout WritableBitStream) where T: FixedWidthInteger & SignedInteger {
        assert(value >= minValue)
        assert(value <= maxValue)
        let (partialValue, overflow) = Int(value).subtractingReportingOverflow(minValue)
        let storedValue: UInt
        if overflow {
            storedValue = Int.max.magnitude + Int.min.distance(to: partialValue).magnitude
        } else {
            storedValue = UInt(partialValue)
        }
        bitStream.append(storedValue, numberOfBits: bits)
    }
    
    /// Write an array of compressed integers into a stream.
    ///
    /// - Parameter value: The integer to be compressed and written.
    /// - Parameter to: The stream that the integer is written to.
    @inlinable
    public func write<T>(_ value: [T], maxCount: Int, to bitStream: inout WritableBitStream) where T: FixedWidthInteger & SignedInteger {
        let bits = UInt64.bitWidth - maxCount.leadingZeroBitCount
        bitStream.append(UInt32(value.count), numberOfBits: bits)
        for element in value {
            write(element, to: &bitStream)
        }
    }
    
    /// Read and decompress an integer value from a stream.
    ///
    /// - Parameter from: The stream that the value is read from.
    ///
    /// - Returns: The decompressed integer value.
    @inlinable
    public func read<T>(from bitStream: inout ReadableBitStream) throws -> T where T: FixedWidthInteger & SignedInteger {
        let storedValue: UInt = try bitStream.read(numberOfBits: bits)
        if storedValue <= Int.max.magnitude {
            return T(Int(storedValue) + minValue)
        } else {
            return T(Int(storedValue - absoluteMinValue) + 1)
        }
    }
    
    /// Read and decompress an array of integer values from a stream.
    ///
    /// - Parameter from: The stream that the value is read from.
    ///
    /// - Returns: The decompressed integer value.
    @inlinable
    public func read<T>(maxCount: Int, from bitStream: inout ReadableBitStream) throws -> [T] where T: FixedWidthInteger & SignedInteger {
        let bits = UInt64.bitWidth - maxCount.leadingZeroBitCount
        let count = try Int(bitStream.read(numberOfBits: bits) as UInt32)
        var result: [T] = []
        if count == 0 { return result }
        for _ in 0..<count {
            try result.append(read(from: &bitStream))
        }
        return result
    }
}

/// An integer compressor to reduce the number of bits used to encode signed integer.
public struct UIntCompressor {
    /// The minimum value that the compressed integers are assumed to have.
    public let minValue: UInt
    
    /// The maximum value that the compressed integers are assumed to have.
    public let maxValue: UInt

    @usableFromInline
    internal let shiftedMaxValue: UInt
    
    /// The number of bits used to encode the compressed integer values.
    /// This is calculated based on the minimum and maximum values.
    public let bits: Int
    
    /// Initialize a new integer compressor.
    /// - Parameter minValue: The minimum value that the compressed integers are assumed to have.
    /// - Parameter maxValue: The maximum value that the compressed integers are assumed to have.
    public init(minValue: UInt, maxValue: UInt) {
        assert(minValue < maxValue)
        self.minValue = minValue
        self.maxValue = maxValue
        let shiftedMaxValue = maxValue - minValue
        self.shiftedMaxValue = shiftedMaxValue
        self.bits = UInt.bitWidth - shiftedMaxValue.leadingZeroBitCount
    }
    
    /// Write a compressed integer into a stream.
    ///
    /// - Parameter value: The integer to be compressed and written.
    /// - Parameter to: The stream that the integer is written to.
    @inlinable
    public func write<T>(_ value: T, to bitStream: inout WritableBitStream) where T: UnsignedInteger {
        assert(value >= minValue)
        assert(value <= maxValue)
        let storedValue = value - T(minValue)
        bitStream.append(storedValue, numberOfBits: bits)
    }
    
    /// Write a compressed integer into a stream.
    ///
    /// - Parameter value: The integer to be compressed and written.
    /// - Parameter to: The stream that the integer is written to.
    @inlinable
    public func write<T>(_ value: [T], maxCount: Int, to bitStream: inout WritableBitStream) where T: UnsignedInteger {
        let bits = UInt64.bitWidth - maxCount.leadingZeroBitCount
        bitStream.append(UInt32(value.count), numberOfBits: bits)
        for element in value {
            write(element, to: &bitStream)
        }
    }
    
    /// Read and decompress an integer value from a stream.
    ///
    /// - Parameter from: The stream that the value is read from.
    ///
    /// - Returns: The decompressed integer value.
    @inlinable
    public func read<T>(from bitStream: inout ReadableBitStream) throws -> T where T: UnsignedInteger {
        let storedValue: UInt = try bitStream.read(numberOfBits: bits)
        return T(storedValue + minValue)
    }
    
    /// Read and decompress an array of integer values from a stream.
    ///
    /// - Parameter from: The stream that the value is read from.
    ///
    /// - Returns: The decompressed integer value.
    @inlinable
    public func read<T>(maxCount: Int, from bitStream: inout ReadableBitStream) throws -> [T] where T: UnsignedInteger {
        let bits = UInt64.bitWidth - maxCount.leadingZeroBitCount
        let count = try Int(bitStream.read(numberOfBits: bits) as UInt32)
        var result: [T] = []
        if count == 0 { return result }
        for _ in 0..<count {
            try result.append(read(from: &bitStream))
        }
        return result
    }
}

public extension FloatCompressor {
    /// Write a  SIMD2-vector to a stream.
    @inlinable
    func write(_ value: SIMD2<Float>, to stream: inout WritableBitStream) {
        write(value.x, to: &stream)
        write(value.y, to: &stream)
    }
    
    /// Write a SIMD3-vector to a stream.
    @inlinable
    func write(_ value: SIMD3<Float>, to stream: inout WritableBitStream) {
        write(value.x, to: &stream)
        write(value.y, to: &stream)
        write(value.z, to: &stream)
    }
    
    /// Read a SIMD2-vector from the stream.
    @inlinable
    func read(from stream: inout ReadableBitStream) throws -> SIMD2<Float> {
        return SIMD2<Float>(x: try read(from: &stream), y: try read(from: &stream))
    }
    
    /// Read a SIMD3-vector from the stream.
    @inlinable
    func read(from stream: inout ReadableBitStream) throws -> SIMD3<Float> {
        return SIMD3<Float>(
            x: try read(from: &stream),
            y: try read(from: &stream),
            z: try read(from: &stream))
    }
}

public extension DoubleCompressor {
    /// Write a  SIMD2-vector to a stream.
    @inlinable
    func write(_ value: SIMD2<Double>, to stream: inout WritableBitStream) {
        write(value.x, to: &stream)
        write(value.y, to: &stream)
    }
    
    /// Write a SIMD3-vector to a stream.
    @inlinable
    func write(_ value: SIMD3<Double>, to stream: inout WritableBitStream) {
        write(value.x, to: &stream)
        write(value.y, to: &stream)
        write(value.z, to: &stream)
    }
    
    /// Read a SIMD2-vector from the stream.
    @inlinable
    func read(from stream: inout ReadableBitStream) throws -> SIMD2<Double> {
        return SIMD2<Double>(x: try read(from: &stream), y: try read(from: &stream))
    }
    
    /// Read a SIMD3-vector from the stream.
    @inlinable
    func read(from stream: inout ReadableBitStream) throws -> SIMD3<Double> {
        return SIMD3<Double>(
            x: try read(from: &stream),
            y: try read(from: &stream),
            z: try read(from: &stream))
    }
}
