//
//  Test.swift
//  Redux
//
//  Created by burt on 2021/02/08.
//

import Foundation
import XCTest
@testable import Redux

public typealias Assertion<S: State> = (S) -> Swift.Void

public class Test<S: State> {
    private var description: String
    private var actionQueue: [(Action?, Assertion<S>?)] = []
    
    internal var expectation: XCTestExpectation?
    internal weak var store: Store<S>?
    
    public init(_ description: String = "") {
        self.description = description
    }
    
    public func reset(store: Store<S>, state: S) {
        store.reset(with: state)
    }
    
    public func dispatch(action: Action) -> Test {
        actionQueue.insert((action, nil), at: 0)
        return self
    }
    
    public func dispatch(middleware: @escaping (S, SideEffect<S>) -> Swift.Void) -> Test {
        func makeMiddleware(actionName: String) -> Middleware<S> {
            return { (state: S, action: Action, sideEffect: @escaping SideEffect<S>) in
                guard
                    action is ImplicitAction<Int>,
                    action.name == actionName
                else {
                    return
                }
                middleware(state, sideEffect)
            }
        }
        
        let actionName = "\(Date().timeIntervalSince1970)"
        let actionJob = Job<S>(middlewares: [
            makeMiddleware(actionName: actionName)
        ])
        let action = ImplicitAction(payload: -1, name: actionName, job: actionJob)
        return dispatch(action: action)
    }
    
    public func dispatch<T>(payload: T, middleware: @escaping (S, T, SideEffect<S>) -> Swift.Void) -> Test {
        func makeMiddleware(actionName: String) -> Middleware<S> {
            return { (state: S, action: Action, sideEffect: @escaping SideEffect<S>) in
                guard
                    action is ImplicitAction<T>,
                    let value: T = action.get()
                else {
                    return
                }
                middleware(state, value, sideEffect)
            }
        }
        
        let actionName = "\(Date().timeIntervalSince1970)"
        let actionJob = Job<S>(middlewares: [
            makeMiddleware(actionName: actionName)
        ])
        let action = ImplicitAction(payload: payload, name: actionName, job: actionJob)
        return dispatch(action: action)
    }
    
    public func dispatch<T>(_ keyPath: WritableKeyPath<S, T>, payload: T, reducer: @escaping (S, T) -> S) -> Test {
        func makeReducer(actionName: String) -> Reducer<S> {
            return { (state: S, action: Action) -> S in
                guard
                    action is ImplicitAction<T>,
                    action.name == actionName,
                    let value: T = action.get()
                else {
                    return state
                }
                return reducer(state, value)
            }
        }
        
        let actionName = "\(Date().timeIntervalSince1970)"
        let actionJob = Job<S>(reducers: [
            makeReducer(actionName: actionName)
        ]) { (state, newState) in
            state[keyPath: keyPath] = newState[keyPath: keyPath]
        }
        let action = ImplicitAction(payload: payload, name: actionName, job: actionJob)
        return dispatch(action: action)
    }
    
    public func test(_ assert: @escaping Assertion<S>) -> Test {
        actionQueue.insert((nil, assert), at: 0)
        return self
    }
    
    public func to(_ store: Store<S>?) {
        self.store = store
        self.expectation = XCTestExpectation(description: self.description)
    }
    
    fileprivate func wait(_ testCase: XCTestCase, timeout: TimeInterval, result: @escaping (S) -> Swift.Void) {
        guard
            let store = self.store,
            let expectation = self.expectation
        else {
            return
        }
        
        store.wait { [weak self] (state) in
            guard let strongSelf = self else { return }
            if strongSelf.actionQueue.isEmpty {
                result(state)
                expectation.fulfill()
            } else {
                if let (action, assertion) = strongSelf.actionQueue.popLast() {
                    if let action = action {
                        store.test(action: action)
                    }
                    if let assertion = assertion {
                        assertion(store.state)
                        store.againTest()
                    }
                }
            }
        }
        
        if let (action, assertion) = self.actionQueue.popLast() {
            if let action = action {
                store.test(action: action)
            }
            if let assertion = assertion {
                assertion(store.state)
                store.againTest()
            }
        }
        testCase.wait(for: [expectation], timeout: timeout)
    }
}

extension Store {
    
}

extension XCTestCase {
    public func wait<S: State>(for test: Test<S>, timeout: TimeInterval = 10, result: @escaping (S) -> Swift.Void) {
        test.wait(self, timeout: timeout, result: result)
    }
}
