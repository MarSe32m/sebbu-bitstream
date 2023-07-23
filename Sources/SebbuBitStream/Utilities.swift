@usableFromInline
internal let crcTable: UnsafeBufferPointer<UInt32> = {
    let buffer = UnsafeMutableBufferPointer<UInt32>.allocate(capacity: 256)
    for i in 0...255 {
        buffer[i] = (0..<8).reduce(UInt32(i)) { c, _ in
            (c % UInt32(2) == 0) ? (c >> UInt32(1)) : (UInt32(0xEDB88320) ^ (c >> 1))
        }
    }
    return UnsafeBufferPointer(buffer)
}()

internal extension Sequence where Element == UInt8 {
    @usableFromInline
    var crcChecksum: UInt32 {
        ~(reduce(~UInt32(0)) { crc, byte in
            (crc >> 8) ^ crcTable[(Int(crc) ^ Int(byte)) & 0xFF]
        })
    }
}

internal extension UnsafeRawBufferPointer {
    @usableFromInline
    var crcChecksum: UInt32 {
        ~(reduce(~UInt32(0)) { crc, byte in
            (crc >> 8) ^ crcTable[(Int(crc) ^ Int(byte)) & 0xFF]
        })
    }
}

/// Gets the number of bits required to encode an enum case.
public extension RawRepresentable where Self: CaseIterable, RawValue == UInt32 {
    @inlinable
    static var bits: Int {
        let casesCount = UInt32(allCases.count)
        return UInt32.bitWidth - casesCount.leadingZeroBitCount
    }
}

//@usableFromInline
public func pow(_ base: Double, _ exponent: Int) -> Double {
    var result = 1.0
    var absExponent = Int(exponent.magnitude)
    if absExponent == 0 { return 1.0 }
    if absExponent % 2 == 1 {
        result *= base
        absExponent -= 1
    }
    let baseSquared = base * base
    while absExponent > 0 {
        result *= baseSquared
        absExponent -= 2
    }
    return exponent > 0 ? result : 1.0 / result
}
