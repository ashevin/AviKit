//
// Miscellaneous+extensions.swift
// AviKit
//
// Created by Avi Shevin.
// Copyright © 2019 Avi Shevin. All rights reserved.
//

import Foundation

extension FixedWidthInteger {
    subscript(range: Range<Int>) -> Self {
        return self[range.lowerBound, range.upperBound - 1]
    }

    subscript(range: ClosedRange<Int>) -> Self {
        return self[range.lowerBound, range.upperBound]
    }

    subscript(bit: Int) -> Self {
        return self[bit, bit]
    }

    subscript(start: Int, end: Int) -> Self {
        precondition(start < Self.bitWidth, "start out of range")
        precondition(end < Self.bitWidth, "end out of range")
        precondition(start <= end, "start greater than end")

        var mask = 0 as Self
        for i in start ... end { mask |= 1 &<< i }

        return (self & mask) &>> start
    }
}
