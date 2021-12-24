import XCTest
import SebbuBitStream
import Dispatch

final class SebbuBitStreamTests: XCTestCase {
    func testBenchmarking() throws {
        measure {
            var writeStream = WritableBitStream(size: 16)
            writeStream.append(163 as UInt64)
            writeStream.append(164 as UInt64)
            let packedData = writeStream.packBytes()
            var readStream = ReadableBitStream(bytes: packedData)
            let value1 = try! readStream.read() as UInt64
            let value2 = try! readStream.read() as UInt64
            if value1 | value2 == 0 {
                print("Hello")
            }
        }
    }
    
    func testUInt8Coding() throws {
        try test(lowerBound: UInt8.min, upperBound: .max)
    }
    
    func testUInt16Coding() throws {
        try test(lowerBound: UInt16.min, upperBound: .max)
    }
    
    func testUInt32Coding() throws {
        try self.test(lowerBound: 0, upperBound: UInt32.random(in: 5000 ... 1_000_000))
    }
    
    func testUInt64Coding() throws {
        try self.test(lowerBound: 0, upperBound: UInt64.random(in: 5000 ... 1_000_000))
    }
    
    func testUIntCoding() throws {
        try self.test(lowerBound: 0, upperBound: UInt.random(in: 5000 ... 1_000_000))
    }
    
    func testInt8Coding() throws {
        try test(lowerBound: Int8.min, upperBound: .max)
    }
    
    func testInt16Coding() throws {
        try test(lowerBound: Int16.min, upperBound: .max)
    }
    
    func testInt32Coding() throws {
        try self.test(lowerBound: Int32.random(in: -1_000_000 ... -5_000), upperBound: Int32.random(in: 5000 ... 1_000_000))
    }
    
    func testInt64Coding() throws {
        try self.test(lowerBound: Int64.random(in: -1_000_000 ... -5_000), upperBound: Int64.random(in: 5000 ... 1_000_000))
    }
    
    func testIntCoding() throws {
        try self.test(lowerBound: Int.random(in: -1_000_000 ... -5_000), upperBound: Int.random(in: 5000 ... 1_000_000))
    }
    
    func testComplexType() throws {
        let entity = Entity(uint8: 154, uint16: 8832, uint32: 718348123, uint64: 918239485, uint: 123895851, int8: -75, int16: -3423, int32: -234555, int64: -2345261462, int: -234692384, name: "My name is Oliver Quèen!", bool: true, ´enum´: .player, float: 1.02345, double: -1.2143525, bytes: [1,2,3,5,6,7,4,2,4,67,3,2,4,5,7,2,129], identifier: .init(), count: 88, uint8bits: 5, uint16bits: 17, uint32bits: 663, uint64bits: 235234, uintbits: 3233, uintBits999: 887, floatBits: -10, doubleBits: 99, bitArray: [1,2,3,5,6,7,4,6], boundedArray: [Packet(sequence: 1), Packet(sequence: 1), Packet(sequence: 1), Packet(sequence: 1)])
        var writeStream = WritableBitStream()
        entity.encode(to: &writeStream)
        var readStream = ReadableBitStream(bytes: writeStream.packBytes())
        let newEntity: Entity = try readStream.readObject()
        XCTAssertEqual(entity.uint8, newEntity.uint8)
        XCTAssertEqual(entity.uint16, newEntity.uint16)
        XCTAssertEqual(entity.uint32, newEntity.uint32)
        XCTAssertEqual(entity.uint64, newEntity.uint64)
        XCTAssertEqual(entity.uint, newEntity.uint)
        
        XCTAssertEqual(entity.int8, newEntity.int8)
        XCTAssertEqual(entity.int16, newEntity.int16)
        XCTAssertEqual(entity.int32, newEntity.int32)
        XCTAssertEqual(entity.int64, newEntity.int64)
        XCTAssertEqual(entity.int, newEntity.int)
        
        XCTAssertEqual(entity.name, newEntity.name)
        XCTAssertEqual(entity.bool, newEntity.bool)
        XCTAssertEqual(entity.´enum´, newEntity.´enum´)
        XCTAssertEqual(entity.float, newEntity.float)
        XCTAssertEqual(entity.double, newEntity.double)
        XCTAssertEqual(entity.bytes, newEntity.bytes)
        
        XCTAssertEqual(entity.identifier, newEntity.identifier)
        
        XCTAssertEqual(entity.uint8Bits, newEntity.uint8Bits)
        XCTAssertEqual(entity.uint16Bits, newEntity.uint16Bits)
        XCTAssertEqual(entity.uint32Bits, newEntity.uint32Bits)
        XCTAssertEqual(entity.uint64Bits, newEntity.uint64Bits)
        XCTAssertEqual(entity.uintBits, newEntity.uintBits)
        XCTAssertEqual(entity.uintBits999, newEntity.uintBits999)
        
        
        XCTAssert(abs(entity.floatBits - newEntity.floatBits) < 0.01)
        XCTAssert(abs(entity.doubleBits - newEntity.doubleBits) < 0.01)
        XCTAssertEqual(entity.bitArray, newEntity.bitArray)
        XCTAssertEqual(entity.boundedArray, newEntity.boundedArray)
        
    }
    
    private func test<T>(lowerBound: T, upperBound: T) throws where T: FixedWidthInteger {
        var writeStream = WritableBitStream()
        for i in lowerBound...upperBound {
            writeStream.append(i)
        }
        var readStream = ReadableBitStream(bytes: writeStream.packBytes())
        for i in lowerBound...upperBound {
            XCTAssertEqual(i, try readStream.read())
        }
    }
    
    private struct Packet: BitStreamCodable, Equatable {
        let sequence: UInt
        
        public init(sequence: UInt) {
            self.sequence = sequence
        }
        
        init(from bitStream: inout ReadableBitStream) throws {
            sequence = try bitStream.read()
        }
        
        func encode(to bitStream: inout WritableBitStream) {
            bitStream.append(sequence)
        }
    }
    
    private enum EntityType: UInt32, CaseIterable {
        case player
        case ai
        case cpu
        case robot
    }
    
    private struct Entity: BitStreamCodable {
        //MARK: Basic BitStream datatypes
        public let uint8: UInt8
        public let uint16: UInt16
        public let uint32: UInt32
        public let uint64: UInt64
        public let uint: UInt
        public let int8: Int8
        public let int16: Int16
        public let int32: Int32
        public let int64: Int64
        public let int: Int
        
        public let name: String
        public let bool: Bool
        public let ´enum´: EntityType
        public let float: Float
        public let double: Double
        public let bytes: [UInt8]
        
        //MARK: Custom bitStreamCodable
        public let identifier: UUID
        
        //MARK: BitDataTypes
        @BitSigned(min: -9900, max: 88245)
        public var count: Int
        
        @BitUnsigned(bits: 6)
        public var uint8Bits: UInt8
        @BitUnsigned(bits: 15)
        public var uint16Bits: UInt16
        @BitUnsigned(bits: 30)
        public var uint32Bits: UInt32
        @BitUnsigned(bits: 48)
        public var uint64Bits: UInt64
        @BitUnsigned(bits: 57)
        public var uintBits: UInt
        @BitUnsigned(maxValue: 999)
        public var uintBits999: UInt32
        
        @BitFloat(min: -1000, max: 1000, bits: 26)
        public var floatBits: Float
        
        @BitDouble(min: -1000.0, max: 1000.0, bits: 36)
        public var doubleBits: Double
        
        @BitArray(maxCount: 180, valueBits: 14)
        public var bitArray: [UInt16]
        
        @BoundedArray(maxCount: 16)
        public var boundedArray: [Packet]
        
        
        internal init(uint8: UInt8, uint16: UInt16, uint32: UInt32, uint64: UInt64, uint: UInt,
                      int8: Int8, int16: Int16, int32: Int32, int64: Int64, int: Int,
                      name: String, bool: Bool, ´enum´: SebbuBitStreamTests.EntityType,
                      float: Float, double: Double, bytes: [UInt8], identifier: UUID, count: Int, uint8bits: UInt8, uint16bits: UInt16, uint32bits: UInt32, uint64bits: UInt64, uintbits: UInt, uintBits999: UInt32,
                      floatBits: Float, doubleBits: Double, bitArray: [UInt16], boundedArray: [Packet]) {
            self.uint8 = uint8
            self.uint16 = uint16
            self.uint32 = uint32
            self.uint64 = uint64
            self.uint = uint
            self.int8 = int8
            self.int16 = int16
            self.int32 = int32
            self.int64 = int64
            self.int = int
            self.name = name
            self.bool = bool
            self.´enum´ = ´enum´
            self.float = float
            self.double = double
            self.bytes = bytes
            self.identifier = identifier
            self.count = count
            self.uint8Bits = uint8bits
            self.uint16Bits = uint16bits
            self.uint32Bits = uint32bits
            self.uint64Bits = uint64bits
            self.uintBits = uintbits
            self.uintBits999 = uintBits999
            self.floatBits = floatBits
            self.doubleBits = doubleBits
            self.bitArray = bitArray
            self.boundedArray = boundedArray
        }
            
        
        init(from bitStream: inout ReadableBitStream) throws {
            uint8 = try bitStream.read()
            uint16 = try bitStream.read()
            uint32 = try bitStream.read()
            uint64 = try bitStream.read()
            uint = try bitStream.read()
            int8 = try bitStream.read()
            int16 = try bitStream.read()
            int32 = try bitStream.read()
            int64 = try bitStream.read()
            int = try bitStream.read()
            name = try bitStream.read()
            bool = try bitStream.read()
            ´enum´ = try bitStream.read()
            float = try bitStream.read()
            double = try bitStream.read()
            bytes = try bitStream.read()
            identifier = try UUID(from: &bitStream)
            try bitStream.read(&_count)
            try bitStream.read(&_uint8Bits)
            try bitStream.read(&_uint16Bits)
            try bitStream.read(&_uint32Bits)
            try bitStream.read(&_uint64Bits)
            try bitStream.read(&_uintBits)
            try bitStream.read(&_uintBits999)
            try bitStream.read(&_floatBits)
            try bitStream.read(&_doubleBits)
            try bitStream.read(&_bitArray)
            try bitStream.read(&_boundedArray)
        }
        
        func encode(to bitStream: inout WritableBitStream) {
            bitStream.append(uint8)
            bitStream.append(uint16)
            bitStream.append(uint32)
            bitStream.append(uint64)
            bitStream.append(uint)
            bitStream.append(int8)
            bitStream.append(int16)
            bitStream.append(int32)
            bitStream.append(int64)
            bitStream.append(int)
            bitStream.append(name)
            bitStream.append(bool)
            bitStream.append(´enum´)
            bitStream.append(float)
            bitStream.append(double)
            bitStream.append(bytes)
            bitStream.appendObject(identifier)
            bitStream.append(_count)
            bitStream.append(_uint8Bits)
            bitStream.append(_uint16Bits)
            bitStream.append(_uint32Bits)
            bitStream.append(_uint64Bits)
            bitStream.append(_uintBits)
            bitStream.append(_uintBits999)
            bitStream.append(_floatBits)
            bitStream.append(_doubleBits)
            bitStream.append(_bitArray)
            bitStream.append(_boundedArray)
        }
    }
}
