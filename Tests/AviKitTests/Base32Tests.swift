//
// Base32Tests.swift
// AviKitTests
//
// Created by Avi Shevin.
// Copyright © 2019 Avi Shevin. All rights reserved.
//

import XCTest
@testable import AviKit

class Base32Tests: XCTestCase {
    func test_padding_0() {
        let s = "abcde"
        let b = BaseNCoding.Base32.encode(s.utf8)

        XCTAssertEqual(b, "MFRGGZDF")
        XCTAssertEqual(BaseNCoding.Base32.decode(b), s.utf8.array)
    }

    func test_padding_1() {
        let s = "abcd"
        let b = BaseNCoding.Base32.encode(s.utf8)

        XCTAssertEqual(b, "MFRGGZA=")
        XCTAssertEqual(BaseNCoding.Base32.decode(b), s.utf8.array)
    }

    func test_padding_3() {
        let s = "abcdefgh"
        let b = BaseNCoding.Base32.encode(s.utf8)

        XCTAssertEqual(b, "MFRGGZDFMZTWQ===")
        XCTAssertEqual(BaseNCoding.Base32.decode(b), s.utf8.array)
    }

    func test_padding_4() {
        let s = "abcdefg"
        let b = BaseNCoding.Base32.encode(s.utf8)

        XCTAssertEqual(b, "MFRGGZDFMZTQ====")
        XCTAssertEqual(BaseNCoding.Base32.decode(b), s.utf8.array)
    }

    func test_padding_6() {
        let s = "abcdef"
        let b = BaseNCoding.Base32.encode(s.utf8)

        XCTAssertEqual(b, "MFRGGZDFMY======")
        XCTAssertEqual(BaseNCoding.Base32.decode(b), s.utf8.array)
    }

    func test_decode_invalid_length() {
        let s = "AAAA"
        let d = BaseNCoding.Base32.decode(s)

        XCTAssertNil(d)
    }

    func test_decode_invalid_character() {
        let s = "88888888"
        let d = BaseNCoding.Base32.decode(s)

        XCTAssertNil(d)
    }
}
