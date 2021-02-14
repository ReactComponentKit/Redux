//
//  DispatchTests.swift
//  ReduxTests
//
//  Created by burt on 2021/02/14.
//

import XCTest
@testable import Redux

struct MyState: State {
    var value: String = ""
    var error: (Error, Action)?
}

class MyStore: Store<MyState> {
}

class DispatchTests: XCTestCase {

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
        test.dispatch(\.value, payload: "Hello") { (state, action) in
            return state.copy { (mutation) in
                mutation.value = action.get() ?? ""
            }
        }
        .to(store)
        
        wait(for: test) { state in
            XCTAssertEqual("Hello", state.value)
        }
    }
    
    func testDispatchActionReducerWithMiddleware() {
        let test = Test<MyState>()
        test.dispatch(payload: "1234") { (state, action, sideEffect) in
            let(_, context) = sideEffect()
            Thread.sleep(forTimeInterval: 1)
            context.dispatch(\.value, payload: (action.get() ?? "") + "5678") { (state, action) -> MyState in
                return state.copy { mutation in
                    mutation.value = action.get() ?? ""
                }
            }
        }
        .to(store)
        
        wait(for: test) { state in
            XCTAssertEqual("12345678", state.value)
        }
        
        test.dispatch(payload: 100) { (state, action, sideEffect) in
            let(_, context) = sideEffect()
            Thread.sleep(forTimeInterval: 1)
            context.dispatch(\.value, payload: "\(action.getOr(0)),200") { (state, action) -> MyState in
                return state.copy { mutation in
                    mutation.value = action.get() ?? ""
                }
            }
        }
        .to(store)
        
        wait(for: test) { state in
            XCTAssertEqual("100,200", state.value)
        }
    }
}
