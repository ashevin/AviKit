//
//  BitStreamTests.swift
//  
//
//  Created by Avraham Shevin on 18/03/2024.
//

import XCTest
import AviKit

final class BitStreamTests: XCTestCase {
    func test_startIndex() {
        let bs = BitStream([0b10101010])

        XCTAssertEqual(bs.startIndex, 0)
    }

    func test_endIndex() {
        let bs = BitStream([0b10101010])

        XCTAssertEqual(bs.endIndex, 8)
    }

    func test_subscript_with_range() {
        let bs = BitStream([0b10101010])

        XCTAssertEqual(bs[2 ..< 5], 5)
    }

    func test_subscript_with_closed_range() {
        let bs = BitStream([0b10101010])

        XCTAssertEqual(bs[2 ... 5], 10)
    }

    func test_subscript_single_position() {
        let bs = BitStream([0b10101010])

        XCTAssertEqual(bs[6], 1)
        XCTAssertEqual(bs[7], 0)
    }

    func test_subscript() {
        let bs = BitStream([0b10101010])

        XCTAssertEqual(bs[6, 7], 2)
    }

    func test_cross_byte_range() {
        let bs = BitStream([0b10101010, 0b10101010])

        XCTAssertEqual(bs[6, 9], 10)
    }

    func test_debug_description() {
        let bs = BitStream([0b10101010])

        XCTAssertEqual(bs.debugDescription, "10101010")
    }
}
