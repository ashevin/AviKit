//
//  Utility.swift
// AviKit
//
// Created by Avi Shevin.
// Copyright © 2019 Avi Shevin. All rights reserved.
//

import Foundation
import Dispatch

public func serialize<Return>(_ task: (@escaping (Return?, Error?) -> ()) -> ()) throws -> Return? {
    let dispatchGroup = DispatchGroup()
    dispatchGroup.enter()

    var errorToThrow: Error? = nil
    var returnValue: Return? = nil

    task { (value: Return?, error: Error?) -> Void in
        errorToThrow = error
        returnValue = value

        dispatchGroup.leave()
    }

    dispatchGroup.wait()

    if let error = errorToThrow {
        throw error
    }

    return returnValue
}

public func promise<Return>(_ task: (@escaping (Return?, Error?) -> ()) -> ()) -> Promise<Return> {
    let p = Promise<Return>()

    task { (value: Return?, error: Error?) -> Void in
        if let error = error {
            p.signal(error)
        }

        if let value = value {
            p.signal(value)
        }
    }

    return p
}

public func observable<Return>(_ task: (@escaping (Return?, Error?) -> ()) -> ()) -> Observer<Return> {
    let o = Observer<Return>()

    task { (value: Return?, error: Error?) -> Void in
        if let error = error {
            o.error(error)
        }

        if let value = value {
            o.next(value)
            o.finish()
        }
    }

    return o
}
