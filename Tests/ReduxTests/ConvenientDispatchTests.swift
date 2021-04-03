//
//  DispatchTests.swift
//  ReduxTests
//
//  Created by burt on 2021/02/14.
//

import XCTest
@testable import Redux

struct OtherValue {
    var something: Int = 0
}

struct MyState: State {
    var asyncValue: Async<String> = .uninitialized
    var value: String = ""
    var otherValue: OtherValue = OtherValue()
    var error: (Error, Action)?
}

class MyStore: Store<MyState> {
}

class ConvenientDispatchTests: XCTestCase {

    private var store: MyStore!
    
    override func setUp() {
        super.setUp()
        store = MyStore()
    }
    
    override func tearDown() {
        super.tearDown()
        store = nil
    }

    func testDispatchActionReducer() {
        let test = Test<MyState>()
        test.dispatch(\.value, payload: "Hello") { (state, value) in
            return state.copy { (mutation) in
                mutation.value = value
            }
        }
        .to(store)
        
        wait(for: test) { state in
            XCTAssertEqual("Hello", state.value)
        }
    }
    
    func testDispatchActionReducerWithMiddleware() {
        let test = Test<MyState>()
        test.dispatch(payload: "1234") { (state, value, sideEffect) in
            let(_, context) = sideEffect()
            Thread.sleep(forTimeInterval: 1)
            context?.dispatch(\.value, payload: value + "5678") { (state, value) -> MyState in
                return state.copy { mutation in
                    mutation.value = value
                }
            }
        }
        .to(store)
        
        wait(for: test) { state in
            XCTAssertEqual("12345678", state.value)
        }
        
        test.dispatch(payload: 100) { (state, value, sideEffect) in
            let(_, context) = sideEffect()
            Thread.sleep(forTimeInterval: 1)
            context?.dispatch(\.value, payload: "\(value),200") { (state, value) -> MyState in
                return state.copy { mutation in
                    mutation.value = value
                }
            }
        }
        .to(store)
        
        wait(for: test) { state in
            XCTAssertEqual("100,200", state.value)
        }
    }
    
    func testUpdateNestedValue() {
        let test = Test<MyState>()
        test.dispatch(\MyState.otherValue.something, payload: 999) { (state, value) -> MyState in
            return state.copy { mutation in
                mutation.otherValue.something = value
            }
        }
        .to(store)
        
        wait(for: test) { state in
            XCTAssertEqual(999, state.otherValue.something)
        }
    }
    
    func testUpdateAsyncValue() {
        let test = Test<MyState>()
        test.dispatch { (state, sideEffect) in
            let (_, context) = sideEffect()
            context?.updateAsync(\.asyncValue, payload: .loading)
        }
        .test { (state) in
            XCTAssertEqual(Async<String>.loading, state.asyncValue)
        }
        .dispatch(payload: "Hello", middleware: { (state, value, sideEffect) in
            Thread.sleep(forTimeInterval: 3)
            let (_, context) = sideEffect()
            context?.updateAsync(\.asyncValue, payload: .success(value: value))
        })
        .test { state in
            XCTAssertTrue(state.asyncValue.isSuccess)
        }
        .to(store)
        
        wait(for: test) { state in
            XCTAssertEqual("Hello", state.asyncValue.value)
        }
    }
}
