//
//  ReadableBitStream.swift
//  sebbu-bitstream
//
//  Created by Sebastian Toivonen on 3.4.2026.
//

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
public struct ReadableBitStream: ~Copyable {
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
    /// - Parameter span: Bytes that are decoded.
    @inlinable
    public init(_ bytes: [UInt8]) throws(BitStreamError) {
        self.bytes = bytes
        if bytes.count < 4 {
            throw BitStreamError.tooShort
        }
        var endBitIndex32 = UInt32(bytes[0])
        endBitIndex32 |= (UInt32(bytes[1]) << 8)
        endBitIndex32 |= (UInt32(bytes[2]) << 16)
        endBitIndex32 |= (UInt32(bytes[3]) << 24)
        endBitIndex = Int(endBitIndex32)
        currentBit = 32
    }
    
    @inlinable
    public static func createValidatingCrc(_ bytes: [UInt8]) throws(BitStreamError) -> ReadableBitStream {
        if bytes.count < 8 {
            throw BitStreamError.tooShort
        }
        var crc = UInt32(bytes[bytes.count - 4])
        crc |= (UInt32(bytes[bytes.count - 3]) << 8)
        crc |= (UInt32(bytes[bytes.count - 2]) << 16)
        crc |= (UInt32(bytes[bytes.count - 1]) << 24)
        let checksum = bytes[0..<bytes.count - 4].crcChecksum
        if checksum != crc { throw BitStreamError.incorrectChecksum }
        return try ReadableBitStream(bytes)
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
    public mutating func read() throws(BitStreamError) -> Bool {
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
    public mutating func read(maxCount: Int = 1 << 29) throws(BitStreamError) -> [Bool] {
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
    public mutating func read() throws(BitStreamError) -> Float {
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
    public mutating func read(maxCount: Int = 1 << 29) throws(BitStreamError) -> [Float] {
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
    public mutating func read() throws(BitStreamError) -> Double {
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
    public mutating func read(maxCount: Int = 1 << 29) throws(BitStreamError) -> [Double] {
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
    @inlinable
    public mutating func read<T>() throws(BitStreamError) -> T where T: FixedWidthInteger {
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
    public mutating func read<T>(maxCount: Int = 1 << 29) throws(BitStreamError) -> [T] where T: FixedWidthInteger {
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
    @_specialize(exported: true, where T == UInt8)
    @_specialize(exported: true, where T == UInt16)
    @_specialize(exported: true, where T == UInt32)
    @_specialize(exported: true, where T == UInt64)
    @_specialize(exported: true, where T == UInt)
    @inlinable
    public mutating func read<T>(numberOfBits: Int) throws(BitStreamError) -> T where T: UnsignedInteger {
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
    public mutating func readBytes(maxCount: Int = 1 << 29) throws(BitStreamError) -> [UInt8] {
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
        let result: [UInt8] = .init(capacity: length) { span in
            for i in currentByte..<endByte {
                span.append(bytes[i])
            }
        }
        currentBit += length * 8
        return result
    }
    
    /// Read a buffer of bytes.
    ///
    /// - Returns: The decoded buffer of bytes.
    /// - Throws: A `BitStreamError.tooShort` if there are no bits left to read.
    @inlinable
    public mutating func readBytes(maxCount: Int = 1 << 29, into: inout OutputSpan<UInt8>) throws(BitStreamError) {
        assert(maxCount <= 1 << 29, "The maximum count of the array must be less than 2^29")
        assert(maxCount > 0, "The maximum count must be more than zero")
        let countBits = UInt64.bitWidth - maxCount.leadingZeroBitCount
        let length = Int(try read(numberOfBits: countBits) as UInt32)
        precondition(into.freeCapacity >= length)
        align()
        assert(currentBit & 7 == 0)
        guard currentBit + (length * 8) <= endBitIndex else {
            throw BitStreamError.tooShort
        }
        let currentByte = currentBit >> 3
        let endByte = currentByte + length
        for i in currentByte..<endByte {
            into.append(bytes[i])
        }
        currentBit += length * 8
    }
    
    /// Read an enum value
    ///
    /// - Returns: The decoded enum value.
    /// - Throws: A `BitStreamError.tooShort` if there are no bits left to read.
    /// - Throws: A `BitStreamError.encoding` if the enum couldn't be constructed from the encoded value.
    @inlinable
    public mutating func read<T>() throws(BitStreamError) -> T where T: CaseIterable & RawRepresentable, T.RawValue == UInt32 {
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
    public mutating func read<T>(maxCount: Int = 1 << 29) throws(BitStreamError) -> [T] where T: CaseIterable & RawRepresentable, T.RawValue == UInt32 {
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
    public mutating func read() throws(BitStreamError) -> String {
        let bytes: [UInt8] = try readBytes()
        return String(decoding: bytes, as: Unicode.UTF8.self)
    }
    
    /// Read a UTF8 string.
    ///
    /// - Returns: The UTF8 encoded string
    /// - Throws: A `BitStreamError.tooShort` if there are no bits left to read.
    @inlinable
    public mutating func read(maxCount: Int = 1 << 29) throws(BitStreamError) -> [String] {
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

public extension Array<UInt8> {
    func decode<T: BitStreamDecodable>() throws(BitStreamError) -> T {
        var stream = try ReadableBitStream(self)
        return try stream.read()
    }
}
