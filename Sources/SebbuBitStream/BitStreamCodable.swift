//
//  BitStreamCodable.swift
//
//  Created by Sebastian Toivonen on 8.8.2021.
//
//  Copyright © 2021 Sebastian Toivonen. All rights reserved.
import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

public protocol BitStreamEncodable {
    func encode(to bitStream: inout WritableBitStream)
}

public protocol BitStreamDecodable {
    init(from bitStream: inout ReadableBitStream) throws
}

/// - Tag: BitStreamCodable
public typealias BitStreamCodable = BitStreamEncodable & BitStreamDecodable

public extension BitStreamEncodable where Self: Encodable {
    func encode(to bitStream: inout WritableBitStream) {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        if let data = try? encoder.encode(self) {
            bitStream.append(data)
        } else {
            print("Failed to encode Encodable data...", #file, #line)
        } //TODO: Maybe just forget about this extension all together
    }
}

public extension BitStreamDecodable where Self: Decodable {
    init(from bitStream: inout ReadableBitStream) throws {
        let data: Data = try bitStream.read()
        let decoder = PropertyListDecoder()
        self = try decoder.decode(Self.self, from: data)
    }
}

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

extension CGFloat: BitStreamCodable {
    public init(from bitStream: inout ReadableBitStream) throws {
        self = try bitStream.read()
    }
    
    @inline(__always)
    public func encode(to bitStream: inout WritableBitStream) {
        bitStream.append(self)
    }
}