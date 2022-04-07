//
//  AsyncEnumTypeTests.swift
//  Redux
//
//  Created by burt on 2022/04/07.
//

import XCTest
@testable import Redux

enum SomeError: Error {
    case systemError(code: Int)
    case unknownError
}

struct SomeState: State {
    var count: Async<Int> = .idle
}

class SomeStore: Store<SomeState> {
    init() {
        super.init(state: SomeState())
    }
    
    @Published
    var count: Async<Int> = .idle
    
    override func computed(new: SomeState, old: SomeState) {
        if new.count != old.count {
            count = new.count
        }
    }
    
    func asyncIncrement() async {
        try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
        self.commit { mutable in
            if case let .value(count) = mutable.count {
                mutable.count = .value(value: count + 1)
            } else {
                mutable.count = .value(value: 1)
            }
        }
    }
}

final class AsyncEnumTypeTests: XCTestCase {
    private var store: SomeStore!
    
    override func setUp() {
        super.setUp()
        store = SomeStore()
    }
    
    override func tearDown() {
        super.tearDown()
        store = nil
    }
    
    func testIdleStateEquality() {
        let a1: Async<Int> = .idle
        let a2: Async<Int> = .idle
        let a3: Async<String> = .idle
        let a4: Async<String> = .idle
        
        XCTAssertEqual(a1 == a2, true)
        XCTAssertEqual(a1 != a2, false)
        XCTAssertEqual(a3 == a4, true)
        XCTAssertEqual(a3 != a4, false)
        XCTAssertEqual(a1 == a3, false)
        XCTAssertEqual(a1 != a3, true)
    }
    
    func testLoadingStateEquality() {
        let a1: Async<Int> = .loading
        let a2: Async<Int> = .loading
        let a3: Async<String> = .loading
        let a4: Async<String> = .loading
        
        XCTAssertEqual(a1 == a2, true)
        XCTAssertEqual(a1 != a2, false)
        XCTAssertEqual(a3 == a4, true)
        XCTAssertEqual(a3 != a4, false)
        XCTAssertEqual(a1 == a3, false)
        XCTAssertEqual(a1 != a3, true)
    }
    
    func testValueStateEqualityWhenGivenSameValue() {
        let a1: Async<Int> = .value(value: 10)
        let a2: Async<Int> = .value(value: 10)
        let a3: Async<String> = .value(value: "Hello")
        let a4: Async<String> = .value(value: "Hello")
        
        XCTAssertEqual(a1 == a2, true)
        XCTAssertEqual(a1 != a2, false)
        XCTAssertEqual(a3 == a4, true)
        XCTAssertEqual(a3 != a4, false)
        XCTAssertEqual(a1 == a3, false)
        XCTAssertEqual(a1 != a3, true)
    }
    
    func testValueStateEqualityWhenGivenDifferentValue() {
        let a1: Async<Int> = .value(value: 10)
        let a2: Async<Int> = .value(value: 99)
        let a3: Async<String> = .value(value: "Hello")
        let a4: Async<String> = .value(value: "World")
        
        XCTAssertEqual(a1 == a2, false)
        XCTAssertEqual(a1 != a2, true)
        XCTAssertEqual(a3 == a4, false)
        XCTAssertEqual(a3 != a4, true)
        XCTAssertEqual(a1 == a3, false)
        XCTAssertEqual(a1 != a3, true)
    }
    
    func testErrorStateEqualityWhenGivenNilError() {
        let a1: Async<Int> = .error(value: nil)
        let a2: Async<Int> = .error(value: nil)
        let a3: Async<String> = .error(value: nil)
        let a4: Async<String> = .error(value: nil)
        
        XCTAssertEqual(a1 == a2, true)
        XCTAssertEqual(a1 != a2, false)
        XCTAssertEqual(a3 == a4, true)
        XCTAssertEqual(a3 != a4, false)
        XCTAssertEqual(a1 == a3, false)
        XCTAssertEqual(a1 != a3, true)
    }
    
    func testErrorStateEqualityWhenGivenSameError() {
        let a1: Async<Int> = .error(value: SomeError.unknownError)
        let a2: Async<Int> = .error(value: SomeError.unknownError)
        let a3: Async<Int> = .error(value: SomeError.systemError(code: 100))
        let a4: Async<Int> = .error(value: SomeError.systemError(code: 100))
        
        XCTAssertEqual(a1 == a2, true)
        XCTAssertEqual(a1 != a2, false)
        XCTAssertEqual(a3 == a4, true)
        XCTAssertEqual(a3 != a4, false)
        XCTAssertEqual(a1 == a3, false)
        XCTAssertEqual(a1 != a3, true)
    }
    
    func testErrorStateEqualityWhenGivenDifferentError() {
        let a1: Async<Int> = .error(value: SomeError.unknownError)
        let a2: Async<Int> = .error(value: SomeError.systemError(code: 400))
        let a3: Async<Int> = .error(value: SomeError.systemError(code: 404))
        let a4: Async<Int> = .error(value: SomeError.systemError(code: 500))
        let a5: Async<String> = .error(value: SomeError.unknownError)
        let a6: Async<String> = .error(value: SomeError.systemError(code: 500))
        
        XCTAssertEqual(a1 == a2, false)
        XCTAssertEqual(a1 != a2, true)
        XCTAssertEqual(a3 == a4, false)
        XCTAssertEqual(a3 != a4, true)
        XCTAssertEqual(a1 == a3, false)
        XCTAssertEqual(a1 != a3, true)
        XCTAssertEqual(a1 == a5, false)
        XCTAssertEqual(a1 != a5, true)
        XCTAssertEqual(a4 == a6, false)
        XCTAssertEqual(a4 != a6, true)
    }
    
    func testIncrementAsyncCount() async {
        await store.asyncIncrement()
        XCTAssertEqual(store.state.count, .value(value: 1))
        await contextSwitching()
        XCTAssertEqual(store.count, .value(value: 1))
    }
}

