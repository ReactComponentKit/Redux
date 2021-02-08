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

### Abstract Async State Value

```swift
struct AppState: State {
    var content: Async<String> = .uninitialized
    var error: (Error, Action)?
}
```

### Define Middlewares

```swift
func fetchContent(state: AppState, action: Action, sideEffect: @escaping SideEffect) {
    var (dispatcher, cancellable) = sideEffect()
    URLSession.shared.dataTaskPublisher(for: URL(string: "https://www.google.com")!)
        .subscribe(on: DispatchQueue.global())
        .receive(on: DispatchQueue.global())
        .sink { (completion) in
            switch completion {
            case .finished:
                break
            case .failure(let error):
                dispatcher(UpdateContentAction(content: .failed(error: error)))
            }
        } receiveValue: { (data, response) in
            let value = String(data: data, encoding: .utf8) ?? ""
            dispatcher(UpdateContentAction(content: .success(value: value)))
        }
        .store(in: &cancellable)

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

