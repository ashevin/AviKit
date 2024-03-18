//
// ObservableTests.swift
// AviKitTests
//
// Created by Avi Shevin.
// Copyright © 2019 Avi Shevin. All rights reserved.
//

import XCTest
@testable import AviKit

#if os(iOS)
import UIKit
#endif

class ObservableTests: XCTestCase {
    func test_next_before_observe() {
        let e = expectation(description: "")

        let o = Observable<Int>()

        o.next(3)

        o.on(next: {
            XCTAssertEqual($0, 3)
            e.fulfill()
        })

        wait(for: [e], timeout: 1)
    }

    func test_next_after_observe() {
        let e = expectation(description: "")

        let o = Observable<Int>()

        o.on(next: {
            XCTAssertEqual($0, 3)
            e.fulfill()
        })

        o.next(3)

        wait(for: [e], timeout: 1)
    }

    func test_pre_observer_buffering() {
        let e = expectation(description: "")

        let o = Observable<Int>()

        o.next(3)
        o.next(2)
        o.next(1)

        var eventCounter = 3
        o.on(next: { _ in
            eventCounter -= 1

            if eventCounter == 0 { e.fulfill() }
        })

        wait(for: [e], timeout: 1)
    }

    struct E: Error { }

    func test_error() {
        let e = expectation(description: "")

        let o = Observable<Int>()

        o.on(error: { _ in e.fulfill() })

        o.error(E())

        var didExecute = false
        o.on(next: { _ in didExecute = true })
        o.next(3)

        XCTAssertFalse(didExecute)

        wait(for: [e], timeout: 1)
    }

    func test_error_after_error() {
        let e = expectation(description: "")

        let o = Observable<Int>()

        o.on(error: { _ in e.fulfill() })

        o.error(E())
        o.error(E())

        wait(for: [e], timeout: 1)
    }

    func test_finish() {
        let e = expectation(description: "")

        let o = Observable<Int>()

        o.on(finish: { e.fulfill() })

        o.finish()

        var didExecute = false
        o.on(next: { _ in didExecute = true })
        o.next(3)

        XCTAssertFalse(didExecute)

        wait(for: [e], timeout: 1)
    }

    func test_finish_after_finish() {
        let e = expectation(description: "")

        let o = Observable<Int>()

        o.on(finish: { e.fulfill() })

        o.finish()
        o.finish()

        wait(for: [e], timeout: 1)
    }

    func test_unlink() {
        let lb = LinkBag()

        let o = Observable<Int>(3)

        o.on(finish: { })
            .add(to: lb)

        o.finish()

        XCTAssertFalse(lb.links.isEmpty)

        lb.clear()

        XCTAssertTrue(lb.links.isEmpty)
    }

    func test_linkbag_clear_deinit() {
        var lb: LinkBag? = LinkBag()

        let o = Observable<Int>()
        o
            .observer()
            .on(next: { _ in XCTFail("This should have been deallocated!") })
            .add(to: lb!)

        lb = nil

        o.next(3)
    }

    func test_unlink_with_multiple_refs() {
        let e = expectation(description: "")

        let lb1 = LinkBag()
        let lb2 = LinkBag()

        let o = Observable<Int>()

        o
            .map({ $0 })
            .on(finish: { XCTFail("This should have been deallocated!" )})
            .add(to: lb1)

        o
            .on(finish: { e.fulfill() })
            .add(to: lb2)

        lb1.clear()

        o.next(3)
        o.finish()

        wait(for: [e], timeout: 1)
    }

    func test_accumulate() {
        let e = expectation(description: "")

        let o = Observable<Int>()
        let p = o.accumulate(limit: 3)

        o.next(3)
        o.next(2)
        o.next(1)

        var eventCounter = 3
        p.on(queue: DispatchQueue(label: ""), next: {
            eventCounter -= 1

            XCTAssertEqual($0.count, 3 - eventCounter)

            if eventCounter == 0 { e.fulfill() }
        })

        wait(for: [e], timeout: 1)
    }

    func test_accumulate_overflow() {
        let e = expectation(description: "")

        let o = Observable<Int>()
        let p = o.accumulate(limit: 3)

        o.next(4)
        o.next(3)
        o.next(2)
        o.next(1)

        var eventCounter = 4
        p.on(next: {
            eventCounter -= 1

            XCTAssertLessThanOrEqual($0.count, 3)

            if eventCounter == 0 { e.fulfill() }
        })

        wait(for: [e], timeout: 1)
    }

    func test_combine_other_signal_primary() {
        let e = expectation(description: "")

        let o = Observable<Int>()
        let p = Observable<String>()
        let q = o.combine(with: p)

        o.next(3)

        q.on(next: {
            XCTAssertEqual($0.0, 3)
            XCTAssertEqual($0.1, nil)

            e.fulfill()
        })

        wait(for: [e], timeout: 1)
    }

    func test_combine_other_signal_other() {
        let e = expectation(description: "")

        let o = Observable<Int>()
        let p = Observable<String>()
        let q = o.combine(with: p)

        p.next("3")

        q.on(next: {
            XCTAssertEqual($0.0, nil)
            XCTAssertEqual($0.1, "3")

            e.fulfill()
        })

        wait(for: [e], timeout: 1)
    }

    func test_combine_other_signal_both() {
        let e = expectation(description: "")

        let o = Observable<Int>()
        let p = Observable<String>()
        let q = o.combine(with: p)

        o.next(3)
        p.next("3")

        var eventCounter = 2
        q.on(next: {
            eventCounter -= 1

            if eventCounter == 0 {
                XCTAssertEqual($0.0, 3)
                XCTAssertEqual($0.1, "3")

                e.fulfill()
            }
        })

        wait(for: [e], timeout: 1)
    }

    func test_combine_same_signal_primary() {
        let e = expectation(description: "")

        let o = Observable<Int>()
        let p = Observable<Int>()
        let q = Observable<Int>()
        let r = o.combine(with: p, q)

        o.next(3)

        r.on(next: {
            XCTAssertEqual($0[0], 3)
            XCTAssertEqual($0[1], nil)
            XCTAssertEqual($0[2], nil)

            e.fulfill()
        })

        wait(for: [e], timeout: 1)
    }

    func test_combine_same_signal_other() {
        let e = expectation(description: "")

        let o = Observable<Int>()
        let p = Observable<Int>()
        let q = Observable<Int>()
        let r = o.combine(with: p, q)

        p.next(3)

        r.on(next: {
            XCTAssertEqual($0[0], nil)
            XCTAssertEqual($0[1], 3)
            XCTAssertEqual($0[2], nil)

            e.fulfill()
        })

        wait(for: [e], timeout: 1)
    }

    func test_combine_same_signal_all() {
        let e = expectation(description: "")

        let o = Observable<Int>()
        let p = Observable<Int>()
        let q = Observable<Int>()
        let r = o.combine(with: p, q)

        o.next(3)
        p.next(2)
        q.next(1)

        var eventCounter = 3
        r.on(next: {
            eventCounter -= 1

            if eventCounter == 0 {
                XCTAssertEqual($0[0], 3)
                XCTAssertEqual($0[1], 2)
                XCTAssertEqual($0[2], 1)

                e.fulfill()
            }
        })

        wait(for: [e], timeout: 1)
    }

    func test_debug() {
        let e = expectation(description: "")

        let o = Observable<Int>()
        let p = o.debug()

        o.next(3)

        p.on(next: {
            XCTAssertEqual($0, 3)
            e.fulfill()
        })

        wait(for: [e], timeout: 1)
    }

    func test_debug_with_identifier() {
        let e = expectation(description: "")

        let o = Observable<Int>()
        let p = o.debug("debug test")

        o.next(3)

        p.on(next: {
            XCTAssertEqual($0, 3)
            e.fulfill()
        })

        wait(for: [e], timeout: 1)
    }

    func test_filter() {
        let e = expectation(description: "")

        let o = Observable<Int>()
        let p = o.filter({ $0 % 2 == 0 })

        o.next(3)
        o.next(2)

        p.on(next: {
            XCTAssertEqual($0, 2)
            e.fulfill()
        })

        wait(for: [e], timeout: 1)
    }

    func test_compact_map() {
        let e = expectation(description: "")

        let o = Observable<Int>()
        let p = o.compactMap({ $0 % 2 == 0 ? String($0) : nil })

        o.next(3)
        o.next(2)

        p.on(next: {
            XCTAssertEqual($0, "2")
            e.fulfill()
        })

        wait(for: [e], timeout: 1)
    }

    func test_map() {
        let e = expectation(description: "")

        let o = Observable<Int>()
        let p = o.map({ String($0) })

        o.next(3)

        p.on(next: {
            XCTAssertEqual($0, "3")
            e.fulfill()
        })

        wait(for: [e], timeout: 1)
    }

    func test_skip() {
        let e = expectation(description: "")

        let o = Observable<Int>()
        let p = o.skip(2)

        o.next(3)
        o.next(2)
        o.next(1)

        p.on(next: {
            XCTAssertEqual($0, 1)
            e.fulfill()
        })

        wait(for: [e], timeout: 1)
    }

    @available(*, deprecated)
    func test_stateful() {
        let o = Observable<Int>()
        let p = o.stateful()

        XCTAssertNil(p.value)

        o.next(3)

        p.on(next: { _ in })
        p.on(next: { _ in })

        XCTAssertEqual(p.value, 3)
    }

    func test_debounce() {
        let e = expectation(description: "")

        let o = Observable<Int>()
        let p = o.debounce(delay: 0.1)

        o.next(3)
        o.next(2)
        o.next(1)

        p.on(next: {
            XCTAssertEqual($0, 1)
            e.fulfill()
        })

        wait(for: [e], timeout: 1)
    }

    func test_debounce_with_delayed_events() {
        let e = expectation(description: "")

        let o = Observable<Int>()
        let p = o.debounce(delay: 0.1)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { o.next(3) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { o.next(2) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { o.next(1) }

        var eventCounter = 3
        p.on(next: {
            XCTAssertEqual($0, eventCounter)

            eventCounter -= 1

            if eventCounter == 0 { e.fulfill() }
        })

        wait(for: [e], timeout: 1)
    }

    func test_distinct() {
        let e = expectation(description: "")

        let o = Observable<Int>()
        let p = o.distinct()

        var a: [Int] = []

        var eventCounter = 2
        p.on(next: {
            a.append($0)

            eventCounter -= 1

            if eventCounter == 0 { e.fulfill() }
        })

        o.next(1)
        o.next(1)
        o.next(2)

        wait(for: [e], timeout: 1)

        XCTAssertEqual(a, [1, 2])
    }

    func test_distinct_with_distinct_value_between_duplicates() {
        let e = expectation(description: "")

        let o = Observable<Int>()
        let p = o.distinct()

        var a: [Int] = []

        var eventCounter = 3
        p.on(next: {
            a.append($0)

            eventCounter -= 1

            if eventCounter == 0 { e.fulfill() }
        })

        o.next(1)
        o.next(2)
        o.next(1)

        wait(for: [e], timeout: 1)

        XCTAssertEqual(a, [1, 2, 1])
    }

    func test_observer() {
        let e = expectation(description: "")

        let o = Observable<Int>()
        let p = o.observer()

        o.next(3)

        p.on(next: {
            XCTAssertEqual($0, 3)
            e.fulfill()
        })

        wait(for: [e], timeout: 1)
    }

    func test_observable_property (){
        class C { @ObservableProperty var x: Int = 0 }

        let c = C()

        let e = expectation(description: "")

        c.x = 4
        c.$x.on(next: {
            XCTAssertEqual(c.x, 4)
            XCTAssertEqual(c.x, $0)

            e.fulfill()
        })

        wait(for: [e], timeout: 1)
    }

    func test_notification() {
        let e = expectation(description: "")

        let n = Notification.Name(rawValue: "test")

        let o = NotificationObserver(name: n)

        NotificationCenter.default.post(Notification(name: n))

        o.on(next: {
            XCTAssertEqual($0.name.rawValue, "test")
            e.fulfill()
        })

        wait(for: [e], timeout: 1)
    }
    
}

#if os(iOS)
extension ObservableTests {
    func test_action() {
        let e = expectation(description: "")

        let c = UIButton(frame: .zero)

        let o = ActionObserver(source: c, event: .touchUpInside)

        c.sendActions(for: .touchUpInside)

        o.on(next: { _ in
            e.fulfill()
        })

        wait(for: [e], timeout: 1)
    }
}
#endif

#if !os(Linux)
class KVOTest: NSObject {
    @objc var test: Int {
        get { return 3 }

        set {
            willChangeValue(for: \.test)
            didChangeValue(for: \.test)
        }
    }
}

extension ObservableTests {
    func test_kvo() {
        let e = expectation(description: "")

        var t: KVOTest? = KVOTest()
        var o: KVOObserver? = KVOObserver(object: t!, keyPath: \KVOTest.test)

        t?.test = 7

        o?.on(next: {
            XCTAssertEqual($0.new, t?.test)

            e.fulfill()
        })

        o = nil
        t = nil

        wait(for: [e], timeout: 1)
    }
}
#endif
