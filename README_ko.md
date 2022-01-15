[English](https://github.com/ReactComponentKit/Redux/blob/main/README.md) | [한국어](https://github.com/ReactComponentKit/Redux/blob/main/README_ko.md)

# Redux

![license MIT](https://img.shields.io/cocoapods/l/Redux.svg)
![Platform](https://img.shields.io/badge/iOS-%3E%3D%2013.0-green.svg)
![Platform](https://img.shields.io/badge/macos-%3E%3D%2010.15-green.svg)
![Xcode](https://img.shields.io/badge/xcode-%3E%3D%2013.2-orange.svg)
[![Swift 5.5](https://img.shields.io/badge/Swift-5.5-orange.svg?style=flat)](https://developer.apple.com/swift/)

Swift 5.5에서 소개된 async/await로 Redux를 구현하는 일이 매우 간소해졌습니다. Xcode 13.2 버전부터는 Swift 5.5의 새로운 Concurrency가 iOS 13을 지원한다고 합니다. 이에 기존의 Redux 패키지를 async/await 를 바탕으로 새로 구현하였습니다.

## 사용하기

Swift 패키지 매니저로 Redux 패키지를 설치할 수 있습니다. CocoaPods는 지원하지 않습니다.

```swift
dependencies: [
    .package(url: "https://github.com/ReactComponentKit/Redux.git", from: "1.2.0"),
]
```

## 흐름

![](./arts/flow.png)

위 그림은 Redux의 흐름을 나타낸 것입니다. 많은 내용이 있지만 실제로는 매우 간결합니다. 흐름 대부분을 Store가 처리합니다. 개발자가 해야할 일은 State와 Store를 정의하고 Action과 Mutation을 수행하는 함수를 정의하는 것 뿐입니다. 추가로 Mutation이 발생하기 전 또는 후에 필요한 작업을 할 수 있도록 미들웨어 성격의 Job을 정의할 수 있습니다.

## State 정의

State는 아래와 같이 정의할 수 있습니다.

```swift
struct Counter: State {
    var count = 0
}
```

주의할 점은 State는 Equatable을 준수해야 합니다.


## Store 정의

Store를 정의할 때, State가 필요합니다. 아래와 같이 Store를 정의할 수 있습니다.

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

Store는 다음 메서드를 제공합니다.

- commit(mutation:, payload:)
- dispatch(action:, payload:) async
- dispatch(action:, payload:)

사용자 정의 Store를 만들 때, 주로 사용하는 메서드는 commit(mutation:, payload:)가 될 것 입니다. dispatch(action:, payload:) 는 사용되는 경우가 매우 적습니다.

## Mutation 정의

Mutation은 스토어의 메서드로 정의합니다. Mutation 메서드는 sync 메서드입니다.

```swift
// mutation
private func increment(counter: inout Counter, payload: Int) {
    counter.count += payload
}
    
private func decrement(counter: inout Counter, payload: Int) {
    counter.count -= payload
}
```

## Action 정의

Action 도 Store의 메서드로 정의합니다. 더 이상 Action을 위해 따로 struct와 같은 타입을 만들 필요가 없습니다. Action을 Store의 메서드로 정의하기 때문에 실제로 Store의 dispatch 메서드를 사용하는 경우는 매우 적습니다. Action은 Sync Action 또는 Async Action으로 나누어 정의할 수 있습니다. 상태 변경은 commit mutation 에서 발생하기 때문에 비동기 처리를 위해서 부가적인 middleware를 정의할 필요가 없습니다. 비동기 액션에서 비동기 처리를 완료한 다음 변경사항을 커밋하면 됩니다.

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


## Computed

View 에 연결할 속성을 정의합니다. Store는 state를 Publish 하지 않습니다. 따라서 상태의 특정 속성을 Publish 하기 위해서, Computed 단계에서 해당 속성에 값을 주입할 수 있습니다.

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

지금까지 정의한 CounterStore의 전체 코드는 아래와 같습니다.

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


## Middleware 정의

선택적으로 Middleware를 추가할 수 있습니다. 미들웨어는 모든 Mutation이 commit되기 전과 후에 호출되는 동기 함수 모음입니다. 예를 들어 상태 변경을 디버깅하기 위해 로그를 출력하는 미들웨어를 정의할 수 있습니다.

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

위에서 정의한 CounterStore를 아주 쉽게 테스트할 수 있습니다.

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

[https://jsonplaceholder.typicode.com](https://jsonplaceholder.typicode.com) API를 사용하는 Store를 간략하게 작성해 보면 아래와 같습니다.

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

위 UserStore를 아래와 같이 테스트할 수 있습니다.

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

## Store 합성

Single Source of Truth 로 앱 상태를 한 곳에서 관리할 필요가 있습니다. 그럴 때, 한 State에 앱의 모든 State를 정의하는 것은 위험합니다. 그래서 State를 모듈 단위로 나누어서 각 State를 관리하는 Store를 만들어 관리하는 것이 좋습니다. 아래와 같이 AppStore를 정의할 수 있습니다.


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

위 AppStore를 아래와 같이 사용할 수 있습니다.

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

## Store 합성 예시

아래처럼 AppState와 AppStore를 구현하면 좋지 않습니다. 상태를 추가하면 할 수록 AppState는 물론 AppStore가 비대해지기 때문입니다.

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

그래서 아래와 같이 상태와 스토어를 관련 있는 것끼리 최대한 작게 나눈 후 나중에 한 곳의 스토어로 합성하는 것이 좋습니다.

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
    // 다른 스토어의 상태에 의존하는 상태입니다.
    var allLength: String = ""
}

class ComposeAppStore: Store<ComposeAppState> {
    let counter = CounterStore();
    let content = ContentStore();
    
    // UI 레이어에서 counter 네임스페이스를 갖는 counter.count로 접근하기 위해서 private로 설정합니다.
    @Published
    private var count = 0;
    
    @Published
    private var contentValue: String? = nil;
    
    @Published
    private var error: String? = nil;
    
    // 합성 상태의 computed 입니다.
    @Published
    var allLength: String? = nil;
    
    override func computed(new: ComposeAppState, old: ComposeAppState) {
        if (new.allLength != old.allLength) {
            self.allLength = new.allLength
        }
    }
    
    init() {
        super.init(state: ComposeAppState())
        // @Published 체이닝이 필요합니다.
        counter.$count.assign(to: &self.$count)
        content.$value.assign(to: &self.$contentValue)
        content.$error.assign(to: &self.$error)
    }
    
    // 다른 스토어의 상태와 액션에 의존하는 액션 및 상태 mutation을 아래와 같이 예로 들 수 있습니다.
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