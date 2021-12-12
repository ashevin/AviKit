//
//  Promise.swift
// AviKit
//
// Created by Avi Shevin.
// Copyright © 2019 Avi Shevin. All rights reserved.
//

import Foundation
import Dispatch

enum Result<Value> {
    case success(Value)
    case failure(Error)

    func unwrap() throws -> Value {
        switch self {
            case .success(let v): return v
            case .failure(let e): throw e
        }
    }

    var success: Value? {
        if case let .success(value) = self {
            return value
        }

        return nil
    }

    var failure: Error? {
        if case let .failure(error) = self {
            return error
        }

        return nil
    }
}

public class Future<Value> {
    typealias Observer = (Result<Value>) -> ()

    private var lock = DispatchSemaphore(value: 1)

    fileprivate(set) var result: Result<Value>? {
        didSet {
            guard oldValue == nil else { return }

            result.map(report)
        }
    }

    var callbacks = [Observer]()

    func observe(with observer: @escaping Observer) {
        guard result != nil else {
            lock.wait()
            callbacks.append(observer)
            lock.signal()

            return
        }

        result.map(observer)
    }

    func report(_ result: Result<Value>) {
        lock.wait()
        callbacks.forEach { $0(result) }
        lock.signal()
    }
}


public final class Promise<Value>: Future<Value> {
    public typealias SuccessSignal = (Value) -> ()
    public typealias ErrorSignal = (Error) -> ()

    override public init() { }

    public convenience init(_ value: Value) {
        self.init()
        fulfill(value)
    }

    public convenience init(_ error: Error) {
        self.init()
        reject(error)
    }

    public convenience init(_ block: (_ fulfill: SuccessSignal, _ reject: ErrorSignal) -> ()) {
        self.init()

        block(
            { value in
                self.fulfill(value)
            },
            { error in
                self.reject(error)
            }
        )
    }

    @discardableResult
    func fulfill(_ value: Value) -> Promise {
        result = result ?? .success(value)

        return self
    }

    @discardableResult
    func reject(_ error: Error) -> Promise {
        result = result ?? .failure(error)

        return self
    }
}

public extension Promise {
    func then<NewValue>(on queue: DispatchQueue? = nil,
                        _ handler: @escaping (Value) throws -> Promise<NewValue>) -> Promise<NewValue>
    {
        let np = Promise<NewValue>()

        observe { result in
            let block = {
                do {
                    try handler(result.unwrap()).observe { np.result = $0 }
                }
                catch {
                    np.reject(error)
                }
            }

            run(block, on: queue)
        }

        return np
    }

    func then<NewValue>(on queue: DispatchQueue? = nil,
                        _ handler: @escaping (Value) throws -> NewValue) -> Promise<NewValue>
    {
        let np = Promise<NewValue>()

        observe { result in
            let block = {
                do {
                    np.fulfill(try handler(try result.unwrap()))
                }
                catch {
                    np.reject(error)
                }
            }

            run(block, on: queue)
        }

        return np
    }

    @discardableResult
    func then(on queue: DispatchQueue? = nil,
              _ handler: @escaping (Value) -> ()) -> Promise<Value>
    {
        observe { result in
            let block = {
                if case let .success(value) = result {
                    handler(value)
                }
            }

            run(block, on: queue)
        }

        return self
    }

    func finally(on queue: DispatchQueue? = nil,
                 _ handler: @escaping () -> ()) {
        observe { _ in run(handler, on: queue) }
    }

    @discardableResult
    func `catch`(on queue: DispatchQueue? = nil,
                 _ handler: @escaping (Error) -> ()) -> Promise<Value>
    {
        observe { result in
            let block = {
                if case let .failure(error) = result {
                    handler(error)
                }
            }

            run(block, on: queue)
        }

        return self
    }

    @discardableResult
    func mapError(_ handler: @escaping (Error) -> (Error)) -> Promise<Value> {
        let p = Promise<Value>()

        observe { result in
            switch result {
                case .success(let value): p.fulfill(value)
                case .failure(let error): p.reject(handler(error))
            }
        }

        return p
    }
}

#if compiler(>=5.5.2)
public extension Promise {
    func async() async throws -> Value {
        return try await withCheckedThrowingContinuation { continuation in
            self
                .observe { result in
                    switch result {
                        case .success(let value): continuation.resume(returning: value)
                        case .failure(let error): continuation.resume(throwing: error)
                    }
                }
        }
    }
}
#endif

public extension Promise {
    @available(*, deprecated, renamed: "fulfill")
    @discardableResult
    func signal(_ value: Value) -> Promise {
        fulfill(value)
    }

    @available(*, deprecated, renamed: "reject")
    @discardableResult
    func signal(_ error: Error) -> Promise {
        reject(error)
    }

    @available(*, deprecated, renamed: "catch")
    @discardableResult
    func error(on queue: DispatchQueue? = nil,
               _ handler: @escaping (Error) -> ()) -> Promise<Value>
    {
        `catch`(on: queue, handler)
    }
}

func run(_ block: @escaping () -> (), on queue: DispatchQueue?) {
    if let queue = queue {
        queue.async(execute: block)
    }
    else {
        block()
    }
}

extension Promise: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "Promise [\(Unmanaged<AnyObject>.passUnretained(self as AnyObject).toOpaque())]"
    }
}
