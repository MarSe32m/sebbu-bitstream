
@usableFromInline
internal let crcTable: UnsafeBufferPointer<UInt32> = {
    let buffer = UnsafeMutableBufferPointer<UInt32>.allocate(capacity: 256)
    for i: UInt32 in 0...255 {
        buffer[Int(i)] = (0..<8).reduce(UInt32(i), {c, _ in
            (c % UInt32(2) == 0) ? (c >> UInt32(1)) : (UInt32(0xEDB88320) ^ (c >> 1))
        })
    }
    return UnsafeBufferPointer(buffer)
}()

internal extension Sequence where Element == UInt8 {
    @usableFromInline
    var crcChecksum: UInt32 {
        ~(self.reduce(~UInt32(0), { crc, byte in 
            (crc >> 8) ^ crcTable[(Int(crc) ^ Int(byte)) & 0xFF]
        }))
    }
}

internal extension UnsafeRawBufferPointer {
    @usableFromInline
    var crcChecksum: UInt32 {
        ~(self.reduce(~UInt32(0), { crc, byte in
            (crc >> 8) ^ crcTable[(Int(crc) ^ Int(byte)) & 0xFF]
        }))
    }
}