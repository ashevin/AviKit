//
// Observables.swift
// AviKit
//
// Created by Avi Shevin.
// Copyright © 2019 Avi Shevin. All rights reserved.
//

import Foundation
import Dispatch

@propertyWrapper public struct PrivateObservable<Value> {
    public let wrappedValue: Observer<Value>
    public let projectedValue: Observable<Value>

    public init(wrappedValue: Observer<Value>) {
        self.wrappedValue = wrappedValue

        projectedValue = Observable<Value>()

        projectedValue.link(observer: wrappedValue)
    }
}

@propertyWrapper public struct ObservableProperty<Value> {
    public var wrappedValue: Value {
        didSet { observable.next(wrappedValue) }
    }

    private let observable = Observable<Value>()

    public let projectedValue: Observer<Value>

    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue

        projectedValue = observable.observer()
    }
}

@available(*, deprecated)
public final class StatefulObservable<Value>: Observer<Value> {
    public private(set) var value: Value?
    
    @discardableResult
    override public func on(queue: DispatchQueue? = nil,
                            next: @escaping (Value) -> Void)
        -> Observer<Value>
    {
        let wasZero = buffer.isEmpty
        
        super.on(queue: queue, next: next)
        
        if let value = value, wasZero {
            super.next(value)
        }
        
        return self
    }
    
    override public func next(_ value: Value) {
        self.value = value
        
        super.next(value)
    }
}

public final class NotificationObserver: Observer<Notification> {
    private var token: NSObjectProtocol
    
    public init(name: Notification.Name,
                object: Any? = nil,
                center: NotificationCenter = .default,
                queue: OperationQueue? = nil)
    {
        token = NSObject()
        
        super.init()
        
        token = center.addObserver(forName: name,
                                   object: object,
                                   queue: queue,
                                   using: { [weak self] notification in
                                    self?.next(notification)
        })
    }
    
    deinit {
        NotificationCenter.default.removeObserver(token)
    }
}

public final class DebouncingObservable<Value>: Observer<Value> {
    let delay: TimeInterval
    
    var workItem: DispatchWorkItem?
    
    let queue = DispatchQueue.global()
    
    public init(delay: TimeInterval) {
        self.delay = delay
        
        super.init()
    }
    
    override public func next(_ value: Value) {
        self.workItem?.cancel()
        
        let next = super.next
        let workItem = DispatchWorkItem(block: { [weak self] in
            if self?.workItem?.isCancelled == false {
                next(value)
            }
        })
        
        self.workItem = workItem
        
        queue.asyncAfter(deadline: .now() + delay, execute: workItem)
    }
}

public final class DistinctObservable<Value: Equatable>: Observer<Value> {
    var previousValue: Value? = nil

    override public func next(_ value: Value) {
        guard previousValue == nil || previousValue != value else {
            return
        }

        previousValue = value

        super.next(value)
    }
}

#if os(iOS)
import UIKit

public final class ActionObserver<T: UIControl>: Observer<T> {
    public init(source: T, event: UIControl.Event) {
        super.init()
        
        source.addTarget(self, action: #selector(action(_:)), for: event)
    }
    
    @objc func action(_ sender: Any) {
        if let sender = sender as? T {
            super.next(sender)
        }
    }
}
#endif

#if !os(Linux)
public final class KVOObserver<Type, ValueType>: Observer<(new: ValueType, old: ValueType?)> {
    private enum Errors: Error {
        case invalidKeyPath
    }
    
    private class Observer: NSObject {
        fileprivate weak var kvoObserver: KVOObserver?
        
        @objc override func observeValue(forKeyPath keyPath: String?,
                                         of object: Any?,
                                         change: [NSKeyValueChangeKey : Any]?,
                                         context: UnsafeMutableRawPointer?) {
            let new = change?[NSKeyValueChangeKey.newKey]
            let old = change?[NSKeyValueChangeKey.oldKey]
            
            if let new = new as? ValueType {
                kvoObserver?.next((new: new, old: old as? ValueType))
            }
        }
    }
    
    private class OnDelete: NSObject {
        private let block: () -> ()
        
        init(block: @escaping () -> ()) {
            self.block = block
        }
        
        deinit {
            block()
        }
    }
    
    private let observer: Observer
    private var object: Unmanaged<NSObject>?
    
    private let keyPath: String
    
    public init(object: NSObject, keyPath: KeyPath<Type, ValueType>,
                options: NSKeyValueObservingOptions = [.new])
    {
        guard let stringPath = keyPath._kvcKeyPathString else {
            fatalError("Missing _kvcKeyPathString")
        }
        
        self.observer = Observer()
        self.object = Unmanaged.passUnretained(object)
        self.keyPath = stringPath
        
        super.init()
        
        observer.kvoObserver = self
        object.addObserver(observer, forKeyPath: self.keyPath, options: options.union([.new]), context: nil)
        
        let deletion = OnDelete { [weak self] in self?.cancel() }
        objc_setAssociatedObject(object,
                                 Unmanaged.passUnretained(self).toOpaque(),
                                 deletion,
                                 .OBJC_ASSOCIATION_RETAIN)
    }
    
    private func cancel() {
        object?.takeUnretainedValue().removeObserver(observer, forKeyPath: keyPath)
        object = nil
    }
    
    deinit {
        cancel()
    }
}
#endif
