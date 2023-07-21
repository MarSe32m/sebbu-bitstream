//
//  BitStreamCodable.swift
//
//  Created by Sebastian Toivonen on 8.8.2021.
//
//  Copyright © 2021 Sebastian Toivonen. All rights reserved.

public protocol BitStreamEncodable {
    func encode(to bitStream: inout WritableBitStream)
}

public protocol BitStreamDecodable {
    init(from bitStream: inout ReadableBitStream) throws
}

/// - Tag: BitStreamCodable
public typealias BitStreamCodable = BitStreamEncodable & BitStreamDecodable

extension String {
    public init(from bitStream: inout ReadableBitStream) throws {
        self = try bitStream.read()
    }

    public func encode(to bitStream: inout WritableBitStream) {
        bitStream.append(self)
    }
}

extension Array where Element == UInt8 {
    public init(from bitStream: inout ReadableBitStream) throws {
        self = try bitStream.read()
    }
    
    @inlinable
    public func encode(to bitStream: inout WritableBitStream) {
        bitStream.append(self)
    }
}

extension Array where Element: BitStreamCodable {
    public init(from bitStream: inout ReadableBitStream) throws {
        let count = try bitStream.read() as Int
        var result = [Element]()
        for _ in 0..<count {
            result.append(try Element(from: &bitStream))
        }
        self = result
    }
    
    @inlinable
    public func encode(to bitStream: inout WritableBitStream) {
        bitStream.append(count)
        for element in self {
            element.encode(to: &bitStream)
        }
    }
}