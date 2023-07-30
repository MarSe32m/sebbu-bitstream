//
//  BitStreamCodable.swift
//
//  Created by Sebastian Toivonen on 8.8.2021.
//
//  Copyright © 2021 Sebastian Toivonen. All rights reserved.

/// A type that can encode itself into a bit stream representation.
public protocol BitStreamEncodable {
    /// Encode the type into the bit stream
    func encode(to bitStream: inout WritableBitStream)
}

/// A type that can decode itself from a bit stream representation.
public protocol BitStreamDecodable {
    init(from bitStream: inout ReadableBitStream) throws
}

/// A type that can convert itself into and out of a bit stream representation.
public typealias BitStreamCodable = BitStreamEncodable & BitStreamDecodable

public extension WritableBitStream {
    /// Encode a `BitStreamEncodable` object.
    ///
    /// - Parameter value: The `BitStreamEncodable` object to encode.
    ///
    /// - Complexity: O(1)
    @inlinable
    @inline(__always)
    mutating func append<T>(_ value: T) where T: BitStreamEncodable {
        value.encode(to: &self)
    }
    
    /// Encode an optional `BitStreamEncodable` object.
    ///
    /// - Parameter value: The `BitStreamEncodable` object to encode.
    ///
    /// - Complexity: O(1)
    @inlinable
    @inline(__always)
    mutating func append<T>(_ value: T?) where T: BitStreamEncodable {
        value.encode(to: &self)
    }
    
    /// Encode an array of `BitStreamEncodable` objects
    ///
    /// - Parameter array: The array of `BitStreamEncodable` objects to encode.
    ///
    /// - Note: This encodes the length of the array with 29 bits. Thus the array must contain less than 2^29 objects.
    ///
    /// - Complexity: O(n)
    @inlinable
    @inline(__always)
    mutating func append<T>(_ array: [T], maxCount: Int = 1 << 29) where T: BitStreamEncodable {
        assert(maxCount <= 1 << 29, "The maximum count of the array must be less than 2^29")
        assert(maxCount > 0, "The maximum count must be more than zero")
        let countBits = UInt64.bitWidth - maxCount.leadingZeroBitCount
        append(UInt32(array.count), numberOfBits: countBits)
        for element in array {
            append(element)
        }
    }
    
    /// Encode an array of `BitStreamEncodable` objects
    ///
    /// - Parameter array: The array of `BitStreamEncodable` objects to encode.
    ///
    /// - Note: This encodes the length of the array with 29 bits. Thus the array must contain less than 2^29 objects.
    ///
    /// - Complexity: O(n)
    @inlinable
    @inline(__always)
    mutating func append<T>(_ array: [T]?, maxCount: Int = 1 << 29) where T: BitStreamEncodable {
        append(array != nil)
        guard let array = array else { return }
        assert(maxCount <= 1 << 29, "The maximum count of the array must be less than 2^29")
        assert(maxCount > 0, "The maximum count must be more than zero")
        let countBits = UInt64.bitWidth - maxCount.leadingZeroBitCount
        append(UInt32(array.count), numberOfBits: countBits)
        for element in array {
            append(element)
        }
    }
    
    /// Encode an array of optional `BitStreamEncodable` objects
    ///
    /// - Parameter array: The array of `BitStreamEncodable` objects to encode.
    ///
    /// - Note: This encodes the length of the array with 29 bits. Thus the array must contain less than 2^29 objects.
    ///
    /// - Complexity: O(n)
    @inlinable
    @inline(__always)
    mutating func append<T>(_ array: [T?], maxCount: Int = 1 << 29) where T: BitStreamEncodable {
        assert(maxCount <= 1 << 29, "The maximum count of the array must be less than 2^29")
        assert(maxCount > 0, "The maximum count must be more than zero")
        let countBits = UInt64.bitWidth - maxCount.leadingZeroBitCount
        append(UInt32(array.count), numberOfBits: countBits)
        for element in array {
            append(element)
        }
    }
}

public extension ReadableBitStream {
    /// Decode a `BitStreamCodable` object
    ///
    /// To specify the type that is read, either use type inference or specify the type using casting
    ///  ```
    /// var stream = ReadableBitStream(bytes: bytes)
    /// let packet: YourPacket = try stream.read()
    /// let object = try stream.read() as YourObjectType
    ///  ```
    @inlinable
    @inline(__always)
    mutating func read<T>() throws -> T where T: BitStreamDecodable {
        return try T(from: &self)
    }
    
    /// Decode an array of `BitStreamCodable` objects
    ///
    /// To specify the type that is read, either use type inference or specify the type using casting
    ///  ```
    /// var stream = ReadableBitStream(bytes: bytes)
    /// let array: [Packet] = try stream.read()
    /// let otherArray = try stream.read() as [Message]
    ///  ```
    @inlinable
    @inline(__always)
    mutating func read<T>(maxCount: Int = 1 << 29) throws -> [T] where T: BitStreamDecodable {
        assert(maxCount <= 1 << 29, "The maximum count of the array must be less than 2^29")
        assert(maxCount > 0, "The maximum count must be more than zero")
        let countBits = UInt64.bitWidth - maxCount.leadingZeroBitCount
        let count = Int(try read(numberOfBits: countBits) as UInt32)
        var array: [T] = []
        if count == 0 { return array }
        array.reserveCapacity(count)
        for _ in 0..<count {
            array.append(try read())
        }
        return array
    }
    
    /// Decode an array of `BitStreamCodable` objects
    ///
    /// To specify the type that is read, either use type inference or specify the type using casting
    ///  ```
    /// var stream = ReadableBitStream(bytes: bytes)
    /// let array: [Packet] = try stream.read()
    /// let otherArray = try stream.read() as [Message]
    ///  ```
    @inlinable
    @inline(__always)
    mutating func read<T>(maxCount: Int = 1 << 29) throws -> [T]? where T: BitStreamDecodable {
        guard try read() as Bool else { return nil }
        assert(maxCount <= 1 << 29, "The maximum count of the array must be less than 2^29")
        assert(maxCount > 0, "The maximum count must be more than zero")
        let countBits = UInt64.bitWidth - maxCount.leadingZeroBitCount
        let count = Int(try read(numberOfBits: countBits) as UInt32)
        var array: [T] = []
        if count == 0 { return array }
        array.reserveCapacity(count)
        for _ in 0..<count {
            array.append(try read())
        }
        return array
    }
}

@available(*, unavailable)
extension Bool: BitStreamCodable {
    public func encode(to bitStream: inout WritableBitStream) {
        fatalError("Bool conformance of BitStreamEncodable is unavailable")
    }
    
    public init(from bitStream: inout ReadableBitStream) throws {
        fatalError("Bool conformance of BitStreamDecodable is unavailable")
    }
}

@available(*, unavailable)
extension UInt8: BitStreamCodable {
    public func encode(to bitStream: inout WritableBitStream) {
        fatalError("UInt8 conformance of BitStreamEncodable is unavailable")
    }
    
    public init(from bitStream: inout ReadableBitStream) throws {
        fatalError("UInt8 conformance of BitStreamDecodable is unavailable")
    }
}

@available(*, unavailable)
extension UInt16: BitStreamCodable {
    public func encode(to bitStream: inout WritableBitStream) {
        fatalError("UInt16 conformance of BitStreamEncodable is unavailable")
    }
    
    public init(from bitStream: inout ReadableBitStream) throws {
        fatalError("UInt16 conformance of BitStreamDecodable is unavailable")
    }
}

@available(*, unavailable)
extension UInt32: BitStreamCodable {
    public func encode(to bitStream: inout WritableBitStream) {
        fatalError("UInt32 conformance of BitStreamEncodable is unavailable")
    }
    
    public init(from bitStream: inout ReadableBitStream) throws {
        fatalError("UInt32 conformance of BitStreamDecodable is unavailable")
    }
}

@available(*, unavailable)
extension UInt64: BitStreamCodable {
    public func encode(to bitStream: inout WritableBitStream) {
        fatalError("UInt64 conformance of BitStreamEncodable is unavailable")
    }
    
    public init(from bitStream: inout ReadableBitStream) throws {
        fatalError("UInt64 conformance of BitStreamDecodable is unavailable")
    }
}

@available(*, unavailable)
extension UInt: BitStreamCodable {
    public func encode(to bitStream: inout WritableBitStream) {
        fatalError("UInt conformance of BitStreamEncodable is unavailable")
    }
    
    public init(from bitStream: inout ReadableBitStream) throws {
        fatalError("UInt conformance of BitStreamDecodable is unavailable")
    }
}

@available(*, unavailable)
extension Int8: BitStreamCodable {
    public func encode(to bitStream: inout WritableBitStream) {
        fatalError("Int8 conformance of BitStreamEncodable is unavailable")
    }
    
    public init(from bitStream: inout ReadableBitStream) throws {
        fatalError("Int8 conformance of BitStreamDecodable is unavailable")
    }
}

@available(*, unavailable)
extension Int16: BitStreamCodable {
    public func encode(to bitStream: inout WritableBitStream) {
        fatalError("Int16 conformance of BitStreamEncodable is unavailable")
    }
    
    public init(from bitStream: inout ReadableBitStream) throws {
        fatalError("Int16 conformance of BitStreamDecodable is unavailable")
    }
}

@available(*, unavailable)
extension Int32: BitStreamCodable {
    public func encode(to bitStream: inout WritableBitStream) {
        fatalError("Int32 conformance of BitStreamEncodable is unavailable")
    }
    
    public init(from bitStream: inout ReadableBitStream) throws {
        fatalError("Int32 conformance of BitStreamDecodable is unavailable")
    }
}

@available(*, unavailable)
extension Int64: BitStreamCodable {
    public func encode(to bitStream: inout WritableBitStream) {
        fatalError("Int64 conformance of BitStreamEncodable is unavailable")
    }
    
    public init(from bitStream: inout ReadableBitStream) throws {
        fatalError("Int64 conformance of BitStreamDecodable is unavailable")
    }
}

@available(*, unavailable)
extension Int: BitStreamCodable {
    public func encode(to bitStream: inout WritableBitStream) {
        fatalError("Int conformance of BitStreamEncodable is unavailable")
    }
    
    public init(from bitStream: inout ReadableBitStream) throws {
        fatalError("Int conformance of BitStreamDecodable is unavailable")
    }
}

@available(*, unavailable)
extension Float: BitStreamCodable {
    public init(from bitStream: inout ReadableBitStream) throws {
        fatalError("Float conformance to BitStreamDecodable is unavailable")
    }

    public func encode(to bitStream: inout WritableBitStream) {
        fatalError("Float conformance to BitStreamEncodable is unavailable")
    }
}

@available(*, unavailable)
extension Double: BitStreamCodable {
    public init(from bitStream: inout ReadableBitStream) throws {
        fatalError("Double conformance to BitStreamDecodable is unavailable")
    }

    public func encode(to bitStream: inout WritableBitStream) {
        fatalError("Double conformance to BitStreamEncodable is unavailable")
    }
}

@available(*, unavailable)
extension String: BitStreamCodable {
    public init(from bitStream: inout ReadableBitStream) throws {
        fatalError("String conformance to BitStreamDecodable is unavailable")
    }

    public func encode(to bitStream: inout WritableBitStream) {
        fatalError("String conformance to BitStreamEncodable is unavailable")
    }
}
