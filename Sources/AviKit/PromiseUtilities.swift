//
//  PromiseUtilities.swift
// AviKit
//
// Created by Avi Shevin.
// Copyright © 2021 Avi Shevin. All rights reserved.
//

import Foundation
import Dispatch

public func all<Value>(on queue: DispatchQueue? = nil, _ promises: Promise<Value>...) -> Promise<[Value]> {
    all(on: queue, promises)
}

public func all<Value>(on queue: DispatchQueue? = nil, _ promises: [Promise<Value>]) -> Promise<[Value]> {
    let p = Promise<[Value]>()

    let block = {
        var results: [Result<Value>?] = Array(repeating: nil, count: promises.count)

        for i in promises.indices {
            promises[i]
                .finally(on: queue, {
                    results[i] = promises[i].result

                    if results.allSatisfy({ $0 != nil }) {
                        let values = results.compactMap { $0?.success }

                        if values.count == results.count {
                            p.fulfill(values)
                        }
                        else {
                            if let error = results.compactMap({ $0?.failure }).first {
                                p.reject(error)
                            }
                        }
                    }
                })
        }
    }

    run(block, on: queue)

    return p
}

public func `await`<Value>(_ promise: Promise<Value>) throws -> Value {
    let group = DispatchGroup()
    group.enter()

    var result: Result<Value>? = nil

    promise.finally {
        result = promise.result

        group.leave()
    }

    group.wait()

    return try result!.unwrap()
}

public func attempt<T>(_ tries: Int, retryInterval: TimeInterval = 0.0, closure: @escaping (Int) throws -> Promise<T>) -> Promise<T> {
    return attempt(retryIntervals: Array(repeating: retryInterval, count: tries - 1), closure: closure)
}

public func attempt<T>(retryIntervals: [TimeInterval], closure: @escaping (Int) throws -> Promise<T>) -> Promise<T> {
    let p = Promise<T>()

    let tries = retryIntervals.count + 1

    var attempts = 0

    func attempt() {
        attempts += 1

        do {
            try closure(attempts)
                .then({
                    p.fulfill($0)
                })
                .catch({
                    if attempts < tries {
                        DispatchQueue.global().asyncAfter(deadline: .now() + retryIntervals[attempts - 1]) {
                            attempt()
                        }

                        return
                    }

                    p.reject($0)
                })
        }
        catch {
            p.reject(error)
        }
    }

    attempt()

    return p
}
