//
//  SSOTTests.swift
//  ReduxTests
//
//  Created by sungcheol.kim on 2021/11/06.
//  email: skyfe79@gmail.com
//  github: https://github.com/skyfe79
//  github: https://github.com/ReactComponentKit
//

import XCTest
@testable import Redux

// Single Source of Truth
final class SSOTTests: XCTestCase {
    private var store: AppStore!
    
    override func setUp() {
        super.setUp()
        store = AppStore()
    }
    
    override func tearDown() {
        super.tearDown()
        store = nil
    }
    
    func testLoadUsers() async {
        await store.users.loadUsers()
        XCTAssertEqual(10, store.users.state.users.count)
        for user in store.users.state.users {
            XCTAssertGreaterThan(user.id, 0)
            XCTAssertNotEqual(user.name, "")
        }
    }
 
    func testUpdateUser() async {
        do {
            await store.users.loadUsers()
            XCTAssertEqual(10, store.users.state.users.count)
            var mutableUser = store.users.state.users[0]
            mutableUser.name = "Sungcheol Kim"
            try await store.users.update(user: mutableUser)
            XCTAssertEqual(10, store.users.state.users.count)
            let user = store.users.state.users[0]
            XCTAssertEqual("Sungcheol Kim", user.name)
        } catch {
            XCTFail("Failed update user")
        }
    }
    
    func testIncrementAction() {
        store.counter.incrementAction(payload: 1)
        XCTAssertEqual(1, store.counter.state.count)
        store.counter.incrementAction(payload: 10)
        XCTAssertEqual(11, store.counter.state.count)
    }
    
    func testPublisherValue() async {
        XCTAssertEqual(0, store.counter.count)
        store.counter.incrementAction(payload: 1)
        await contextSwitching()
        XCTAssertEqual(1, store.counter.count)
        
        store.counter.incrementAction(payload: 10)
        await contextSwitching()
        XCTAssertEqual(11, store.counter.count)
        
        store.counter.decrementAction(payload: 10)
        await contextSwitching()
        XCTAssertEqual(1, store.counter.count)
        
        store.counter.decrementAction(payload: 1)
        await contextSwitching()
        XCTAssertEqual(0, store.counter.count)
    }
    
    func testAsyncIncrementAction() async {
        await store.counter.asyncIncrementAction(payload: 1)
        XCTAssertEqual(1, store.counter.state.count)
        await contextSwitching()
        XCTAssertEqual(1, store.counter.count)
        
        await store.counter.asyncIncrementAction(payload: 10)
        XCTAssertEqual(11, store.counter.state.count)
        await contextSwitching()
        XCTAssertEqual(11, store.counter.count)
    }
    
    func testAsyncDecrementAction() async {
        await store.counter.asyncDecrementAction(payload: 1)
        XCTAssertEqual(-1, store.counter.state.count)
        await contextSwitching()
        XCTAssertEqual(-1, store.counter.count)
        
        await store.counter.asyncDecrementAction(payload: 10)
        XCTAssertEqual(-11, store.counter.state.count)
        await contextSwitching()
        XCTAssertEqual(-11, store.counter.count)
    }
}
