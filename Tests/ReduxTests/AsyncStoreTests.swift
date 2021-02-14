//
//  AsyncStoreTest.swift
//  Redux
//
//  Created by burt on 2021/02/11.
//

import XCTest
@testable import Redux

final class AsyncStoreTests: XCTestCase {
    
    private var store: AsyncStore!
    
    override func setUp() {
        super.setUp()
        store = AsyncStore()
    }
    
    override func tearDown() {
        super.tearDown()
        store = nil
    }
    
    func testInitialState() {
        XCTAssertEqual(Async<String>.uninitialized, store.state.content)
        XCTAssertNil(store.state.error)
    }
        
    func testAsyncAction() {
        let test = Test<AsyncState>()

        test
            .dispatch(action: FetchContentAction())
            .to(store)

        wait(for: test) { state in
            XCTAssertNotNil(state.content.value)
            XCTAssertEqual(true, state.content.isSuccess)
        }
    }
    
    static var allTests = [
        ("testInitialState", testInitialState),
    ]
}
