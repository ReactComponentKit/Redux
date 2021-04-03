# Redux

Manage SwiftUI's state with Redux and Combine :)

## Counter Example

### Define State

```swift
struct AppState: State {
    var count: Int = 0
    var error: (Error, Action)? = nil
}
```

### Define Middlewares

```swift
enum MyError: Error {
    case tempError
}

enum MyError: Error {
    case tempError
}

func asyncJob(state: AppState, action: Action, sideEffect: @escaping SideEffect<AppState>) {
    let (dispatch, _) = sideEffect()
    Thread.sleep(forTimeInterval: 2)
    dispatch(IncrementAction(payload: 2))
}

func asyncJobWithError(state: AppState, action: Action, sideEffect: @escaping SideEffect<AppState>) {
    Thread.sleep(forTimeInterval: 2)
    let (_, context) = sideEffect()
    context?.dispatch(\.error, payload: (MyError.tempError, action)) { (state, error) -> AppState in
        return state.copy { mutable in
            mutable.error = error
        }
    }
}
```

### Define Reducers

```swift
func counterReducer(state: AppState, action: Action) -> AppState {
    return state.copy { (mutation) in
        switch action {
        case let act as IncrementAction:
            mutation.count += act.payload
        case let act as DecrementAction:
            mutation.count -= act.payload
        default:
            break
        }
    }
}
```

### Define Actions

```swift
struct AsyncIncrementAction: Action {
    static var job: ActionJob {
        Job<AppState>(middleware: [asyncJob])
    }
}

struct IncrementAction: Action {
    let payload: Int
    init(payload: Int = 1) {
        self.payload = payload
    }
    
    static var job: ActionJob {
        Job<AppState>(reducers: [counterReducer]) { state, newState in
            state.count = newState.count
        }
    }
}

struct DecrementAction: Action {
    let payload: Int
    init(payload: Int = 1) {
        self.payload = payload
    }
    
    static var job: ActionJob {
        Job(reducers: [counterReducer]) { state, newState in
            state.count = newState.count
        }
    }
}

struct TestAsyncErrorAction: Action {
    static var job: ActionJob {
        Job<AppState>(middleware: [asyncJobWithError])
    }
}
```

### Define Store

```swift
class AppStore: Store<AppState> {
    override func beforeProcessingAction(state: AppState, action: Action) -> (AppState, Action)? {
        // do whatever you need to
        return (
            state.copy({ mutation in
                mutation.error = nil
            }),
            action
        )
    }

    override func afterProcessingAction(state: AppState, action: Action) {
        // do whatever you need to
        print("[## \(action) ##]")
        print(state)
    }
}
```

### Abstract Async State Value

```swift
struct AppState: State {
    var content: Async<String> = .uninitialized
}
```

### Define Middlewares

```swift
func fetchContent(state: AppState, action: Action, sideEffect: @escaping SideEffect<AppState>) {
    var (dispatch, context) = sideEffect()
    
    // if you need to access the store
    let store: AppStore = context.store()
    
    URLSession.shared.dataTaskPublisher(for: URL(string: "https://www.google.com")!)
        .subscribe(on: DispatchQueue.global())
        .receive(on: DispatchQueue.global())
        .sink { (completion) in
            switch completion {
            case .finished:
                break
            case .failure(let error):
                dispatch(UpdateContentAction(content: .failed(error: error)))
            }
        } receiveValue: { (data, response) in
            let value = String(data: data, encoding: .utf8) ?? ""
            dispatch(UpdateContentAction(content: .success(value: value)))
        }
        .store(in: &context.cancellable)

}
```

### Define Reducers

```swift
func updateContent(state: AppState, action: Action) -> AppState {
    guard let action = action as? UpdateContentAction else { return state }
    return state.copy { mutation in
        mutation.content = action.content
    }
}
```

### Define Actions

```swift
struct RequestContentAction: Action {
    static var job: ActionJob {
        Job<AppState>(middleware: [fetchContent])
    }
}

struct UpdateContentAction: Action {
    let content: Async<String>
    
    static var job: ActionJob {
        Job<AppState>(reducers: [updateContent]) { (state, newState) in
            state.content = newState.content
        }
    }
}
```

### Consume Async State

```swift
VStack {
    Button(action: { store.dispatch(action: RequestContentAction()) }) {
        Text("Fetch Content")
            .bold()
            .multilineTextAlignment(.center)
    }
    ScrollView(.vertical) {
        Text(store.state.content.value ?? store.state.content.error?.localizedDescription ?? "")
    }
    .frame(width: UIApplication.shared.windows.first?.frame.width)
}
```

## Testing

### CounterStore Example for Testing

```swift
import Foundation

struct CounterState: State {
    var count: Int = 0
}

class CounterStore: Store<CounterState> {
}

struct IncrementAction: Action {
    let payload: Int
    static var job: ActionJob {
        Job<CounterState>(reducers: [counterReducer]) { state, newState in
            state.count = newState.count
        }
    }
}

struct DecrementAction: Action {
    let payload: Int
    static var job: ActionJob {
        Job<CounterState>(reducers: [counterReducer]) { state, newState in
            state.count = newState.count
        }
    }
}


func counterReducer(state: CounterState, action: Action) -> CounterState {
    return state.copy { mutation in
        switch action {
        case let act as IncrementAction:
            mutation.count += act.payload
        case let act as DecrementAction:
            mutation.count -= act.payload
        default:
            break
        }
    }
}
```

### UnitTest

```swift
import XCTest
@testable import Redux

final class CounterStoreTests: XCTestCase {
    
    private var store: CounterStore? = nil
    
    override func setUp() {
        super.setUp()
        store = CounterStore()
    }
    
    override func tearDown() {
        super.tearDown()
        store = nil
    }
    
    func testInitialState() {
        XCTAssertEqual(0, store!.state.count)
        XCTAssertNil(store!.state.error)
    }
    
    func testIncrementAction() {
        let test = Test<CounterState>()
        
        test
            .dispatch(action: IncrementAction(payload: 1))
            .to(store)
        
        wait(for: test) { state in
            XCTAssertEqual(1, state.count)
        }
    }
    
    func testDecrementAction() {
        let test = Test<CounterState>()

        test
            .dispatch(action: DecrementAction(payload: 1))
            .to(store)

        wait(for: test) { state in
            XCTAssertEqual(-1, state.count)
        }
    }

    func testMultipleIncrementActions() {
        let test = Test<CounterState>()

        test
            .dispatch(action: IncrementAction(payload: 1))
            .dispatch(action: IncrementAction(payload: 1))
            .test { state in
                XCTAssertEqual(2, state.count)
            }
            .dispatch(action: IncrementAction(payload: 1))
            .dispatch(action: IncrementAction(payload: 1))
            .dispatch(action: IncrementAction(payload: 1))
            .to(store)

        wait(for: test) { (state) in
            XCTAssertEqual(5, state.count)
        }
    }

    func testMultipleDecrementActions() {
        let test = Test<CounterState>()

        test
            .dispatch(action: DecrementAction(payload: 1))
            .dispatch(action: DecrementAction(payload: 1))
            .dispatch(action: DecrementAction(payload: 1))
            .dispatch(action: DecrementAction(payload: 1))
            .dispatch(action: DecrementAction(payload: 1))
            .to(store)

        wait(for: test) { (state) in
            XCTAssertEqual(-5, state.count)
        }
    }

    func testMultipleIncDecActions() {
        let test = Test<CounterState>()
        let counterState = CounterState(count: 10, error: nil)
        test.reset(store: store!, state: counterState)

        XCTAssertEqual(10, store!.state.count)
        XCTAssertNil(store!.state.error)

        test.dispatch(action: IncrementAction(payload: 1))
            .dispatch(action: IncrementAction(payload: 2))
            .dispatch(action: IncrementAction(payload: 3))
            .test { state in
                XCTAssertEqual(16, state.count)
            }
            .dispatch(action: DecrementAction(payload: 1))
            .dispatch(action: DecrementAction(payload: 2))
            .dispatch(action: DecrementAction(payload: 3))
            .test { state in
                XCTAssertEqual(10, state.count)
            }
            .dispatch(action: IncrementAction(payload: 1))
            .dispatch(action: DecrementAction(payload: 2))
            .to(store)

        wait(for: test) { (state) in
            XCTAssertEqual(9, state.count)
        }
    }
    

    static var allTests = [
        ("testInitialState", testInitialState),
    ]
}

```
