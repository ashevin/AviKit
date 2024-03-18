//
// BaseNCoding.swift
// AviKit
//
// Created by Avi Shevin.
// Copyright © 2019 Avi Shevin. All rights reserved.
//

import Foundation

public struct BaseNCoding {
    let alphabet: String
    let padding: Character?

    private let bitWidth: Int

    init(alphabet: String, padding: Character? = "=") {
        precondition(alphabet.count.nonzeroBitCount == 1, "alphabet length is not a power of 2")
        precondition(Set(alphabet.map({ $0 })).count == alphabet.count, "alphabet does not contain unique characters")

        self.alphabet = alphabet
        self.padding = padding

        bitWidth = Int.bitWidth - alphabet.count.leadingZeroBitCount - 1
    }

    public func encode<T: Sequence>(_ data: T) -> String where T.Element == UInt8
    {
        let toTable = Self.toTable(alphabet: alphabet)

        var stream = BitStream(data)

        var s = [Character]()

        let count = stream.count

        stream.bytes += count % bitWidth == 0 ? [] : [ 0 ]

        // calculate the nearest multiple of `bitWidth` which is equal-to-or-greater than count
        let limit = count - (count - (count / bitWidth * bitWidth)) + (count % bitWidth == 0 ? 0 : bitWidth)

        for i in stride(from: 0, to: limit, by: bitWidth) {
            s.append(toTable[stream[i ... i + (bitWidth - 1)]]!)
        }

        return padding != nil ? String(s + Array(repeating: padding!, count: (8 - (s.count % 8)) % 8)) : String(s)
    }

    public func decode(_ string: String) -> [UInt8]?
    {
        guard string.count.isMultiple(of: 8) else { return nil }

        let fromTable = Self.fromTable(alphabet: alphabet)

        let string = string.uppercased().map { $0 }.filter({ $0 != padding })
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

                bitsRemaining = bitWidth
            }

            let bitsTaken = min(bitsRemaining, bitsNeeded)

            let high = bitWidth - (bitWidth - bitsTaken) + (bitsRemaining - bitsTaken) - 1
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

    private static func fromTable(alphabet: String) -> [Character: UInt8] {
        let alpha = alphabet.map { $0 }

        var table = [Character: UInt8]()

        for index in alpha.indices {
            table[alpha[index]] = UInt8(clamping: index)
        }

        return table
    }

    private static func toTable(alphabet: String) -> [UInt8: Character] {
        var t = [UInt8: Character]()

        for (k, v) in fromTable(alphabet: alphabet) { t[v] = k }

        return t
    }
}

public extension BaseNCoding {
    static var Base32: Self {
        BaseNCoding(alphabet: "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567", padding: "=")
    }

    static var Base64: Self {
        BaseNCoding(alphabet: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/", padding: "=")
    }

    static var Base2: Self {
        BaseNCoding(alphabet: "01", padding: nil)
    }

    static var Base8: Self {
        BaseNCoding(alphabet: "01234567", padding: nil)
    }

    static var Base16: Self {
        BaseNCoding(alphabet: "0123456789abcdef", padding: nil)
    }
}

@available(*, deprecated, renamed: "BaseNCoding.Base32", message: "Use BaseNCoding")
public enum Base32 {
    @available(*, deprecated, renamed: "BaseNCoding.Base32.encode", message: "Use BaseNCoding")
    public static func encode<T: Sequence>(_ data: T) -> String where T.Element == UInt8 {
        BaseNCoding.Base32.encode(data)
    }

    @available(*, deprecated, renamed: "BaseNCoding.Base32.decode", message: "Use BaseNCoding")
    public static func decode(_ string: String) -> [UInt8]? {
        BaseNCoding.Base32.decode(string)
    }
}
