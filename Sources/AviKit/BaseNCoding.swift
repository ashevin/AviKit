//
// BaseNCoding.swift
// AviKit
//
// Created by Avi Shevin.
// Copyright © 2019 Avi Shevin. All rights reserved.
//

import Foundation

/**
`BaseNCoding` provides methods to encode and decode data using a provided alphabet and an optional padding character.  Static constructors are provided
 for common formats, as defined by [RFC-4648](https://datatracker.ietf.org/doc/html/rfc4648).
 */
public struct BaseNCoding {
    /// the character set used for encoding and decoding
    public let alphabet: String
    /// the padding character used when the encoded string is not a multiple of the bit width
    public let padding: Character?
    /// indicates whether the characters of a decoded string should be compared in a case-sensitive way to the characters in the alphabet
    public let caseSensitive: Bool

    private let bitWidth: Int

    /**
     Construct an instance of BaseNCoding which will use the given alphabet for encoding and decoding.

     - Parameters:
         - alphabet: a string of characters to which data will be mapped when encoding, and from which strings will be mapped when decoding.
         - padding: an optional character that will be used as required.
         - caseSensitive: a boolean which controls whether decoding treats upper and lower-case letters as being the same.

     Alphabets must consist of single-byte characters.  For best results, they should be limited to printable ASCII characters.  It is a programmer error to
     pass `false` to `caseSensitive` if the alphabet contains both upper and lower-case letters.  Alphabets must consist of a unique set of characters,
     and the alphabet count must be a power of 2.  The index of each character in the alphabet string is used as its value when encoding and decoding.

     ## Padding

     When encoding, each group of N bits from the input is mapped to a character from the alphabet and appended to the output.  When the maximum number
     of bits necessary to represent a single character is not a factor of 8 (the bit width of a single byte), padding is used to represent the missing bits.

     ## Example
     ```swift
     BaseNCoding(alphabet: "ab")
     ```

     This coder will map sequences of bytes into strings consisting of the characters __a__ and __b__, where __a__ represents a zero and __b__
     represents a 1. A single byte with a value of 85 has a binary representation of `01010101`, which will map to "abababab".
     */
    public init(alphabet: String, padding: Character? = "=", caseSensitive: Bool = false) {
        precondition(alphabet.count.nonzeroBitCount == 1, "alphabet length is not a power of 2")
        precondition(Set(alphabet.map({ $0 })).count == alphabet.count, "alphabet does not contain unique characters")

        self.alphabet = caseSensitive ? alphabet : alphabet.uppercased()
        self.padding = padding
        self.caseSensitive = caseSensitive

        bitWidth = Int.bitWidth - alphabet.count.leadingZeroBitCount - 1
    }

    /**
     Encode a sequence of bytes into a string comprised of characters from the provided alphabet.
     */
    public func encode<S: Sequence>(_ data: S) -> String where S.Element == UInt8 {
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

    public func decode(_ string: String) -> [UInt8]? {
        guard string.count.isMultiple(of: 8) else { return nil }

        let fromTable = Self.fromTable(alphabet: alphabet)

        let string = string.map { caseSensitive ? $0 : Character($0.uppercased()) }.filter({ $0 != padding })
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
    /// A coder preconfigured with the base32 alphabet, as specified by [RFC-4648](https://datatracker.ietf.org/doc/html/rfc4648)
    static var Base32: Self {
        BaseNCoding(alphabet: "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567", padding: "=", caseSensitive: false)
    }

    /// A coder preconfigured with the base32hex alphabet, as specified by [RFC-4648](https://datatracker.ietf.org/doc/html/rfc4648)
    static var Base32Hex: Self {
        BaseNCoding(alphabet: "0123456789ABCDEFGHIJKLMNOPQRSTUV", padding: "=", caseSensitive: false)
    }

    /// A coder preconfigured with the base64 alphabet, as specified by [RFC-4648](https://datatracker.ietf.org/doc/html/rfc4648)
    static var Base64: Self {
        BaseNCoding(alphabet: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/",
                    padding: "=",
                    caseSensitive: true)
    }

    /// A coder preconfigured with the base64url alphabet, as specified by [RFC-4648](https://datatracker.ietf.org/doc/html/rfc4648)
    static var Base64Hex: Self {
        BaseNCoding(alphabet: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_",
                    padding: "=",
                    caseSensitive: true)
    }

    /// A coder preconfigured with the base16 alphabet, as specified by [RFC-4648](https://datatracker.ietf.org/doc/html/rfc4648)
    static var Base16: Self {
        BaseNCoding(alphabet: "0123456789ABCDEF", padding: nil, caseSensitive: false)
    }

    /// A coder preconfigured to map individual bits to the character '0' and '1' for the bit values _zero_ and _one_, respectively
    static var Base2: Self {
        BaseNCoding(alphabet: "01", padding: nil)
    }

    /// A coder preconfigured to map bytes to their _octal_ string representation
    static var Base8: Self {
        BaseNCoding(alphabet: "01234567", padding: nil)
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
