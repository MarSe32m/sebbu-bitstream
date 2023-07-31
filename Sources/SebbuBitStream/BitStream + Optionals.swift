//
//  BitStream + Optionals.swift
//  
//
//  Created by Sebastian Toivonen on 23.7.2023.
//

public extension WritableBitStream {
    /// Append an optional boolean value to the stream.
    @inlinable
    mutating func append(_ value: Bool?) {
        append(value != nil)
        if let value = value {
            append(value)
        }
    }
    
    /// Append an optional boolean array value to the stream.
    @inlinable
    mutating func append(_ value: [Bool]?, maxCount: Int = 1 << 29) {
        append(value != nil)
        if let value = value {
            append(value, maxCount: maxCount)
        }
    }
    
    /// Append an optional fixed width integer value to the stream.
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
    mutating func append<T>(_ value: T?) where T: FixedWidthInteger {
        append(value != nil)
        if let value = value {
            append(value)
        }
    }
    
    /// Append an optional fixed width integer value to the stream.
    @inlinable
    mutating func append<T>(_ value: [T]?, maxCount: Int = 1 << 29) where T: FixedWidthInteger {
        append(value != nil)
        if let value = value {
            append(value, maxCount: maxCount)
        }
    }
    
    /// Append an optional unsigned integer value to the stream with a given number of bits used to encoding.
    @_specialize(exported: true, where T == UInt8)
    @_specialize(exported: true, where T == UInt16)
    @_specialize(exported: true, where T == UInt32)
    @_specialize(exported: true, where T == UInt64)
    @_specialize(exported: true, where T == UInt)
    @inlinable
    mutating func append<T>(_ value: T?, numberOfBits: Int) where T: UnsignedInteger {
        append(value != nil)
        if let value = value {
            append(value, numberOfBits: numberOfBits)
        }
    }
    
    /// Append an optional enum value to the stream.
    @inlinable
    mutating func append<T>(_ value: T?) where T: CaseIterable & RawRepresentable, T.RawValue == UInt32 {
        append(value != nil)
        if let value = value {
            append(value)
        }
    }
    
    /// Append an optional enum value to the stream.
    @inlinable
    mutating func append<T>(_ value: [T]?, maxCount: Int = 1 << 29) where T: CaseIterable & RawRepresentable, T.RawValue == UInt32 {
        append(value != nil)
        if let value = value {
            append(value, maxCount: maxCount)
        }
    }
    
    /// Append an optional float value to the stream.
    @inlinable
    mutating func append(_ value: Float?) {
        append(value != nil)
        if let value = value {
            append(value)
        }
    }
    
    /// Append an optional float value to the stream.
    @inlinable
    mutating func append(_ value: [Float]?, maxCount: Int = 1 << 29) {
        append(value != nil)
        if let value = value {
            append(value, maxCount: maxCount)
        }
    }
    
    /// Append an optional double value to the stream.
    @inlinable
    mutating func append(_ value: Double?) {
        append(value != nil)
        if let value = value {
            append(value)
        }
    }
    
    /// Append an optional double value to the stream.
    @inlinable
    mutating func append(_ value: [Double]?, maxCount: Int = 1 << 29) {
        append(value != nil)
        if let value = value {
            append(value, maxCount: maxCount)
        }
    }
    
    /// Append an optional UTF8 encoded string to the stream.
    @inlinable
    mutating func append(_ value: String?) {
        append(value != nil)
        if let value = value {
            append(value)
        }
    }
    
    /// Append an optional UTF8 encoded string to the stream.
    @inlinable
    mutating func append(_ value: [String]?, maxCount: Int = 1 << 29) {
        append(value != nil)
        if let value = value {
            append(value, maxCount: maxCount)
        }
    }
    
    /// Append an optional buffer of bytes to the stream.
    @inlinable
    mutating func appendBytes(_ value: [UInt8]?) {
        append(value != nil)
        if let value = value {
            appendBytes(value)
        }
    }
}

public extension ReadableBitStream {
    /// Read an optional boolean value
    ///
    /// - Returns: Boolean value or `nil` if the encoded value was a value or nil respectively
    @inlinable
    mutating func read() throws -> Bool? {
        let hasValue = try read() as Bool
        return hasValue ? try read() as Bool : nil
    }
    
    /// Read an optional boolean value
    ///
    /// - Returns: Boolean value or `nil` if the encoded value was a value or nil respectively
    @inlinable
    mutating func read(maxCount: Int = 1 << 29) throws -> [Bool]? {
        let hasValue = try read() as Bool
        return hasValue ? try read(maxCount: maxCount) as [Bool] : nil
    }
    
    /// Read an optional fixed width integer value
    ///
    /// - Returns: Fixed width integer value or `nil` if the encoded value was a value or nil respectively
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
    mutating func read<T>() throws -> T? where T: FixedWidthInteger {
        let hasValue = try read() as Bool
        return hasValue ? try read() as T : nil
    }
    
    /// Read an optional fixed width integer value
    ///
    /// - Returns: Fixed width integer value or `nil` if the encoded value was a value or nil respectively
    @inlinable
    mutating func read<T>(maxCount: Int = 1 << 29) throws -> [T]? where T: FixedWidthInteger {
        let hasValue = try read() as Bool
        return hasValue ? try read(maxCount: maxCount) as [T] : nil
    }
    
    /// Read an optional unsigned integer value with a given number of bits.
    ///
    /// - Returns: Unsigned integer value or `nil` if the encoded value was a value or nil respectively
    @_specialize(exported: true, where T == UInt8)
    @_specialize(exported: true, where T == UInt16)
    @_specialize(exported: true, where T == UInt32)
    @_specialize(exported: true, where T == UInt64)
    @_specialize(exported: true, where T == UInt)
    @inlinable
    mutating func read<T>(numberOfBits: Int) throws -> T? where T: UnsignedInteger {
        let hasValue = try read() as Bool
        return hasValue ? try read(numberOfBits: numberOfBits) as T : nil
    }
    
    /// Read an optional enum value
    ///
    /// - Returns: Enum value or `nil` if the encoded value was a value or nil respectively
    @inlinable
    mutating func read<T>() throws -> T? where T: CaseIterable & RawRepresentable, T.RawValue == UInt32 {
        let hasValue = try read() as Bool
        return hasValue ? try read() as T : nil
    }
    
    /// Read an optional enum value
    ///
    /// - Returns: Enum value or `nil` if the encoded value was a value or nil respectively
    @inlinable
    mutating func read<T>(maxCount: Int = 1 << 29) throws -> [T]? where T: CaseIterable & RawRepresentable, T.RawValue == UInt32 {
        let hasValue = try read() as Bool
        return hasValue ? try read(maxCount: maxCount) as [T] : nil
    }
    
    /// Read an optional float value
    ///
    /// - Returns: Float value or `nil` if the encoded value was a value or nil respectively
    @inlinable
    mutating func read() throws -> Float? {
        let hasValue = try read() as Bool
        return hasValue ? try read() as Float : nil
    }
    
    /// Read an optional float value
    ///
    /// - Returns: Float value or `nil` if the encoded value was a value or nil respectively
    @inlinable
    mutating func read(maxCount: Int = 1 << 29) throws -> [Float]? {
        let hasValue = try read() as Bool
        return hasValue ? try read(maxCount: maxCount) as [Float] : nil
    }
    
    /// Read an optional double value
    ///
    /// - Returns: Double value or `nil` if the encoded value was a value or nil respectively
    @inlinable
    mutating func read() throws -> Double? {
        let hasValue = try read() as Bool
        return hasValue ? try read() as Double : nil
    }
    
    /// Read an optional double value
    ///
    /// - Returns: Double value or `nil` if the encoded value was a value or nil respectively
    @inlinable
    mutating func read(maxCount: Int = 1 << 29) throws -> [Double]? {
        let hasValue = try read() as Bool
        return hasValue ? try read(maxCount: maxCount) as [Double] : nil
    }
    
    /// Read an optional  UTF8 encoded string
    ///
    /// - Returns: UTF8 encoded string or `nil` if the encoded value was a value or nil respectively
    @inlinable
    mutating func read() throws -> String? {
        let hasValue = try read() as Bool
        return hasValue ? try read() as String : nil
    }
    
    /// Read an optional  UTF8 encoded string
    ///
    /// - Returns: The array of UTF8 encoded strings or `nil`
    @inlinable
    mutating func read(maxCount: Int = 1 << 29) throws -> [String]? {
        let hasValue = try read() as Bool
        return hasValue ? try read(maxCount: maxCount) as [String] : nil
    }
    
    /// Read an optional buffer of bytes.
    ///
    /// - Returns: Buffer of bytes or `nil` if the encoded value was a value or nil respectively
    @inlinable
    mutating func readBytes() throws -> [UInt8]? {
        let hasValue = try read() as Bool
        return hasValue ? try readBytes() as [UInt8] : nil
    }
}

extension Optional: BitStreamDecodable where Wrapped: BitStreamDecodable {
    public init(from bitStream: inout ReadableBitStream) throws {
        let hasValue = try bitStream.read() as Bool
        self = hasValue ? .some(try bitStream.read() as Wrapped) : .none
    }
}

extension Optional: BitStreamEncodable where Wrapped: BitStreamEncodable {
    @inline(__always)
    public func encode(to bitStream: inout WritableBitStream) {
        switch self {
        case .some(let wrapped):
            bitStream.append(true)
            bitStream.append(wrapped)
        case .none:
            bitStream.append(false)
        }
    }
}
