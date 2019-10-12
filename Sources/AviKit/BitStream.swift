//
// BitStream.swift
// AviKit
//
// Created by Avi Shevin.
// Copyright © 2019 Avi Shevin. All rights reserved.
//

import Foundation

public struct BitStream {
    var bytes: [UInt8]

    public var count: Int { return bytes.count * UInt8.bitWidth }

    public init<T: Sequence>(_ sequence: T) where T.Element == UInt8 {
        self.bytes = sequence.array
    }
}

fileprivate extension BitStream {
    func bytes(for range: ClosedRange<Int>) -> [Int] {
        let first = range.lowerBound / 8
        let last = range.upperBound / 8

        return [first, last]
    }

    func byteRanges(for range: ClosedRange<Int>) -> (ClosedRange<Int>, ClosedRange<Int>?) {
        let a = range.lowerBound / 8 * 8
        let l = range.lowerBound - a
        let h = range.upperBound - a

        if h <= 7 {
            return (7 - h ... 7 - l, nil)
        }
        else {
            let r1 = l ... 7
            let r2 = 8 ... h
            let d = h - 7

            return (7 - r1.upperBound ... 7 - r1.lowerBound,
                    r2.lowerBound - d ... r2.upperBound - d)
        }
    }

    func byte(from: [UInt8], bits: ClosedRange<Int>) -> UInt8 {
        let b = bytes(for: bits)
        let r = byteRanges(for: bits)

        var result = from[b[0]][r.0]

        if let r = r.1 {
            let b = from[b[1]][r]

            result = (result << (r.upperBound - r.lowerBound + 1)) + b
        }

        return result
    }
}

public extension BitStream {
    subscript(range: Range<Int>) -> UInt8 {
        return self[range.lowerBound, range.upperBound - 1]
    }

    subscript(range: ClosedRange<Int>) -> UInt8 {
        return self[range.lowerBound, range.upperBound]
    }

    subscript(bit: Int) -> UInt8 {
        return self[bit, bit]
    }

    subscript(start: Int, end: Int) -> UInt8 {
        precondition(start < UInt8.bitWidth * bytes.count, "start out of range")
        precondition(end < UInt8.bitWidth * bytes.count, "end out of range")
        precondition(start <= end, "start greater than end")

        return byte(from: bytes, bits: start ... end)
    }
}

extension BitStream: Collection, RandomAccessCollection {
    public var startIndex: Int {
        return 0
    }

    public var endIndex: Int {
        return count
    }
}
