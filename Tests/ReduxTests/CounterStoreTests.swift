//
//  CounterStoreTests.swift
//  ReduxTests
//
//  Created by sungcheol.kim on 2021/11/06.
//  email: skyfe79@gmail.com
//  github: https://github.com/skyfe79
//  github: https://github.com/ReactComponentKit
//

import XCTest
@testable import Redux

final class CounterStoreTests: XCTestCase {
    private var store: CounterStore!
    
    override func setUp() {
        super.setUp()
        store = CounterStore()
    }
    
    override func tearDown() {
        super.tearDown()
        store = nil
    }
    
    func testInitialState() {
        XCTAssertEqual(0, store.state.count)
    }
    
    func testIncrementAction() {
        store.incrementAction(payload: 1)
        XCTAssertEqual(1, store.state.count)
        store.incrementAction(payload: 10)
        XCTAssertEqual(11, store.state.count)
    }
    
    func testPublisherValue() async {
        XCTAssertEqual(0, store.count)
        
        store.incrementAction(payload: 1)
        await contextSwitching()
        XCTAssertEqual(1, store.count)
        
        store.incrementAction(payload: 10)
        await contextSwitching()
        XCTAssertEqual(11, store.count)
        
        store.decrementAction(payload: 10)
        await contextSwitching()
        XCTAssertEqual(1, store.count)
        
        store.decrementAction(payload: 1)
        await contextSwitching()
        XCTAssertEqual(0, store.count)
    }
    
    func testAsyncIncrementAction() async {
        await store.asyncIncrementAction(payload: 1)
        XCTAssertEqual(1, store.state.count)
        await store.asyncIncrementAction(payload: 10)
        XCTAssertEqual(11, store.state.count)
    }
    
    func testAsyncDecrementAction() async {
        await store.asyncDecrementAction(payload: 1)
        XCTAssertEqual(-1, store.state.count)
        await store.asyncDecrementAction(payload: 10)
        XCTAssertEqual(-11, store.state.count)
    }
}
