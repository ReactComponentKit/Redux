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

func asyncJob(state: AppState, action: Action, dispatcher: @escaping ActionDispatcher) {
    Thread.sleep(forTimeInterval: 2)
    dispatcher(IncrementAction(payload: 2))
}

func asyncJobWithError(state: AppState, action: Action, dispatcher: @escaping ActionDispatcher) throws {
    Thread.sleep(forTimeInterval: 20)
    throw MyError.tempError
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

### Define Action and State processing pipeline in the Store

```swift
class AppStore: Store<AppState> {
    override func beforeProcessingAction(state: AppState, action: Action) -> Action {
        print("[## \(action) ##]")
        print(state)
        return action
    }
}
```
