//
//  WritableBitStream.swift
//  sebbu-bitstream
//
//  Created by Sebastian Toivonen on 3.4.2026.
//

/// A writable bit stream used to encode objects into a packed stream of bytes.
///
/// Basic usage
/// ```
/// var stream = WritableBitStream()
/// stream.append(-29)
/// stream.append(883, numberOfBits: 7)
/// stream.append(100.0)
/// stream.append("Some string")
/// let bytes = stream.finalize(crc: false)
/// ```
public struct WritableBitStream: ~Copyable {
    @usableFromInline
    var bytes: [UInt8]
    
    @usableFromInline
    var endBitIndex = 0

    /// Initialize a new `WritableBitStream`
    ///
    /// - Parameter span: Output span into which the bit stream will be encoded
    @inlinable
    public init() {
        bytes = []
        // Bytes for endBitIndex
        reset(keepingCapacity: false)
    }
    
    @inlinable
    public init(_ bytes: [UInt8]) {
        self.bytes = bytes
    }
    
    @inlinable
    public mutating func reset(keepingCapacity: Bool = true) {
        bytes.removeAll(keepingCapacity: keepingCapacity)
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
    @inline(always)
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
    @_specialize(exported: true, where T == UInt8)
    @_specialize(exported: true, where T == UInt16)
    @_specialize(exported: true, where T == UInt32)
    @_specialize(exported: true, where T == UInt64)
    @_specialize(exported: true, where T == UInt)
    @inlinable
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
    @inline(always)
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
    @inline(always)
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
    @inline(always)
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
        for byte in value {
            bytes.append(byte)
        }
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
    @inline(always)
    mutating internal func align() {
        // skip over any remaining bits in the current byte
        endBitIndex = bytes.count * 8
    }
    
    @inlinable
    public mutating func finalize(crc: Bool = false) -> [UInt8] {
        let endBitIndex32 = UInt32(endBitIndex)
        withUnsafeBytes(of: endBitIndex32) {
            bytes[0] = $0[0]
            bytes[1] = $0[1]
            bytes[2] = $0[2]
            bytes[3] = $0[3]
        }
        if crc {
            let crc = bytes.crcChecksum
            withUnsafeBytes(of: crc) {
                bytes.append(contentsOf: $0)
            }
            //let crcChecksum = bytes.crcChecksum
            //append(crcChecksum)
        }
        return bytes
    }
}
