//
//  BitStream.swift
//
//  Created by Sebastian Toivonen on 8.8.2021.
//
//  Copyright © 2021 Sebastian Toivonen. All rights reserved.

public enum BitStreamError: Error {
    case tooShort
    case encodingError
}

/// Gets the number of bits required to encode an enum case.
public extension RawRepresentable where Self: CaseIterable, RawValue == UInt32 {
    @inlinable
    static var bits: Int {
        let casesCount = UInt32(allCases.count)
        return UInt32.bitWidth - casesCount.leadingZeroBitCount
    }
}

//MARK: WritableBitStream
public struct WritableBitStream {
    @usableFromInline
    var bytes = [UInt8]()
    
    @usableFromInline
    var endBitIndex = 0

    public init(size: Int? = nil) {
        if let size = size { bytes.reserveCapacity(size + 4) }
    }

    public var description: String {
        var result = "WritableBitStream \(endBitIndex): \n\t"
        for index in 0..<bytes.count {
            result.append((String(bytes[index], radix: 2) + " "))
        }
        return result
    }

    //MARK: - Append Bool
    @inlinable
    public mutating func append(_ value: Bool) {
        appendBit(UInt8(value ? 1 : 0))
    }
    
    //MARK: - Append FixedWidthInteger
    @inlinable
    @_specialize(where T == UInt8)
    @_specialize(where T == UInt16)
    @_specialize(where T == UInt32)
    @_specialize(where T == UInt64)
    @_specialize(where T == UInt)
    @_specialize(where T == Int8)
    @_specialize(where T == Int16)
    @_specialize(where T == Int32)
    @_specialize(where T == Int64)
    @_specialize(where T == Int)
    public mutating func append<T>(_ value: T) where T: FixedWidthInteger {
        var tempValue = value
        for _ in 0..<value.bitWidth {
            appendBit(UInt8(tempValue & 1))
            tempValue >>= 1
        }
    }
    
    @inlinable
    @_specialize(where T == UInt8)
    @_specialize(where T == UInt16)
    @_specialize(where T == UInt32)
    @_specialize(where T == UInt64)
    @_specialize(where T == UInt)
    public mutating func append<T>(_ value: T, numberOfBits: Int) where T: UnsignedInteger {
        var tempValue = value
        assert(numberOfBits <= value.bitWidth)
        for _ in 0..<numberOfBits {
            appendBit(UInt8(tempValue & 1))
            tempValue >>= 1
        }
    }
    
    // Appends an integer-based enum using the minimal number of bits for its set of possible cases.
    @inlinable
    public mutating func append<T>(_ value: T) where T: CaseIterable & RawRepresentable, T.RawValue == UInt32 {
        append(value.rawValue, numberOfBits: type(of: value).bits)
    }
    
    @inlinable
    public mutating func append(_ value: Float) {
        append(value.bitPattern)
    }
    
    @inlinable
    public mutating func append(_ value: Double) {
        append(value.bitPattern)
    }
    
    @inlinable
    public mutating func append(_ value: String) {
        append([UInt8](value.utf8))
    }
    
    @inlinable
    public mutating func append(_ value: [UInt8]) {
        align()
        let length = UInt32(value.count)
        append(length)
        bytes.append(contentsOf: value)
        endBitIndex += Int(length * 8)
    }
    
    @inlinable
    mutating internal func appendBit(_ value: UInt8) {
        let bitShift = endBitIndex & 7      //let bitShift = endBitIndex % 8
        let byteIndex = endBitIndex >> 3    //let byteIndex = endBitIndex / 8
        if bitShift == 0 {
            bytes.append(UInt8(0))
        }

        bytes[byteIndex] |= UInt8(value << bitShift)
        endBitIndex += 1
    }
    
    @inlinable
    mutating internal func align() {
        // skip over any remaining bits in the current byte
        endBitIndex = bytes.count * 8
    }

    // MARK: - Pack/Unpack Data
    @inlinable
    public func packBytes(withExtraCapacity: Int = 0) -> [UInt8] {
        let endBitIndex32 = UInt32(endBitIndex)
        let endBitIndexBytes = [UInt8(truncatingIfNeeded: endBitIndex32),
                                UInt8(truncatingIfNeeded: endBitIndex32 >> 8),
                                UInt8(truncatingIfNeeded: endBitIndex32 >> 16),
                                UInt8(truncatingIfNeeded: endBitIndex32 >> 24)]
        var result: [UInt8] = []
        result.reserveCapacity(bytes.count + 4 + withExtraCapacity)
        result.append(contentsOf: endBitIndexBytes)
        result.append(contentsOf: bytes)
        return result
    }
}

//MARK: ReadableBitStream
public struct ReadableBitStream {
    @usableFromInline
    var bytes: [UInt8]
    
    @usableFromInline
    var endBitIndex: Int
    
    @usableFromInline
    var currentBit = 0
    
    @usableFromInline
    var isAtEnd: Bool { return currentBit == endBitIndex }
    
    public init(bytes data: [UInt8]) {
        if data.count < 4 {
            fatalError("failed to init bitstream")
        }

        var endBitIndex32 = UInt32(data[0])
        endBitIndex32 |= (UInt32(data[1]) << 8)
        endBitIndex32 |= (UInt32(data[2]) << 16)
        endBitIndex32 |= (UInt32(data[3]) << 24)
        endBitIndex = Int(endBitIndex32)

        self.bytes = data
        bytes.removeSubrange(0...3)
    }
    
    // MARK: - Read
    
    @inlinable
    public mutating func read() throws -> Bool {
        if currentBit >= endBitIndex {
            throw BitStreamError.tooShort
        }
        return (readBit() > 0) ? true : false
    }
    
    @inlinable
    public mutating func read() throws -> Float {
        var result: Float = 0.0
        do {
            result = try Float(bitPattern: read())
        } catch let error {
            throw error
        }
        return result
    }
    
    @inlinable
    public mutating func read() throws -> Double {
        var result: Double = 0.0
        do {
            result = try Double(bitPattern: read())
        } catch let error {
            throw error
        }
        return result
    }
    
    @inlinable
    @_specialize(where T == UInt8)
    @_specialize(where T == UInt16)
    @_specialize(where T == UInt32)
    @_specialize(where T == UInt64)
    @_specialize(where T == UInt)
    @_specialize(where T == Int8)
    @_specialize(where T == Int16)
    @_specialize(where T == Int32)
    @_specialize(where T == Int64)
    @_specialize(where T == Int)
    public mutating func read<T>() throws -> T where T: FixedWidthInteger {
        if currentBit + T.bitWidth > endBitIndex {
            throw BitStreamError.tooShort
        }
        var bitPattern: T = 0
        for index in 0..<T.bitWidth {
            bitPattern |= (T(readBit()) << index)
        }
        return bitPattern
    }
    
    @inlinable
    @_specialize(where T == UInt8)
    @_specialize(where T == UInt16)
    @_specialize(where T == UInt32)
    @_specialize(where T == UInt64)
    @_specialize(where T == UInt)
    public mutating func read<T>(numberOfBits: Int) throws -> T where T: UnsignedInteger {
        if currentBit + numberOfBits > endBitIndex {
            throw BitStreamError.tooShort
        }
        var bitPattern: T = 0
        for index in 0..<numberOfBits {
            bitPattern |= (T(readBit()) << index)
        }
        return bitPattern
    }
    
    @inlinable
    public mutating func read() throws -> [UInt8] {
        align()
        let length = Int(try read() as UInt32)
        assert(currentBit & 7 == 0)
        guard currentBit + (length * 8) <= endBitIndex else {
            throw BitStreamError.tooShort
        }
        let currentByte = currentBit >> 3
        let endByte = currentByte + length

        let result = Array(bytes[currentByte..<endByte])
        currentBit += length * 8
        return result
    }
    
    @inlinable
    public mutating func read<T>() throws -> T where T: CaseIterable & RawRepresentable, T.RawValue == UInt32 {
        let rawValue = try read(numberOfBits: T.bits) as UInt32
        guard let result = T(rawValue: rawValue) else {
            throw BitStreamError.encodingError
        }
        return result
    }
    
    @inlinable
    public mutating func read() throws -> String {
        let bytes: [UInt8] = try read()
        return String(decoding: bytes, as: Unicode.UTF8.self)
    }
    
    @inlinable
    mutating internal func align() {
        let mod = currentBit & 7 //let mod = currentBit % 8
        if mod != 0 {
            currentBit += 8 - mod
        }
    }
    
    @inlinable
    mutating internal func readBit() -> UInt8 {
        let bitShift = currentBit & 7   //let bitShift = currentBit % 8
        let byteIndex = currentBit >> 3 //let byteIndex = currentBit / 8
        currentBit += 1
        return (bytes[byteIndex] >> bitShift) & 1
    }
}

public extension FloatCompressor {
    @inlinable
    func write(_ value: SIMD2<Float>, to string: inout WritableBitStream) {
        write(value.x, to: &string)
        write(value.y, to: &string)
    }
    
    @inlinable
    func write(_ value: SIMD3<Float>, to string: inout WritableBitStream) {
        write(value.x, to: &string)
        write(value.y, to: &string)
        write(value.z, to: &string)
    }
    
    @inlinable
    func read(from string: inout ReadableBitStream) throws -> SIMD2<Float> {
        return SIMD2<Float>(x: try read(from: &string), y: try read(from: &string))
    }
    
    @inlinable
    func read(from string: inout ReadableBitStream) throws -> SIMD3<Float> {
        return SIMD3<Float>(
            x: try read(from: &string),
            y: try read(from: &string),
            z: try read(from: &string))
    }
}

public extension DoubleCompressor {
    @inlinable
    func write(_ value: SIMD2<Double>, to string: inout WritableBitStream) {
        write(value.x, to: &string)
        write(value.y, to: &string)
    }
    
    @inlinable
    func write(_ value: SIMD3<Double>, to string: inout WritableBitStream) {
        write(value.x, to: &string)
        write(value.y, to: &string)
        write(value.z, to: &string)
    }
    
    @inlinable
    func read(from string: inout ReadableBitStream) throws -> SIMD2<Double> {
        return SIMD2<Double>(x: try read(from: &string), y: try read(from: &string))
    }
    
    @inlinable
    func read(from string: inout ReadableBitStream) throws -> SIMD3<Double> {
        return SIMD3<Double>(
            x: try read(from: &string),
            y: try read(from: &string),
            z: try read(from: &string))
    }
}
