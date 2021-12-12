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

        let extraCount = stream.bytes.count % 5
        let padding = ["", "======", "====", "===", "="][extraCount]

        // calculate the nearest multiple of 5 which is equal-to-or-greater than count
        let count = stream.count
        let limit = count - (count - (count / 5 * 5)) + (count % 5 == 0 ? 0 : 5)

        stream.bytes += Array(repeating: 0, count: 5 - extraCount)

        for i in stride(from: 0, to: limit, by: 5) {
            s.append(toTable[stream[i ... i + 4]]!)
        }

        return String(s) + padding
    }

    public static func decode(_ string: String) -> [UInt8]? {
        enum E: Error { case invalidChar }

        guard string.count % 8 == 0 else { return nil }

        var result = [UInt8]()

        let string = string.uppercased().map { $0 }
        let bytes: [UInt8]

        do {
            bytes = try string.compactMap {
                guard $0 != "=" else { return nil }

                guard let v = fromTable[$0] else { throw E.invalidChar }

                return v
            }
        }
        catch {
            return nil
        }

        let paddingCounts = [0, 1, 3, 4, 6]
        let paddingCount = string.count - (string.firstIndex(of: "=") ?? bytes.count)
        let paddingIndex = paddingCounts.firstIndex(of: paddingCount)

        for i in stride(from: 0, to: bytes.count, by: 8) {
            result.append(bytes[i] << 3 + bytes[i + 1][2, 4])

            let b: [() -> (UInt8)] = [
                { bytes[i + 1][0, 1] << 6 + bytes[i + 2] << 1 + bytes[i + 3][4] },

                { bytes[i + 3][0, 3] << 4 + bytes[i + 4][1, 4] },

                { bytes[i + 4][0] << 7 + bytes[i + 5] << 2 + bytes[i + 6][3, 4] },

                { bytes[i + 6][0, 2] << 5 + bytes[i + 7] },
            ]

            (0 ..< 4 - (i + 8 < bytes.count ? 0 : paddingIndex!))
                .forEach { result.append(b[$0]()) }
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
