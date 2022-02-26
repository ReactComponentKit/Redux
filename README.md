[English](https://github.com/ReactComponentKit/Redux/blob/main/README.md) | [한국어](https://github.com/ReactComponentKit/Redux/blob/main/README_ko.md)

# Redux

![license MIT](https://img.shields.io/cocoapods/l/Redux.svg)
![Platform](https://img.shields.io/badge/iOS-%3E%3D%2013.0-green.svg)
![Platform](https://img.shields.io/badge/macos-%3E%3D%2010.15-green.svg)
![Xcode](https://img.shields.io/badge/xcode-%3E%3D%2013.2-orange.svg)
[![Swift 5.5](https://img.shields.io/badge/Swift-5.5-orange.svg?style=flat)](https://developer.apple.com/swift/)

Implementing Redux with async/await introduced in Swift 5.5 has become very simple. From Xcode 13.2, Swift 5.5's new concurrency supports iOS 13. Therefore, the existing Redux package was newly implemented based on async/await.

## Installation

Redux only support Swift Package Manager. 

```swift
dependencies: [
    .package(url: "https://github.com/ReactComponentKit/Redux.git", from: "1.2.1"),
]
```

## Flow

![](./arts/flow.png)

The figure above shows the flow of Redux. There's a lot of content, but it's actually very concise. The store handles most of the flow. All the developer has to do is define State and Store and define the functions that perform Action and Mutation. Additionally, middleware-like jobs can be defined so that you can do the necessary tasks before or after Mutation occurs.

## State

State can be defined as below.

```swift
struct Counter: State {
    var count = 0
}
```

Note that State should comply with Equatable.


## Store

When defining a store, a state is required. You can define the store as below.

```swift
struct Counter: State {
    var count = 0
}

class CounterStore: Store<Counter> {
    init() {
        super.init(state: Counter())
    }
}
```

The store provides the following methods.

- commit(mutation:, payload:)
- dispatch(action:, payload:) async
- dispatch(action:, payload:)

When creating a custom store, the method mainly used will be commit(mutation:, payload:). dispatch(action:, payload:) is very rarely used.

## Mutation

Mutation is defined as a store method. The Mutation method is a sync method.

```swift
// mutation
private func increment(counter: inout Counter, payload: Int) {
    counter.count += payload
}
    
private func decrement(counter: inout Counter, payload: Int) {
    counter.count -= payload
}
```

## Action

Action is also defined by the store's method. There is no need to create a separate custom data type for action anymore. Since Action is defined as a store method, there are very few cases where the store's dispatch method is actually used. 

Action can be defined by dividing it into Sync Action or Async Action. Since the state change occurs in the commit, there is no need to define additional middleware for asynchronous processing. You can complete asynchronous processing in the async action and then commit the changes.

```swift
// actions
func incrementAction(payload: Int) {
    self.commit(mutation: increment, payload: payload)
}
    
func decrementAction(payload: Int) {
    self.commit(mutation: decrement, payload: payload)
}
    
func asyncIncrementAction(payload: Int) async {
    await Task.sleep(1 * 1_000_000_000)
    self.commit(mutation: increment, payload: payload)
}
    
func asyncDecrementAction(payload: Int) async {
    await Task.sleep(1 * 1_000_000_000)
    self.commit(mutation: decrement, payload: payload)
}
```

Also, You can use simplified commit method to define action or mutate state.

```swift
func asyncIncrementAction(payload: Int) async {
    await Task.sleep(1 * 1_000_000_000)
    self.commit { mutableState in 
        mutableState.count += 1
    }
}
```

Store's `commit` method is public so you can use it on the UI layer.

```swift
Button(action: { store.counter.commit { $0.count += 1 }) {
    Text(" + ")
        .font(.title)
        .bold()
}
```

or use store's action method.

```swift
Button(action: { store.counter.incrementAction(payload: 1) }) {
    Text(" + ")
        .font(.title)
        .bold()
}
```


## Computed

Define the properties to connect to View. The store does not publish the state. Therefore, in order to publish a specific property of the state, a value can be injected into the property in the computed step.

```swift
class CounterStore: Store<Counter> {
    init() {
        super.init(state: Counter())
    }
    
    // computed
    @Published
    var count = 0
    
    override func computed(new: Counter, old: Counter) {
        self.count = new.count
    }
    ...
}
```

## CounterStore

The entire code of CounterStore defined so far is as follows.

```swift
import Foundation
import Redux

struct Counter: State {
    var count = 0
}

class CounterStore: Store<Counter> {
    init() {
        super.init(state: Counter())
    }
    
    // computed
    @Published
    var count = 0
    
    override func computed(new: Counter, old: Counter) {
        self.count = new.count
    }
    
    // mutation
    private func increment(counter: inout Counter, payload: Int) {
        counter.count += payload
    }
    
    private func decrement(counter: inout Counter, payload: Int) {
        counter.count -= payload
    }
    
    // actions
    func incrementAction(payload: Int) {
        self.commit(mutation: increment, payload: payload)
    }
    
    func decrementAction(payload: Int) {
        self.commit(mutation: decrement, payload: payload)
    }
    
    func asyncIncrementAction(payload: Int) async {
        await Task.sleep(1 * 1_000_000_000)
        self.commit(mutation: increment, payload: payload)
    }
    
    func asyncDecrementAction(payload: Int) async {
        await Task.sleep(1 * 1_000_000_000)
        self.commit(mutation: decrement, payload: payload)
    }
}
```


## Middlewares

You can optionally add middlewares. Middleware is a collection of functions called before or after all Mutations.

You can optionally add Middleware. Middleware is a collection of sync functions called before and after all mutations are commited. For example, you can define middleware that print logs to debug state changes.

```swift
class WorksBeforeCommitStore: Store<ReduxState> {
    init() {
        super.init(state: ReduxState())
    }
    
    override func worksBeforeCommit() -> [(ReduxState) -> Void] {
        return [
            { (state) in
                print(state.count)
            }
        ]
    }
}

class WorksAfterCommitStore: Store<ReduxState> {
    init() {
        super.init(state: ReduxState())
    }
    
    override func worksAfterCommit() -> [(ReduxState) -> Void] {
        return [
            { (state) in
                print(state.count)
            }
        ]
    }
}
```

## UnitTest

It is very easy to test the CounterStore defined above.

```swift
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
    
    func testPublisherValue() {
        XCTAssertEqual(0, store.count)
        store.incrementAction(payload: 1)
        XCTAssertEqual(1, store.count)
        store.incrementAction(payload: 10)
        XCTAssertEqual(11, store.count)
        store.decrementAction(payload: 10)
        XCTAssertEqual(1, store.count)
        store.decrementAction(payload: 1)
        XCTAssertEqual(0, store.count)
    }
    
    func testAsyncIncrementAction() async {
        await store.asyncIncrementAction(payload: 1)
        XCTAssertEqual(1, store.state.count)
        XCTAssertEqual(1, store.count)
        await store.asyncIncrementAction(payload: 10)
        XCTAssertEqual(11, store.state.count)
        XCTAssertEqual(11, store.count)
    }
    
    func testAsyncDecrementAction() async {
        await store.asyncDecrementAction(payload: 1)
        XCTAssertEqual(-1, store.state.count)
        XCTAssertEqual(-1, store.count)
        await store.asyncDecrementAction(payload: 10)
        XCTAssertEqual(-11, store.state.count)
        XCTAssertEqual(-11, store.count)
    }
}
```

## UserStore

Let's define a store that uses API([https://jsonplaceholder.typicode.com](https://jsonplaceholder.typicode.com)).

```swift
import Foundation
import Redux

struct User: Equatable, Codable {
    let id: Int
    var name: String
}

struct UserState: State {
    var users: [User] = []
}

class UserStore: Store<UserState> {
    
    init() {
        super.init(state: UserState())
    }
    
    // mutations
    private func SET_USERS(userState: inout UserState, payload: [User]) {
        userState.users = payload
    }
    
    private func SET_USER(userState: inout UserState, payload: User) {
        let index = userState.users.firstIndex { it in
            it.id == payload.id
        }
        
        if let index = index {
            userState.users[index] = payload
        }
    }
    
    // actions
    func loadUsers() async {
        do {
            let (data, _) = try await URLSession.shared.data(from: URL(string: "https://jsonplaceholder.typicode.com/users/")!)
            let users = try JSONDecoder().decode([User].self, from: data)
            commit(mutation: SET_USERS, payload: users)
        } catch {
            print(#function, error)
            commit(mutation: SET_USERS, payload: [])
        }
    }
    
    func update(user: User) async throws {
        let params = try JSONEncoder().encode(user)
        var request = URLRequest(url: URL(string: "https://jsonplaceholder.typicode.com/users/\(user.id)")!)
        request.httpMethod = "PUT"
        request.httpBody = params
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        let (data, _) = try await URLSession.shared.data(for: request)
        let user = try JSONDecoder().decode(User.self, from: data)
        commit(mutation: SET_USER, payload: user)
    }
}
```

You can test the above UserStore as follows.

```swift
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
```

## Store Composition

It is necessary to manage the app status in one place with Single Source of Truth. In that case, it is dangerous to define all states of the app in one state. Therefore, it is recommended to divide the state into modules and create and manage a store that manages each state. You can define the App Store as below.


```swift
import Foundation
import Redux

struct AppState: State {
}

class AppStore: Store<AppState> {
    
    // composition store
    let counter = CounterStore()
    let users = UserStore()
    
    init() {
        super.init(state: AppState())
    }
}
```

You can use the AppStore above as follows.

```swift
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
    
    func testPublisherValue() {
        XCTAssertEqual(0, store.counter.count)
        store.counter.incrementAction(payload: 1)
        XCTAssertEqual(1, store.counter.count)
        store.counter.incrementAction(payload: 10)
        XCTAssertEqual(11, store.counter.count)
        store.counter.decrementAction(payload: 10)
        XCTAssertEqual(1, store.counter.count)
        store.counter.decrementAction(payload: 1)
        XCTAssertEqual(0, store.counter.count)
    }
    
    func testAsyncIncrementAction() async {
        await store.counter.asyncIncrementAction(payload: 1)
        XCTAssertEqual(1, store.counter.state.count)
        XCTAssertEqual(1, store.counter.count)
        await store.counter.asyncIncrementAction(payload: 10)
        XCTAssertEqual(11, store.counter.state.count)
        XCTAssertEqual(11, store.counter.count)
    }
    
    func testAsyncDecrementAction() async {
        await store.counter.asyncDecrementAction(payload: 1)
        XCTAssertEqual(-1, store.counter.state.count)
        XCTAssertEqual(-1, store.counter.count)
        await store.counter.asyncDecrementAction(payload: 10)
        XCTAssertEqual(-11, store.counter.state.count)
        XCTAssertEqual(-11, store.counter.count)
    }
}
```

## Example Of Store Composition

We can define the AppStore like as below but it is not a good design. If you add more state to the AppState, the AppStore becomes more massive store.

```swift
struct AppState: State {
    var count: Int = 0
    var content: String? = nil
    var error: String? = nil
}

class AppStore: Store<AppState> {
    init() {
        super.init(state: AppState())
    }
    
    @Published
    var count: Int = 0
    
    @Published
    var content: String? = nil
    
    @Published
    var error: String? = nil
    
    override func computed(new: AppState, old: AppState) {
        if (self.count != new.count) {
            self.count = new.count
        }
        
        if (self.content != new.content) {
            self.content = new.content
        }
        
        if (self.error != new.error) {
            self.error = new.error
        }
    }
    
    override func worksAfterCommit() -> [(AppState) -> Void] {
        return [ { state in
            print(state.count)
        }]
    }
    
    private func INCREMENT(state: inout AppState, payload: Int) {
        state.count += payload
    }
    
    private func DECREMENT(state: inout AppState, payload: Int) {
        state.count -= payload
    }
    
    private func SET_CONTENT(state: inout AppState, payload: String) {
        state.content = payload
    }
    
    private func SET_ERROR(state: inout AppState, payload: String?) {
        state.error = payload
    }
    
    func incrementAction(payload: Int) {
        commit(mutation: INCREMENT, payload: payload)
    }
    
    func decrementAction(payload: Int) {
        commit(mutation: DECREMENT, payload: payload)
    }

    func fetchContent() async {
        do {
            let (data, _) = try await URLSession.shared.data(from: URL(string: "https://www.facebook.com")!)
            let value = String(data: data, encoding: .utf8) ?? ""
            commit(mutation: SET_ERROR, payload: nil)
            commit(mutation: SET_CONTENT, payload: value)
        } catch {
            commit(mutation: SET_ERROR, payload: error.localizedDescription)
        }
    }
}
```

It is a good practice to break the state into small pieces and then compose them to one store.

```swift

/**
 * CounterStore.swift
 */
struct Counter: State {
    var count: Int = 0
}

class CounterStore: Store<Counter> {
    @Published
    var count: Int = 0
    
    override func computed(new: Counter, old: Counter) {
        if (self.count != new.count) {
            self.count = new.count
        }
    }
    
    init() {
        super.init(state: Counter())
    }
    
    override func worksAfterCommit() -> [(Counter) -> Void] {
        return [ { state in
            print(state.count)
        }]
    }
    
    private func INCREMENT(state: inout Counter, payload: Int) {
        state.count += payload
    }
    
    private func DECREMENT(state: inout Counter, payload: Int) {
        state.count -= payload
    }
    
    func incrementAction(payload: Int) {
        commit(mutation: INCREMENT, payload: payload)
    }
    
    func decrementAction(payload: Int) {
        commit(mutation: DECREMENT, payload: payload)
    }
}

/**
 * ContentStore.swift
 */
struct Content: State {
    var value: String? = nil
    var error: String? = nil
}

class ContentStore: Store<Content> {
    @Published
    var value: String? = nil
    
    @Published
    var error: String? = nil
    
    override func computed(new: Content, old: Content) {
        if (self.value != new.value) {
            self.value = new.value
        }
        
        if (self.error != new.error) {
            self.error = new.error
        }
    }
    
    init() {
        super.init(state: Content())
    }
    
    override func worksAfterCommit() -> [(Content) -> Void] {
        return [
            { state in
                print(state.value ?? "없음")
            }
        ]
    }
    
    private func SET_CONTENT_VALUE(state: inout Content, payload: String) {
        state.value = payload
    }
    
    private func SET_ERROR(state: inout Content, payload: String?) {
        state.error = payload
    }
    
    func fetchContentValue() async {
        do {
            let (data, _) = try await URLSession.shared.data(from: URL(string: "https://www.facebook.com")!)
            let value = String(data: data, encoding: .utf8) ?? ""
            commit(mutation: SET_ERROR, payload: nil)
            commit(mutation: SET_CONTENT_VALUE, payload: value)
        } catch {
            commit(mutation: SET_ERROR, payload: error.localizedDescription)
        }
    }
}

/**
 * ComposeAppStore.swift
 */
struct ComposeAppState: State {
    // A state that depends on the state of another store.
    var allLength: String = ""
}

class ComposeAppStore: Store<ComposeAppState> {
    let counter = CounterStore();
    let content = ContentStore();
    
    // Set it to private to access counter.count with the counter namespace in the UI layer.
    @Published
    private var count = 0;
    
    @Published
    private var contentValue: String? = nil;
    
    @Published
    private var error: String? = nil;
    
    @Published
    var allLength: String? = nil;
    
    override func computed(new: ComposeAppState, old: ComposeAppState) {
        if (new.allLength != old.allLength) {
            self.allLength = new.allLength
        }
    }
    
    init() {
        super.init(state: ComposeAppState())
        // @Published chaining is required.
        counter.$count.assign(to: &self.$count)
        content.$value.assign(to: &self.$contentValue)
        content.$error.assign(to: &self.$error)
    }
    
    //Examples of actions and state mutations that depend on the state and actions of other stores are
    private func SET_ALL_LENGTH(state: inout ComposeAppState, payload: String) {
        state.allLength = payload
    }
    func someComposeAction() async {
        await content.fetchContentValue()
        commit(mutation: SET_ALL_LENGTH, payload: "counter: \(counter.state.count), content: \(content.state.value?.count ?? 0)")
    }
}

/**
 * ContentView.swift
 */
import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject
    private var store: ComposeAppStore
    
    var body: some View {
        
        VStack {
            Text("\(store.counter.count)")
                .font(.title)
                .bold()
                .padding()
            if let error = store.content.error {
                Text("Error! \(error)")
            }
            HStack {
                Spacer()
                
                Button(action: { store.counter.decrementAction(payload: 1) }) {
                    Text(" - ")
                        .font(.title)
                        .bold()
                }
                
                Spacer()
                
                Button(action: { store.counter.incrementAction(payload: 1) }) {
                    Text(" + ")
                        .font(.title)
                        .bold()
                }
                
                Spacer()
                
            }
            VStack {
                Button(action: {
                    Task {
                        await store.someComposeAction()
                    }
                }) {
                    Text("All Length")
                        .bold()
                        .multilineTextAlignment(.center)
                }
                Text(store.allLength ?? "")
                    .foregroundColor(.red)
                    .font(.system(size: 12))
                    .lineLimit(5)
                
                Button(action: {
                    Task {
                        await store.content.fetchContentValue()
                    }
                }) {
                    Text("Fetch Content")
                        .bold()
                        .multilineTextAlignment(.center)
                }
                Text(store.content.value ?? "")
                    .foregroundColor(.red)
                    .font(.system(size: 12))
                    .lineLimit(5)
            }
        }
        .padding(.horizontal, 100)
    }
}
```


## MIT License

Copyright (c) 2021 Redux, ReactComponentKit

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.