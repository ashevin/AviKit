//
// Base32.swift
// AviKit
//
// Created by Avi Shevin.
// Copyright © 2019 Avi Shevin. All rights reserved.
//

import Foundation

public enum Base32 {
    public static func encode<T: Sequence>(_ data: T) -> String where T.Element == UInt8 {
        var stream = BitStream(data)

        var s = [Character]()

        let count = stream.count

        stream.bytes += count % 5 == 0 ? [] : [ 0 ]

        // calculate the nearest multiple of 5 which is equal-to-or-greater than count
        let limit = count - (count - (count / 5 * 5)) + (count % 5 == 0 ? 0 : 5)

        for i in stride(from: 0, to: limit, by: 5) {
            s.append(toTable[stream[i ... i + 4]]!)
        }

        return String(s + Array(repeating: "=", count: (8 - (s.count % 8)) % 8))
    }

    public static func decode(_ string: String) -> [UInt8]? {
        guard string.count.isMultiple(of: 8) else { return nil }

        let string = string.uppercased().map { $0 }.filter({ $0 != "=" })
        var bytes = string.compactMap { fromTable[$0] }[...]

        guard bytes.count == string.count else { return nil }

        var result = [UInt8]()

        var accumulator: UInt8 = 0
        var bitsNeeded = 8
        var bitsRemaining = 0

        var byte: UInt8 = 0

        while bytes.startIndex < bytes.endIndex {
            if bitsRemaining == 0 {
                byte = bytes[bytes.startIndex]; bytes = bytes[(bytes.startIndex + 1)...]

                bitsRemaining = 5
            }

            let bitsTaken = min(bitsRemaining, bitsNeeded)

            let high = 5 - (5 - bitsTaken) + (bitsRemaining - bitsTaken) - 1
            let low = high - bitsTaken + 1

            bitsNeeded -= bitsTaken
            bitsRemaining -= bitsTaken

            accumulator <<= bitsTaken
            accumulator += byte[low, high]

            if bitsNeeded == 0 {
                result.append(accumulator)

                accumulator = 0
                bitsNeeded = 8
            }
        }

        return result
    }
}

private let fromTable: [Character: UInt8] = [
    "A": 0b00000, "B": 0b00001, "C": 0b00010, "D": 0b00011, "E": 0b00100,
    "F": 0b00101, "G": 0b00110, "H": 0b00111, "I": 0b01000, "J": 0b01001,
    "K": 0b01010, "L": 0b01011, "M": 0b01100, "N": 0b01101, "O": 0b01110,
    "P": 0b01111, "Q": 0b10000, "R": 0b10001, "S": 0b10010, "T": 0b10011,
    "U": 0b10100, "V": 0b10101, "W": 0b10110, "X": 0b10111, "Y": 0b11000,
    "Z": 0b11001, "2": 0b11010, "3": 0b11011, "4": 0b11100, "5": 0b11101,
    "6": 0b11110, "7": 0b11111,
]

private let toTable: [UInt8: Character] = {
    var t = [UInt8: Character]()

    for (k, v) in fromTable { t[v] = k }

    return t
}()
