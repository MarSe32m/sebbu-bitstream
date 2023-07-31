//
//  BitStream.swift
//
//  Created by Sebastian Toivonen on 8.8.2021.
//
//  Copyright © 2021 Sebastian Toivonen. All rights reserved.

/// Possible error that can occur when using `ReadableBitStream`s.
public enum BitStreamError: Error {
    case tooShort
    case encodingError
    case incorrectChecksum
}

//TODO: non-copyable?
/// A writable bit stream used to encode objects into a packed stream of bytes.
///
/// Basic usage
/// ```
/// var stream = WritableBitStream()
/// stream.append(-29)
/// stream.append(883, numberOfBits: 7)
/// stream.append(100.0)
/// stream.append("Some string")
/// ```
public struct WritableBitStream: CustomStringConvertible {
    @usableFromInline
    var bytes: [UInt8] = []
    
    @usableFromInline
    var endBitIndex = 0

    /// Initialize a new `WritableBitStream`.
    ///
    /// - Parameter size: The amount of bytes to reserve for the `WritableBitStream`. By correctly specifying the size can reduce the amount of allocations during encoding.
    public init(size: Int = 0) {
        precondition(size >= 0)
        // 4: endBitIndex + size: data + 4: possible crc
        reset(reservingCapacity: 4 + size + 4)
    }

    /// Reset the stream into a fresh state.
    ///
    /// - Parameter reservingCapacity: Give the size that the underlying buffer will reserve.
    @inlinable
    public mutating func reset(reservingCapacity: Int = 0) {
        bytes.removeAll(keepingCapacity: reservingCapacity == 0)
        if reservingCapacity != 0 {
            bytes.reserveCapacity(4 + reservingCapacity + 4)
        }
        endBitIndex = 0
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

    /// Append a boolean value.
    ///
    /// - Parameter value: The boolean value to be encoded.
    ///
    /// The `Bool` is encoded as one bit.
    ///
    /// - Complexity: O(1)
    @inlinable
    public mutating func append(_ value: Bool) {
        appendBit(UInt8(value ? 1 : 0))
    }
    
    /// Append an array of boolean values.
    ///
    /// - Parameter value: The boolean values to be encoded.
    ///
    /// The `Bool` is encoded as one bit.
    ///
    /// - Complexity: O(n)
    @inlinable
    public mutating func append(_ value: [Bool], maxCount: Int = 1 << 29) {
        assert(maxCount <= 1 << 29, "The maximum count of the array must be less than 2^29")
        assert(maxCount > 0, "The maximum count must be more than zero")
        let countBits = UInt64.bitWidth - maxCount.leadingZeroBitCount
        append(UInt32(value.count), numberOfBits: countBits)
        for element in value {
            append(element)
        }
    }
    
    /// Append a `FixedWidthInteger`.
    ///
    /// - Parameter value: The integer value to be encoded.
    ///
    /// The value if encoded using the corresponding amount of bits as the integer bit width.
    ///
    /// - Complexity: O(1)
    @inlinable
    @_specialize(exported: true, where T == UInt8)
    @_specialize(exported: true, where T == UInt16)
    @_specialize(exported: true, where T == UInt32)
    @_specialize(exported: true, where T == UInt64)
    @_specialize(exported: true, where T == UInt)
    @_specialize(exported: true, where T == Int8)
    @_specialize(exported: true, where T == Int16)
    @_specialize(exported: true, where T == Int32)
    @_specialize(exported: true, where T == Int64)
    @_specialize(exported: true, where T == Int)
    public mutating func append<T>(_ value: T) where T: FixedWidthInteger {
        var tempValue = value
        for _ in 0..<value.bitWidth {
            appendBit(UInt8(tempValue & 1))
            tempValue >>= 1
        }
    }
    
    /// Append an array of `FixedWidthInteger`s.
    ///
    /// - Parameter value: The integer values to be encoded.
    ///
    /// The value is encoded using the corresponding amount of bits as the integer bit width.
    ///
    /// - Complexity: O(n)
    @inlinable
    #if !os(Windows)
    @_specialize(exported: true, where T == UInt8)
    @_specialize(exported: true, where T == UInt16)
    @_specialize(exported: true, where T == UInt32)
    @_specialize(exported: true, where T == UInt64)
    @_specialize(exported: true, where T == UInt)
    @_specialize(exported: true, where T == Int8)
    @_specialize(exported: true, where T == Int16)
    @_specialize(exported: true, where T == Int32)
    @_specialize(exported: true, where T == Int64)
    @_specialize(exported: true, where T == Int)
    #endif
    public mutating func append<T>(_ value: [T], maxCount: Int = 1 << 29) where T: FixedWidthInteger {
        assert(maxCount <= 1 << 29, "The maximum count of the array must be less than 2^29")
        assert(maxCount > 0, "The maximum count must be more than zero")
        let countBits = UInt64.bitWidth - maxCount.leadingZeroBitCount
        append(UInt32(value.count), numberOfBits: countBits)
        for element in value {
            append(element)
        }
    }
    
    /// Append an `UnsignedInteger` with a custom number of bits.
    ///
    /// - Parameter value: The unsigned integer value to be encoded.
    /// - Parameter numberOfBits: The number of bits to be used to encode the value.
    ///
    /// - Complexity: O(1)
    @inlinable
    @_specialize(exported: true, where T == UInt8)
    @_specialize(exported: true, where T == UInt16)
    @_specialize(exported: true, where T == UInt32)
    @_specialize(exported: true, where T == UInt64)
    @_specialize(exported: true, where T == UInt)
    public mutating func append<T>(_ value: T, numberOfBits: Int) where T: UnsignedInteger {
        var tempValue = value
        assert(numberOfBits <= value.bitWidth)
        for _ in 0..<numberOfBits {
            appendBit(UInt8(tempValue & 1))
            tempValue >>= 1
        }
    }
    
    /// Append an unsigned integer based enum using the minimal number of bits for its set of possible cases.
    ///
    /// - Parameter value: The enum value to be encoded.
    ///
    /// - Complexity: O(1)
    @inlinable
    public mutating func append<T>(_ value: T) where T: CaseIterable & RawRepresentable, T.RawValue == UInt32 {
        append(value.rawValue, numberOfBits: T.bits)
    }
    
    /// Append an unsigned integer based enum using the minimal number of bits for its set of possible cases.
    ///
    /// - Parameter value: The enum value to be encoded.
    ///
    /// - Complexity: O(1)
    @inlinable
    public mutating func append<T>(_ value: [T], maxCount: Int = 1 << 29) where T: CaseIterable & RawRepresentable, T.RawValue == UInt32 {
        assert(maxCount <= 1 << 29, "The maximum count of the array must be less than 2^29")
        assert(maxCount > 0, "The maximum count must be more than zero")
        let countBits = UInt64.bitWidth - maxCount.leadingZeroBitCount
        append(UInt32(value.count), numberOfBits: countBits)
        for element in value {
            append(element)
        }
    }

    /// Append a float value.
    ///
    /// - Parameter value: The float value to be encoded.
    ///
    /// - Complexity: O(1)
    @inlinable
    public mutating func append(_ value: Float) {
        append(value.bitPattern)
    }
    
    /// Append an array of floats.
    ///
    /// - Parameter value: The float value to be encoded.
    ///
    /// - Complexity: O(n)
    @inlinable
    public mutating func append(_ value: [Float], maxCount: Int = 1 << 29) {
        assert(maxCount <= 1 << 29, "The maximum count of the array must be less than 2^29")
        assert(maxCount > 0, "The maximum count must be more than zero")
        let countBits = UInt64.bitWidth - maxCount.leadingZeroBitCount
        append(UInt32(value.count), numberOfBits: countBits)
        for element in value {
            append(element)
        }
    }
    
    /// Append a double value.
    ///
    /// - Parameter value: The double value to be encoded.
    ///
    /// - Complexity: O(1)
    @inlinable
    public mutating func append(_ value: Double) {
        append(value.bitPattern)
    }
    
    /// Append an array of doubles.
    ///
    /// - Parameter value: The float value to be encoded.
    ///
    /// - Complexity: O(n)
    @inlinable
    public mutating func append(_ value: [Double], maxCount: Int = 1 << 29) {
        assert(maxCount <= 1 << 29, "The maximum count of the array must be less than 2^29")
        assert(maxCount > 0, "The maximum count must be more than zero")
        let countBits = UInt64.bitWidth - maxCount.leadingZeroBitCount
        append(UInt32(value.count), numberOfBits: countBits)
        for element in value {
            append(element)
        }
    }
    
    /// Append a string using UTF8 encoding.
    ///
    /// - Parameter value: A UTF8 compatible string to be encoded
    ///
    ///
    /// - Complexity: O(*n*), where *n* is the length of the string
    @inlinable
    public mutating func append(_ value: String) {
        appendBytes([UInt8](value.utf8))
    }
    
    /// Append an array of strings using UTF8 encoding.
    ///
    /// - Parameter value: An array of UTF8 compatible strings to be encoded
    ///
    ///
    /// - Complexity: O(*n* * *m*), where *n* is the length of the string and m is the length of the array
    @inlinable
    public mutating func append(_ value: [String], maxCount: Int = 1 << 29) {
        assert(maxCount <= 1 << 29, "The maximum count of the array must be less than 2^29")
        assert(maxCount > 0, "The maximum count must be more than zero")
        let countBits = UInt64.bitWidth - maxCount.leadingZeroBitCount
        append(UInt32(value.count), numberOfBits: countBits)
        for element in value {
            append(element)
        }
    }
    
    /// Append bytes.
    ///
    /// - Parameter value: Bytes to be encoded.
    ///
    /// - Complexity: O(*n*), where *n* is the number of bytes in the bytes to be encoded.
    @inlinable
    public mutating func appendBytes(_ value: [UInt8], maxCount: Int = 1 << 29) {
        assert(maxCount <= 1 << 29, "The maximum count of the array must be less than 2^29")
        assert(maxCount > 0, "The maximum count must be more than zero")
        let countBits = UInt64.bitWidth - maxCount.leadingZeroBitCount
        let length = UInt32(value.count)
        append(length, numberOfBits: countBits)
        align()
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

    /// Pack the buffer into transferable form.
    ///
    /// - Parameters withCrc: Boolean value to indicate if a CRC checksum is appended to the bytes
    ///
    /// - Returns: The packed bytes that can be transferred and decoded.
    @inlinable
    @_optimize(speed)
    public mutating func packBytes(withCrc: Bool = false) -> [UInt8] {
        let endBitIndex32 = UInt32(endBitIndex)
        withUnsafeBytes(of: endBitIndex32) { 
            bytes[0] = $0[0]
            bytes[1] = $0[1]
            bytes[2] = $0[2]
            bytes[3] = $0[3]
        }
        if withCrc {
            let crc = bytes.crcChecksum
            withUnsafeBytes(of: crc) {
                bytes.append(contentsOf: $0)
            }
        }
        return bytes
    }
}

//TODO: non-copyable?
/// A readable bit stream used to decode packed bytes by a writable bit stream.
///
/// Basic usage
/// ```
/// ...
/// let buffer = writeStream.packBytes()
/// var stream = ReadableBitStream(bytes: buffer)
/// let age = try stream.read() as Int
/// let name: String = try stream.read()
/// let length = try stream.read() as Float
/// ```
/// The reading of values must correspond to the order at which the values were encoded into the stream.
public struct ReadableBitStream: CustomStringConvertible {
    @usableFromInline
    let bytes: [UInt8]
    
    @usableFromInline
    var endBitIndex: Int
    
    @usableFromInline
    var currentBit = 0
    
    @usableFromInline
    var isAtEnd: Bool { return currentBit == endBitIndex }
    
    /// Initialize a new `ReadableBitStream` from given bytes.
    ///
    /// - Parameter bytes: Bytes that are decoded.
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

    /// Initialize a new `ReadableBitStream` from given bytes.
    ///
    /// - Parameter bytes: Bytes that are decoded.
    /// - Parameter crcValidated: Boolean value to indicate wheter to validate an appended crc.
    public init(bytes data: [UInt8], crcValidated: Bool) throws {
        precondition(data.count >= 8, "Failed to initialize bit stream, the provided count was \(data.count)")
        if _fastPath(crcValidated) {
            let checksum = data[0..<data.count - 4].crcChecksum
            var crc = UInt32(data[data.count - 4])
            crc |= (UInt32(data[data.count - 3]) << 8)
            crc |= (UInt32(data[data.count - 2]) << 16)
            crc |= (UInt32(data[data.count - 1]) << 24)
            if checksum != crc { throw BitStreamError.incorrectChecksum }
        }
        self = ReadableBitStream(bytes: data)
    }
    
    public var description: String {
        var result = "ReadableBitStream \(endBitIndex): \n\t"
        for index in currentBit / 8 ..< bytes.count {
            result.append((String(bytes[index], radix: 2) + " "))
        }
        return result
    }
    
    /// Read a boolean value.
    ///
    /// - Returns: The decoded boolean value.
    /// - Throws: A `BitStreamError.tooShort` if there are no bits left to read.
    @inlinable
    public mutating func read() throws -> Bool {
        if currentBit >= endBitIndex {
            throw BitStreamError.tooShort
        }
        return (readBit() > 0) ? true : false
    }
    
    /// Read an array of boolean values.
    ///
    /// - Returns: The decoded boolean value.
    /// - Throws: A `BitStreamError.tooShort` if there are no bits left to read.
    @inlinable
    public mutating func read(maxCount: Int = 1 << 29) throws -> [Bool] {
        assert(maxCount <= 1 << 29, "The maximum count of the array must be less than 2^29")
        assert(maxCount > 0, "The maximum count must be more than zero")
        let countBits = UInt64.bitWidth - maxCount.leadingZeroBitCount
        let count = Int(try read(numberOfBits: countBits) as UInt32)
        if count == 0 { return [] }
        var result: [Bool] = []
        result.reserveCapacity(count)
        for _ in 0..<count {
            try result.append(read())
        }
        return result
    }
    
    /// Read a float value.
    ///
    /// - Returns: The decoded float value.
    /// - Throws: A `BitStreamError.tooShort` if there are no bits left to read.
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
    
    /// Read an array of floats.
    ///
    /// - Returns: The decoded float value.
    /// - Throws: A `BitStreamError.tooShort` if there are no bits left to read.
    @inlinable
    public mutating func read(maxCount: Int = 1 << 29) throws -> [Float] {
        assert(maxCount <= 1 << 29, "The maximum count of the array must be less than 2^29")
        assert(maxCount > 0, "The maximum count must be more than zero")
        let countBits = UInt64.bitWidth - maxCount.leadingZeroBitCount
        let count = Int(try read(numberOfBits: countBits) as UInt32)
        if count == 0 { return [] }
        var result: [Float] = []
        result.reserveCapacity(count)
        for _ in 0..<count {
            try result.append(read())
        }
        return result
    }
    
    /// Read a double value.
    ///
    /// - Returns: The decoded double value.
    /// - Throws: A `BitStreamError.tooShort` if there are no bits left to read.
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
    
    /// Read an array of doubles.
    ///
    /// - Returns: The decoded doubles.
    /// - Throws: A `BitStreamError.tooShort` if there are no bits left to read.
    @inlinable
    public mutating func read(maxCount: Int = 1 << 29) throws -> [Double] {
        assert(maxCount <= 1 << 29, "The maximum count of the array must be less than 2^29")
        assert(maxCount > 0, "The maximum count must be more than zero")
        let countBits = UInt64.bitWidth - maxCount.leadingZeroBitCount
        let count = Int(try read(numberOfBits: countBits) as UInt32)
        if count == 0 { return [] }
        var result: [Double] = []
        result.reserveCapacity(count)
        for _ in 0..<count {
            try result.append(read())
        }
        return result
    }
    
    /// Read a `FixedWidthInteger` value.
    ///
    /// - Returns: The decoded fixed width integer.
    /// - Throws: A `BitStreamError.tooShort` if there are no bits left to read.
    @inlinable
    @_specialize(exported: true, where T == UInt8)
    @_specialize(exported: true, where T == UInt16)
    @_specialize(exported: true, where T == UInt32)
    @_specialize(exported: true, where T == UInt64)
    @_specialize(exported: true, where T == UInt)
    @_specialize(exported: true, where T == Int8)
    @_specialize(exported: true, where T == Int16)
    @_specialize(exported: true, where T == Int32)
    @_specialize(exported: true, where T == Int64)
    @_specialize(exported: true, where T == Int)
    public mutating func read<T>() throws -> T where T: FixedWidthInteger {
        if currentBit + T.bitWidth > endBitIndex {
            throw BitStreamError.tooShort
        }
        var bitPattern: T = 0
        for index in 0..<T.bitWidth {
            bitPattern |= T(readBit()) << index
        }
        return bitPattern
    }
    
    /// Read a `FixedWidthInteger` value.
    ///
    /// - Returns: The decoded fixed width integer.
    /// - Throws: A `BitStreamError.tooShort` if there are no bits left to read.
    @inlinable
    #if !os(Windows)
    @_specialize(exported: true, where T == UInt8)
    @_specialize(exported: true, where T == UInt16)
    @_specialize(exported: true, where T == UInt32)
    @_specialize(exported: true, where T == UInt64)
    @_specialize(exported: true, where T == UInt)
    @_specialize(exported: true, where T == Int8)
    @_specialize(exported: true, where T == Int16)
    @_specialize(exported: true, where T == Int32)
    @_specialize(exported: true, where T == Int64)
    @_specialize(exported: true, where T == Int)
    #endif
    public mutating func read<T>(maxCount: Int = 1 << 29) throws -> [T] where T: FixedWidthInteger {
        assert(maxCount <= 1 << 29, "The maximum count of the array must be less than 2^29")
        assert(maxCount > 0, "The maximum count must be more than zero")
        let countBits = UInt64.bitWidth - maxCount.leadingZeroBitCount
        let count = Int(try read(numberOfBits: countBits) as UInt32)
        if count == 0 { return [] }
        var result: [T] = []
        result.reserveCapacity(count)
        for _ in 0..<count {
            try result.append(read())
        }
        return result
    }
    
    /// Read an `UnsignedInteger` value.
    ///
    /// - Returns: The decoded unsigned integer.
    /// - Throws: A `BitStreamError.tooShort` if there are no bits left to read.
    @inlinable
    @_specialize(exported: true, where T == UInt8)
    @_specialize(exported: true, where T == UInt16)
    @_specialize(exported: true, where T == UInt32)
    @_specialize(exported: true, where T == UInt64)
    @_specialize(exported: true, where T == UInt)
    public mutating func read<T>(numberOfBits: Int) throws -> T where T: UnsignedInteger {
        if currentBit + numberOfBits > endBitIndex {
            throw BitStreamError.tooShort
        }
        var bitPattern: T = 0
        for index in 0..<numberOfBits {
            bitPattern |= T(readBit()) << index
        }
        return bitPattern
    }
    
    /// Read a buffer of bytes.
    ///
    /// - Returns: The decoded buffer of bytes.
    /// - Throws: A `BitStreamError.tooShort` if there are no bits left to read.
    @inlinable
    public mutating func readBytes(maxCount: Int = 1 << 29) throws -> [UInt8] {
        assert(maxCount <= 1 << 29, "The maximum count of the array must be less than 2^29")
        assert(maxCount > 0, "The maximum count must be more than zero")
        let countBits = UInt64.bitWidth - maxCount.leadingZeroBitCount
        let length = Int(try read(numberOfBits: countBits) as UInt32)
        align()
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
    
    /// Read an enum value
    ///
    /// - Returns: The decoded enum value.
    /// - Throws: A `BitStreamError.tooShort` if there are no bits left to read.
    /// - Throws: A `BitStreamError.encoding` if the enum couldn't be constructed from the encoded value.
    @inlinable
    public mutating func read<T>() throws -> T where T: CaseIterable & RawRepresentable, T.RawValue == UInt32 {
        let rawValue = try read(numberOfBits: T.bits) as UInt32
        guard let result = T(rawValue: rawValue) else {
            throw BitStreamError.encodingError
        }
        return result
    }
    
    /// Read an enum value
    ///
    /// - Returns: The decoded enum value.
    /// - Throws: A `BitStreamError.tooShort` if there are no bits left to read.
    /// - Throws: A `BitStreamError.encoding` if the enum couldn't be constructed from the encoded value.
    @inlinable
    public mutating func read<T>(maxCount: Int = 1 << 29) throws -> [T] where T: CaseIterable & RawRepresentable, T.RawValue == UInt32 {
        assert(maxCount <= 1 << 29, "The maximum count of the array must be less than 2^29")
        assert(maxCount > 0, "The maximum count must be more than zero")
        let countBits = UInt64.bitWidth - maxCount.leadingZeroBitCount
        let count = Int(try read(numberOfBits: countBits) as UInt32)
        if count == 0 { return [] }
        var result: [T] = []
        result.reserveCapacity(count)
        for _ in 0..<count {
            try result.append(read())
        }
        return result
    }

    /// Read a UTF8 string.
    ///
    /// - Returns: The UTF8 encoded string
    /// - Throws: A `BitStreamError.tooShort` if there are no bits left to read.
    @inlinable
    public mutating func read() throws -> String {
        let bytes: [UInt8] = try readBytes()
        return String(decoding: bytes, as: Unicode.UTF8.self)
    }
    
    /// Read a UTF8 string.
    ///
    /// - Returns: The UTF8 encoded string
    /// - Throws: A `BitStreamError.tooShort` if there are no bits left to read.
    @inlinable
    public mutating func read(maxCount: Int = 1 << 29) throws -> [String] {
        assert(maxCount <= 1 << 29, "The maximum count of the array must be less than 2^29")
        assert(maxCount > 0, "The maximum count must be more than zero")
        let countBits = UInt64.bitWidth - maxCount.leadingZeroBitCount
        let count = Int(try read(numberOfBits: countBits) as UInt32)
        if count == 0 { return [] }
        var result: [String] = []
        result.reserveCapacity(count)
        for _ in 0..<count {
            try result.append(read())
        }
        return result
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
