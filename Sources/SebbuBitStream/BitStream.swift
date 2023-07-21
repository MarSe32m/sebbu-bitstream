//
//  BitStream.swift
//
//  Created by Sebastian Toivonen on 8.8.2021.
//
//  Copyright © 2021 Sebastian Toivonen. All rights reserved.

public enum BitStreamError: Error {
    case tooShort
    case encodingError
    case incorrectChecksum
}

/// Gets the number of bits required to encode an enum case.
public extension RawRepresentable where Self: CaseIterable, RawValue == UInt8 {
    @inlinable
    static var bits: Int {
        let casesCount = UInt8(allCases.count)
        return UInt32.bitWidth - casesCount.leadingZeroBitCount
    }
}

public extension RawRepresentable where Self: CaseIterable, RawValue == UInt16 {
    @inlinable
    static var bits: Int {
        let casesCount = UInt16(allCases.count)
        return UInt32.bitWidth - casesCount.leadingZeroBitCount
    }
}

public extension RawRepresentable where Self: CaseIterable, RawValue == UInt32 {
    @inlinable
    static var bits: Int {
        let casesCount = UInt32(allCases.count)
        return UInt32.bitWidth - casesCount.leadingZeroBitCount
    }
}

public extension RawRepresentable where Self: CaseIterable, RawValue == UInt64 {
    @inlinable
    static var bits: Int {
        let casesCount = UInt64(allCases.count)
        return UInt32.bitWidth - casesCount.leadingZeroBitCount
    }
}

public extension RawRepresentable where Self: CaseIterable, RawValue == UInt {
    @inlinable
    static var bits: Int {
        let casesCount = UInt(allCases.count)
        return UInt32.bitWidth - casesCount.leadingZeroBitCount
    }
}

//MARK: WritableBitStream
//TODO: non-copyable?
public struct WritableBitStream {
    @usableFromInline
    var bytes: [UInt8]
    
    @usableFromInline
    var endBitIndex = 0

    public init(size: Int? = nil) {
        bytes = []
        if let size = size {
            // 4: endBitIndex + size: data + 4: possible crc
            bytes.reserveCapacity(4 + size + 4)
        }
        append(0 as UInt8)
        append(0 as UInt8)
        append(0 as UInt8)
        append(0 as UInt8)
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
    @_specialize(exported: true, kind: full, where T == UInt8)
    @_specialize(exported: true, kind: full, where T == UInt16)
    @_specialize(exported: true, kind: full, where T == UInt32)
    @_specialize(exported: true, kind: full, where T == UInt64)
    @_specialize(exported: true, kind: full, where T == UInt)
    @_specialize(exported: true, kind: full, where T == Int8)
    @_specialize(exported: true, kind: full, where T == Int16)
    @_specialize(exported: true, kind: full, where T == Int32)
    @_specialize(exported: true, kind: full, where T == Int64)
    @_specialize(exported: true, kind: full, where T == Int)
    public mutating func append<T>(_ value: T) where T: FixedWidthInteger {
        var tempValue = value
        for _ in 0..<value.bitWidth {
            appendBit(UInt8(tempValue & 1))
            tempValue >>= 1
        }
    }
    
    @inlinable
    @_specialize(exported: true, kind: full, where T == UInt8)
    @_specialize(exported: true, kind: full, where T == UInt16)
    @_specialize(exported: true, kind: full, where T == UInt32)
    @_specialize(exported: true, kind: full, where T == UInt64)
    @_specialize(exported: true, kind: full, where T == UInt)
    public mutating func append<T>(_ value: T, numberOfBits: Int) where T: UnsignedInteger {
        var tempValue = value
        assert(numberOfBits <= value.bitWidth)
        for _ in 0..<numberOfBits {
            appendBit(UInt8(tempValue & 1))
            tempValue >>= 1
        }
    }
    
    // Appends an integer-based enum using the minimal number of bits for its set of possible cases.
    //TODO: Add test
    @inlinable
    public mutating func append<T>(_ value: T) where T: CaseIterable & RawRepresentable, T.RawValue == UInt8 {
        append(value.rawValue, numberOfBits: T.bits)
    }

    @inlinable
    //TODO: Add test
    public mutating func append<T>(_ value: T) where T: CaseIterable & RawRepresentable, T.RawValue == UInt16 {
        append(value.rawValue, numberOfBits: T.bits)
    }

    @inlinable
    //TODO: Add test
    public mutating func append<T>(_ value: T) where T: CaseIterable & RawRepresentable, T.RawValue == UInt32 {
        append(value.rawValue, numberOfBits: T.bits)
    }

    @inlinable
    //TODO: Add test
    public mutating func append<T>(_ value: T) where T: CaseIterable & RawRepresentable, T.RawValue == UInt64 {
        append(value.rawValue, numberOfBits: T.bits)
    }

    @inlinable
    //TODO: Add test
    public mutating func append<T>(_ value: T) where T: CaseIterable & RawRepresentable, T.RawValue == UInt {
        append(value.rawValue, numberOfBits: T.bits)
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
    @inline(__always)
    mutating internal func align() {
        // skip over any remaining bits in the current byte
        endBitIndex = bytes.count * 8
    }

    // MARK: - Pack/Unpack Data
    @inlinable
    @_optimize(speed)
    public mutating func packBytes(withExtraCapacity: Int = 0, crcAppended: Bool = false) -> [UInt8] {
        assert(withExtraCapacity >= 0, "Extra capacity cannot be negative")
        let endBitIndex32 = UInt32(endBitIndex)
        withUnsafeBytes(of: endBitIndex32) { 
            bytes[0] = $0[0]
            bytes[1] = $0[1]
            bytes[2] = $0[2]
            bytes[3] = $0[3]
        }
        if crcAppended {
            let crc = bytes.crcChecksum
            withUnsafeBytes(of: crc) {
                bytes.append(contentsOf: $0)
            }
        }
        return bytes
    }
}

//MARK: ReadableBitStream
//TODO: non-copyable?
public struct ReadableBitStream {
    @usableFromInline
    let bytes: [UInt8]
    
    @usableFromInline
    var endBitIndex: Int
    
    @usableFromInline
    var currentBit = 0
    
    @usableFromInline
    var isAtEnd: Bool { return currentBit == endBitIndex }
    
    public init(bytes data: [UInt8]) {
        precondition(data.count >= 4, "Failed to initialize bit stream, the provided count was \(data.count)")
        // Since arrays are copy-on-write, this will not copy 
        // unless the passed in array is modified by the outside caller
        self.bytes = data
        var endBitIndex32 = UInt32(data[0])
        endBitIndex32 |= (UInt32(data[1]) << 8)
        endBitIndex32 |= (UInt32(data[2]) << 16)
        endBitIndex32 |= (UInt32(data[3]) << 24)
        endBitIndex = Int(endBitIndex32)
        currentBit = 32
    }

    public init(bytes data: [UInt8], withCRCValidated: Bool) throws {
        precondition(data.count >= 8, "Failed to initialize bit stream, the provided count was \(data.count)")
        if _fastPath(withCRCValidated) {
            let checksum = data[0..<data.count - 4].crcChecksum
            var crc = UInt32(data[data.count - 4])
            crc |= (UInt32(data[data.count - 3]) << 8)
            crc |= (UInt32(data[data.count - 2]) << 16)
            crc |= (UInt32(data[data.count - 1]) << 24)
            if checksum != crc { throw BitStreamError.incorrectChecksum }
        }
        self = ReadableBitStream(bytes: data)
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
    @_specialize(exported: true, kind: full, where T == UInt8)
    @_specialize(exported: true, kind: full, where T == UInt16)
    @_specialize(exported: true, kind: full, where T == UInt32)
    @_specialize(exported: true, kind: full, where T == UInt64)
    @_specialize(exported: true, kind: full, where T == UInt)
    @_specialize(exported: true, kind: full, where T == Int8)
    @_specialize(exported: true, kind: full, where T == Int16)
    @_specialize(exported: true, kind: full, where T == Int32)
    @_specialize(exported: true, kind: full, where T == Int64)
    @_specialize(exported: true, kind: full, where T == Int)
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
    @_specialize(exported: true, kind: full, where T == UInt8)
    @_specialize(exported: true, kind: full, where T == UInt16)
    @_specialize(exported: true, kind: full, where T == UInt32)
    @_specialize(exported: true, kind: full, where T == UInt64)
    @_specialize(exported: true, kind: full, where T == UInt)
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
    //TODO: Add test
    public mutating func read<T>() throws -> T where T: CaseIterable & RawRepresentable, T.RawValue == UInt8 {
        let rawValue = try read(numberOfBits: T.bits) as UInt8
        guard let result = T(rawValue: rawValue) else {
            throw BitStreamError.encodingError
        }
        return result
    }

    @inlinable
    //TODO: Add test
    public mutating func read<T>() throws -> T where T: CaseIterable & RawRepresentable, T.RawValue == UInt16 {
        let rawValue = try read(numberOfBits: T.bits) as UInt16
        guard let result = T(rawValue: rawValue) else {
            throw BitStreamError.encodingError
        }
        return result
    }

    @inlinable
    //TODO: Add test
    public mutating func read<T>() throws -> T where T: CaseIterable & RawRepresentable, T.RawValue == UInt32 {
        let rawValue = try read(numberOfBits: T.bits) as UInt32
        guard let result = T(rawValue: rawValue) else {
            throw BitStreamError.encodingError
        }
        return result
    }

    @inlinable
    //TODO: Add test
    public mutating func read<T>() throws -> T where T: CaseIterable & RawRepresentable, T.RawValue == UInt64 {
        let rawValue = try read(numberOfBits: T.bits) as UInt64
        guard let result = T(rawValue: rawValue) else {
            throw BitStreamError.encodingError
        }
        return result
    }
    
    @inlinable
    //TODO: Add test
    public mutating func read<T>() throws -> T where T: CaseIterable & RawRepresentable, T.RawValue == UInt {
        let rawValue = try read(numberOfBits: T.bits) as UInt
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
    func write(_ value: SIMD2<Float>, to stream: inout WritableBitStream) {
        write(value.x, to: &stream)
        write(value.y, to: &stream)
    }
    
    @inlinable
    func write(_ value: SIMD3<Float>, to stream: inout WritableBitStream) {
        write(value.x, to: &stream)
        write(value.y, to: &stream)
        write(value.z, to: &stream)
    }
    
    @inlinable
    func read(from stream: inout ReadableBitStream) throws -> SIMD2<Float> {
        return SIMD2<Float>(x: try read(from: &stream), y: try read(from: &stream))
    }
    
    @inlinable
    func read(from stream: inout ReadableBitStream) throws -> SIMD3<Float> {
        return SIMD3<Float>(
            x: try read(from: &stream),
            y: try read(from: &stream),
            z: try read(from: &stream))
    }
}

public extension DoubleCompressor {
    @inlinable
    func write(_ value: SIMD2<Double>, to stream: inout WritableBitStream) {
        write(value.x, to: &stream)
        write(value.y, to: &stream)
    }
    
    @inlinable
    func write(_ value: SIMD3<Double>, to stream: inout WritableBitStream) {
        write(value.x, to: &stream)
        write(value.y, to: &stream)
        write(value.z, to: &stream)
    }
    
    @inlinable
    func read(from stream: inout ReadableBitStream) throws -> SIMD2<Double> {
        return SIMD2<Double>(x: try read(from: &stream), y: try read(from: &stream))
    }
    
    @inlinable
    func read(from stream: inout ReadableBitStream) throws -> SIMD3<Double> {
        return SIMD3<Double>(
            x: try read(from: &stream),
            y: try read(from: &stream),
            z: try read(from: &stream))
    }
}
