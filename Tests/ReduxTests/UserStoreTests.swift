//
//  UserStoreTests.swift
//  ReduxTests
//
//  Created by sungcheol.kim on 2021/11/06.
//  email: skyfe79@gmail.com
//  github: https://github.com/skyfe79
//  github: https://github.com/ReactComponentKit
//

import XCTest
@testable import Redux

final class UserStoreTests: XCTestCase {
    private var store: UserStore!
    
    override func setUp() {
        super.setUp()
        store = UserStore()
    }
    
    override func tearDown() {
        super.tearDown()
        store = nil
    }
    
    func testInitialState() {
        XCTAssertEqual([], store.state.users)
    }
    
    func testLoadUsers() async {
        await store.loadUsers()
        XCTAssertEqual(10, store.state.users.count)
        for user in store.state.users {
            XCTAssertGreaterThan(user.id, 0)
            XCTAssertNotEqual(user.name, "")
        }
    }
 
    func testUpdateUser() async {
        do {
            await store.loadUsers()
            XCTAssertEqual(10, store.state.users.count)
            var mutableUser = store.state.users[0]
            mutableUser.name = "Sungcheol Kim"
            try await store.update(user: mutableUser)
            XCTAssertEqual(10, store.state.users.count)
            let user = store.state.users[0]
            XCTAssertEqual("Sungcheol Kim", user.name)
        } catch {
            XCTFail("Failed update user")
        }
    }
}
