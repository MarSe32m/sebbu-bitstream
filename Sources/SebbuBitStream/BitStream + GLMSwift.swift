//
//  BitStream + GLMSwift.swift
//  
//
//  Created by Sebastian Toivonen on 8.8.2021.
//
/*
import GLMSwift

@propertyWrapper
public struct BitVector2<T: BinaryFloatingPoint & SIMDScalar> {
    public var wrappedValue: Vector2<T> = Vector2(x: 0, y: 0)
    public let minValue: T
    public let maxValue: T
    public let bits: Int
    
    public init(minValue: T, maxValue: T, bits: Int) {
        self.minValue = minValue
        self.maxValue = maxValue
        self.bits = bits
    }
}

@propertyWrapper
public struct BitVector3<T: BinaryFloatingPoint & SIMDScalar> {
    public var wrappedValue: Vector3<T> = Vector3(x: 0, y: 0)
    public let minValue: T
    public let maxValue: T
    public let bits: Int
    
    public init(minValue: T, maxValue: T, bits: Int) {
        self.minValue = minValue
        self.maxValue = maxValue
        self.bits = bits
    }
}

@propertyWrapper
public struct BitVector4<T: BinaryFloatingPoint & SIMDScalar> {
    public var wrappedValue: Vector4<T> = Vector4(x: 0, y: 0)
    public let minValue: T
    public let maxValue: T
    public let bits: Int
    
    public init(minValue: T, maxValue: T, bits: Int) {
        self.minValue = minValue
        self.maxValue = maxValue
        self.bits = bits
    }
}

//TODO: BitMatrix2, BitMatrix3, BitMatrix4

public extension WritableBitStream {
    @inlinable
    mutating func append(_ value: BitVector2<Float>) {
        let floatCompressor = FloatCompressor(minValue: value.minValue, maxValue: value.maxValue, bits: value.bits)
        floatCompressor.write(value.wrappedValue, to: &self)
    }

    @inlinable
    mutating func append(_ value: BitVector3<Float>) {
        let floatCompressor = FloatCompressor(minValue: value.minValue, maxValue: value.maxValue, bits: value.bits)
        floatCompressor.write(value.wrappedValue, to: &self)
    }
    
    @inlinable
    mutating func append(_ value: BitVector4<Float>) {
        let floatCompressor = FloatCompressor(minValue: value.minValue, maxValue: value.maxValue, bits: value.bits)
        floatCompressor.write(value.wrappedValue, to: &self)
    }
    
    @inlinable
    mutating func append(_ value: BitVector2<Double>) {
        let doubleCompressor = DoubleCompressor(minValue: value.minValue, maxValue: value.maxValue, bits: value.bits)
        doubleCompressor.write(value.wrappedValue, to: &self)
    }

    @inlinable
    mutating func append(_ value: BitVector3<Double>) {
        let doubleCompressor = DoubleCompressor(minValue: value.minValue, maxValue: value.maxValue, bits: value.bits)
        doubleCompressor.write(value.wrappedValue, to: &self)
    }
    
    @inlinable
    mutating func append(_ value: BitVector4<Double>) {
        let doubleCompressor = DoubleCompressor(minValue: value.minValue, maxValue: value.maxValue, bits: value.bits)
        doubleCompressor.write(value.wrappedValue, to: &self)
    }
    
    //TODO: BitMatrix2, BitMatrix3, BitMatrix4 encoding
    
    @inlinable
    mutating func append(_ value: Vector2<Float>) {
        append(value.x)
        append(value.y)
    }
    
    @inlinable
    mutating func append(_ value: Vector2<Double>) {
        append(value.x)
        append(value.y)
    }
    
    @inlinable
    mutating func append(_ value: Vector3<Float>) {
        append(value.x)
        append(value.y)
        append(value.z)
    }
    
    @inlinable
    mutating func append(_ value: Vector3<Double>) {
        append(value.x)
        append(value.y)
        append(value.z)
    }
    
    @inlinable
    mutating func append(_ value: Vector4<Float>) {
        append(value.x)
        append(value.y)
        append(value.z)
        append(value.w)
    }
    
    @inlinable
    mutating func append(_ value: Vector4<Double>) {
        append(value.x)
        append(value.y)
        append(value.z)
        append(value.w)
    }
}

public extension ReadableBitStream {
    @inlinable
    mutating func read(_ value: inout BitVector2<Float>) throws {
        let floatComperssor = FloatCompressor(minValue: value.minValue, maxValue: value.maxValue, bits: value.bits)
        value.wrappedValue = try floatComperssor.read(from: &self)
    }
    
    @inlinable
    mutating func read(_ value: inout BitVector3<Float>) throws {
        let floatComperssor = FloatCompressor(minValue: value.minValue, maxValue: value.maxValue, bits: value.bits)
        value.wrappedValue = try floatComperssor.read(from: &self)
    }
    
    @inlinable
    mutating func read(_ value: inout BitVector4<Float>) throws {
        let floatComperssor = FloatCompressor(minValue: value.minValue, maxValue: value.maxValue, bits: value.bits)
        value.wrappedValue = try floatComperssor.read(from: &self)
    }
    
    @inlinable
    mutating func read(_ value: inout BitVector2<Double>) throws {
        let doubleComperssor = DoubleCompressor(minValue: value.minValue, maxValue: value.maxValue, bits: value.bits)
        value.wrappedValue = try doubleComperssor.read(from: &self)
    }
    
    @inlinable
    mutating func read(_ value: inout BitVector3<Double>) throws {
        let doubleComperssor = DoubleCompressor(minValue: value.minValue, maxValue: value.maxValue, bits: value.bits)
        value.wrappedValue = try doubleComperssor.read(from: &self)
    }
    
    @inlinable
    mutating func read(_ value: inout BitVector4<Double>) throws {
        let doubleComperssor = DoubleCompressor(minValue: value.minValue, maxValue: value.maxValue, bits: value.bits)
        value.wrappedValue = try doubleComperssor.read(from: &self)
    }
    
    //TODO: BitMatrix2, BitMatrix3, BitMatrix4 decoding
    
    @inlinable
    mutating func read() throws -> Vector2<Float> {
        Vector2<Float>(try read(), try read())
    }
    
    @inlinable
    mutating func read() throws -> Vector2<Double> {
        Vector2<Double>(try read(), try read())
    }
    
    @inlinable
    mutating func read() throws -> Vector3<Float> {
        Vector3<Float>(try read(), try read(), try read())
    }
    
    @inlinable
    mutating func read() throws -> Vector3<Double> {
        Vector3<Double>(try read(), try read(), try read())
    }
    
    @inlinable
    mutating func read() throws -> Vector4<Float> {
        Vector4<Float>(try read(), try read(), try read(), try read())
    }
    
    @inlinable
    mutating func read() throws -> Vector4<Double> {
        Vector4<Double>(try read(), try read(), try read(), try read())
    }
}

public extension FloatCompressor {
    @inlinable
    func write(_ value: Vector2<Float>, to bitStream: inout WritableBitStream) {
        write(value.x, to: &bitStream)
        write(value.y, to: &bitStream)
    }
    
    @inlinable
    func read(from bitStream: inout ReadableBitStream) throws -> Vector2<Float> {
        Vector2(x: try read(from: &bitStream), y: try read(from: &bitStream))
    }
    
    @inlinable
    func write(_ value: Vector3<Float>, to bitStream: inout WritableBitStream) {
        write(value.x, to: &bitStream)
        write(value.y, to: &bitStream)
        write(value.z, to: &bitStream)
    }
    
    @inlinable
    func read(from bitStream: inout ReadableBitStream) throws -> Vector3<Float> {
        Vector3(x: try read(from: &bitStream), y: try read(from: &bitStream), z: try read(from: &bitStream))
    }
    
    @inlinable
    func write(_ value: Vector4<Float>, to bitStream: inout WritableBitStream) {
        write(value.x, to: &bitStream)
        write(value.y, to: &bitStream)
        write(value.z, to: &bitStream)
        write(value.w, to: &bitStream)
    }
    
    @inlinable
    func read(from bitStream: inout ReadableBitStream) throws -> Vector4<Float> {
        Vector4(x: try read(from: &bitStream), y: try read(from: &bitStream), z: try read(from: &bitStream), w: try read(from: &bitStream))
    }
}

public extension DoubleCompressor {
    @inlinable
    func write(_ value: Vector2<Double>, to bitStream: inout WritableBitStream) {
        write(value.x, to: &bitStream)
        write(value.y, to: &bitStream)
    }
    
    @inlinable
    func read(from bitStream: inout ReadableBitStream) throws -> Vector2<Double> {
        Vector2(x: try read(from: &bitStream), y: try read(from: &bitStream))
    }
    
    @inlinable
    func write(_ value: Vector3<Double>, to bitStream: inout WritableBitStream) {
        write(value.x, to: &bitStream)
        write(value.y, to: &bitStream)
        write(value.z, to: &bitStream)
    }
    
    @inlinable
    func read(from bitStream: inout ReadableBitStream) throws -> Vector3<Double> {
        Vector3(x: try read(from: &bitStream), y: try read(from: &bitStream), z: try read(from: &bitStream))
    }
    
    @inlinable
    func write(_ value: Vector4<Double>, to bitStream: inout WritableBitStream) {
        write(value.x, to: &bitStream)
        write(value.y, to: &bitStream)
        write(value.z, to: &bitStream)
        write(value.w, to: &bitStream)
    }
    
    @inlinable
    func read(from bitStream: inout ReadableBitStream) throws -> Vector4<Double> {
        Vector4(x: try read(from: &bitStream), y: try read(from: &bitStream), z: try read(from: &bitStream), w: try read(from: &bitStream))
    }
}
*/