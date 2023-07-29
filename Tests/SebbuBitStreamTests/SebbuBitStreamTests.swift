import XCTest
import SebbuBitStream
import SebbuBitStreamFoundation
import Foundation

final class SebbuBitStreamTests: XCTestCase {
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
        let entity = Entity(uint8: .random(in: .min ... .max), uint16: .random(in: .min ... .max), uint32: .random(in: .min ... .max),
                            uint64: .random(in: .min ... .max), uint: .random(in: .min ... .max), int8: .random(in: .min ... .max),
                            int16: .random(in: .min ... .max), int32: .random(in: .min ... .max), int64: .random(in: .min ... .max),
                            int: .random(in: .min ... .max), name: "My name is Oliver Quèen!", bool: .random(), ´enum´: .random(),
                            float: .random(in: -10000...10000), double: .random(in: -100000...100000),
                            bytes: (0..<Int.random(in: 128...1024)).map {_ in UInt8.random(in: .min ... .max) },
                            identifier: .init(),
                            packets: (0..<15).map {_ in .random() },
                            uint8Opt: Bool.random() ? nil : .random(in: .min ... .max),
                            uint16Opt: Bool.random() ? nil : .random(in: .min ... .max),
                            uint32Opt: Bool.random() ? nil : .random(in: .min ... .max),
                            uint64Opt: Bool.random() ? nil : .random(in: .min ... .max),
                            uintOpt: Bool.random() ? nil : .random(in: .min ... .max),
                            int8Opt: Bool.random() ? nil : .random(in: .min ... .max),
                            int16Opt: Bool.random() ? nil : .random(in: .min ... .max),
                            int32Opt: Bool.random() ? nil : .random(in: .min ... .max),
                            int64Opt: Bool.random() ? nil : .random(in: .min ... .max),
                            intOpt: Bool.random() ? nil : .random(in: .min ... .max),
                            nameOpt: Bool.random() ? nil : "My name is again Oliver Quèen!",
                            boolOpt: Bool.random() ? nil : Bool.random(),
                            enumOpt: Bool.random() ? nil : .random(),
                            floatOpt: Bool.random() ? nil : .random(in: -10000...10000),
                            doubleOpt: Bool.random() ? nil : .random(in: -100000...100000),
                            bytesOpt: Bool.random() ? nil : (0..<Int.random(in: 16...199)).map {_ in UInt8.random(in: .min ... .max) },
                            identifierOpt: Bool.random() ? nil : .init(),
                            packetsOpt: Bool.random() ? nil : (0...120).map {_ in .random() },
                            packetsAreOpt: (0...120).map {_ in Bool.random() ? nil : .random() },
                            count: 88, uint8bits: 5, uint16bits: 17, uint32bits: 663, uint64bits: 235234,
                            uintbits: 3233, uintBits999: 887, floatBits: -10, doubleBits: 99, bitArray: [1,2,3,5,6,7,4,6],
                            boundedArray: [Packet(sequence: 1), Packet(sequence: 1), Packet(sequence: 1), Packet(sequence: 1)])
        var writeStream = WritableBitStream()
        entity.encode(to: &writeStream)
        var readStream = ReadableBitStream(bytes: writeStream.packBytes())
        var newEntity: Entity = try readStream.read()
        try assert(entity: entity, newEntity: newEntity)
        
        writeStream = WritableBitStream()
        entity.encode(to: &writeStream)
        readStream = try ReadableBitStream(bytes: writeStream.packBytes(withCrc: true), crcValidated: true)
        newEntity = try readStream.read()
        try assert(entity: entity, newEntity: newEntity)
    }
    
    func testIntCompressor() throws {
        var writeStream = WritableBitStream()
        try _testIntCompressor(lowerBound: 0, upperBound: 1, writeStream: &writeStream)
        
        try _testIntCompressor(lowerBound: Int(Int8.min), upperBound: Int(Int8.max), writeStream: &writeStream)
        try _testIntCompressor(lowerBound: Int(Int16.min), upperBound: Int(Int16.max), writeStream: &writeStream)
        try _testIntCompressor(lowerBound: Int(Int32.min), upperBound: Int(Int32.max), writeStream: &writeStream)
        try _testIntCompressor(lowerBound: Int.min, upperBound: Int.max, writeStream: &writeStream)
        
        try _testIntCompressor(lowerBound: 0, upperBound: Int(Int8.max), writeStream: &writeStream)
        try _testIntCompressor(lowerBound: 0, upperBound: Int(Int16.max), writeStream: &writeStream)
        try _testIntCompressor(lowerBound: 0, upperBound: Int(Int32.max), writeStream: &writeStream)
        try _testIntCompressor(lowerBound: 0, upperBound: Int.max, writeStream: &writeStream)
        
        try _testIntCompressor(lowerBound: Int(Int8.min), upperBound: 0, writeStream: &writeStream)
        try _testIntCompressor(lowerBound: Int(Int16.min), upperBound: 0, writeStream: &writeStream)
        try _testIntCompressor(lowerBound: Int(Int32.min), upperBound: 0, writeStream: &writeStream)
        try _testIntCompressor(lowerBound: Int.min, upperBound: 0, writeStream: &writeStream)
        
        for _ in 0..<10 {
            try _testIntCompressor(lowerBound: Int.random(in: -10000000 ... -1), upperBound: Int.random(in: 1...10000000), writeStream: &writeStream)
        }
    }
    
    private func _testIntCompressor(lowerBound: Int, upperBound: Int, writeStream: inout WritableBitStream) throws {
        writeStream.reset()
        let intCompressor = IntCompressor(minValue: lowerBound, maxValue: upperBound)
        var writtenValues: [Int] = []
        var currentValue = lowerBound
        while currentValue <= upperBound {
            writtenValues.append(currentValue)
            intCompressor.write(currentValue, to: &writeStream)
            let valueToAdd = max(max(upperBound / 40_000, abs(lowerBound + 1) / 40_000), 1)
            let (partialValue, overflow) = currentValue.addingReportingOverflow(Int.random(in: 1 ... valueToAdd))
            currentValue = partialValue
            if overflow {
                writtenValues.append(upperBound)
                intCompressor.write(upperBound, to: &writeStream)
                break
            }
        }
        
        var readStream = try ReadableBitStream(bytes: writeStream.packBytes(withCrc: true), crcValidated: true)
        for writtenValue in writtenValues {
            XCTAssertEqual(writtenValue, try intCompressor.read(from: &readStream))
        }
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
        
        static func random() -> Packet {
            Packet(sequence: .random(in: .min ... .max))
        }
    }
    
    private enum EntityType: UInt32, CaseIterable {
        case player
        case ai
        case cpu
        case robot
        
        static func random() -> EntityType {
            allCases.randomElement()!
        }
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
        public let identifier: UUID
        public let packets: [Packet]
        
        public let uint8Opt: UInt8?
        public let uint16Opt: UInt16?
        public let uint32Opt: UInt32?
        public let uint64Opt: UInt64?
        public let uintOpt: UInt?
        public let int8Opt: Int8?
        public let int16Opt: Int16?
        public let int32Opt: Int32?
        public let int64Opt: Int64?
        public let intOpt: Int?
        public let nameOpt: String?
        public let boolOpt: Bool?
        public let enumOpt: EntityType?
        public let floatOpt: Float?
        public let doubleOpt: Double?
        public let bytesOpt: [UInt8]?
        public let identifierOpt: UUID?
        public let packetsOpt: [Packet]?
        public let packetsAreOpt: [Packet?]
        
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
                      float: Float, double: Double, bytes: [UInt8], identifier: UUID, packets: [Packet],
                      uint8Opt: UInt8?, uint16Opt: UInt16?, uint32Opt: UInt32?, uint64Opt: UInt64?, uintOpt: UInt?,
                      int8Opt: Int8?, int16Opt: Int16?, int32Opt: Int32?, int64Opt: Int64?, intOpt: Int?,
                      nameOpt: String?, boolOpt: Bool?, enumOpt: SebbuBitStreamTests.EntityType?,
                      floatOpt: Float?, doubleOpt: Double?, bytesOpt: [UInt8]?, identifierOpt: UUID?,
                      packetsOpt: [Packet]?, packetsAreOpt: [Packet?],
                      count: Int, uint8bits: UInt8, uint16bits: UInt16, uint32bits: UInt32,
                      uint64bits: UInt64, uintbits: UInt, uintBits999: UInt32,
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
            self.packets = packets
            
            self.uint8Opt = uint8Opt
            self.uint16Opt = uint16Opt
            self.uint32Opt = uint32Opt
            self.uint64Opt = uint64Opt
            self.uintOpt = uintOpt
            self.int8Opt = int8Opt
            self.int16Opt = int16Opt
            self.int32Opt = int32Opt
            self.int64Opt = int64Opt
            self.intOpt = intOpt
            self.nameOpt = nameOpt
            self.boolOpt = boolOpt
            self.enumOpt = enumOpt
            self.floatOpt = floatOpt
            self.doubleOpt = doubleOpt
            self.bytesOpt = bytesOpt
            self.identifierOpt = identifierOpt
            self.packetsOpt = packetsOpt
            self.packetsAreOpt = packetsAreOpt
            
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
            identifier = try bitStream.read()
            packets = try bitStream.read()
            
            uint8Opt = try bitStream.read()
            uint16Opt = try bitStream.read()
            uint32Opt = try bitStream.read()
            uint64Opt = try bitStream.read()
            uintOpt = try bitStream.read()
            int8Opt = try bitStream.read()
            int16Opt = try bitStream.read()
            int32Opt = try bitStream.read()
            int64Opt = try bitStream.read()
            intOpt = try bitStream.read()
            nameOpt = try bitStream.read()
            boolOpt = try bitStream.read()
            enumOpt = try bitStream.read()
            floatOpt = try bitStream.read()
            doubleOpt = try bitStream.read()
            bytesOpt = try bitStream.read()
            identifierOpt = try bitStream.read()
            packetsOpt = try bitStream.read()
            packetsAreOpt = try bitStream.read()
            
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
            bitStream.append(identifier)
            bitStream.append(packets)
            
            bitStream.append(uint8Opt)
            bitStream.append(uint16Opt)
            bitStream.append(uint32Opt)
            bitStream.append(uint64Opt)
            bitStream.append(uintOpt)
            bitStream.append(int8Opt)
            bitStream.append(int16Opt)
            bitStream.append(int32Opt)
            bitStream.append(int64Opt)
            bitStream.append(intOpt)
            bitStream.append(nameOpt)
            bitStream.append(boolOpt)
            bitStream.append(enumOpt)
            bitStream.append(floatOpt)
            bitStream.append(doubleOpt)
            bitStream.append(bytesOpt)
            bitStream.append(identifierOpt)
            bitStream.append(packetsOpt)
            bitStream.append(packetsAreOpt)
            
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

    private func assert(entity: Entity, newEntity: Entity) throws {
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
        XCTAssertEqual(entity.packets, entity.packets)
        
        // Optionals
        XCTAssertEqual(entity.uint8Opt, newEntity.uint8Opt)
        XCTAssertEqual(entity.uint16Opt, newEntity.uint16Opt)
        XCTAssertEqual(entity.uint32Opt, newEntity.uint32Opt)
        XCTAssertEqual(entity.uint64Opt, newEntity.uint64Opt)
        XCTAssertEqual(entity.uintOpt, newEntity.uintOpt)
        
        XCTAssertEqual(entity.int8Opt, newEntity.int8Opt)
        XCTAssertEqual(entity.int16Opt, newEntity.int16Opt)
        XCTAssertEqual(entity.int32Opt, newEntity.int32Opt)
        XCTAssertEqual(entity.int64Opt, newEntity.int64Opt)
        XCTAssertEqual(entity.intOpt, newEntity.intOpt)
        
        XCTAssertEqual(entity.nameOpt, newEntity.nameOpt)
        XCTAssertEqual(entity.boolOpt, newEntity.boolOpt)
        XCTAssertEqual(entity.enumOpt, newEntity.enumOpt)
        XCTAssertEqual(entity.floatOpt, newEntity.floatOpt)
        XCTAssertEqual(entity.doubleOpt, newEntity.doubleOpt)
        XCTAssertEqual(entity.bytesOpt, newEntity.bytesOpt)
        
        XCTAssertEqual(entity.identifierOpt, newEntity.identifierOpt)
        XCTAssertEqual(entity.packetsOpt, newEntity.packetsOpt)
        XCTAssertEqual(entity.packetsAreOpt, newEntity.packetsAreOpt)
        
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
}
