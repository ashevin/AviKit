//
// Base32Tests.swift
// KinUtilTests
//
// Created by Kin Foundation.
// Copyright © 2019 Kin Foundation. All rights reserved.
//

import XCTest
@testable import AviKit

class Base32Tests: XCTestCase {

    func test_padding_0() {
        let s = "abcde"
        let b = Base32.encode(s.utf8)

        XCTAssertEqual(b, "MFRGGZDF")
        XCTAssertEqual(Base32.decode(b), s.utf8.array)
    }

    func test_padding_1() {
        let s = "abcd"
        let b = Base32.encode(s.utf8)

        XCTAssertEqual(b, "MFRGGZA=")
        XCTAssertEqual(Base32.decode(b), s.utf8.array)
    }

    func test_padding_3() {
        let s = "abcdefgh"
        let b = Base32.encode(s.utf8)

        XCTAssertEqual(b, "MFRGGZDFMZTWQ===")
        XCTAssertEqual(Base32.decode(b), s.utf8.array)
    }

    func test_padding_4() {
        let s = "abcdefg"
        let b = Base32.encode(s.utf8)

        XCTAssertEqual(b, "MFRGGZDFMZTQ====")
        XCTAssertEqual(Base32.decode(b), s.utf8.array)
    }

    func test_padding_6() {
        let s = "abcdef"
        let b = Base32.encode(s.utf8)

        XCTAssertEqual(b, "MFRGGZDFMY======")
        XCTAssertEqual(Base32.decode(b), s.utf8.array)
    }

    func test_decode_invalid_length() {
        let s = "AAAA"
        let d = Base32.decode(s)

        XCTAssertNil(d)
    }

    func test_decode_invalid_character() {
        let s = "88888888"
        let d = Base32.decode(s)

        XCTAssertNil(d)
    }
}
