//
//  AsyncStore.swift
//  Redux
//
//  Created by burt on 2021/02/11.
//

import Foundation
import Combine

struct AsyncState: State {
    var error: (Error, Action)?
    var content: Async<String> = .uninitialized
}

class AsyncStore: Store<AsyncState> {
    // something likes Core Data Contexts
    public var shareVariableAmongMiddlewares = "Hello Middleware!"
}


struct FetchContentAction: Action {
    static var job: ActionJob {
        Job<AsyncState>(middleware: [fetchContent])
    }
}

struct UpdateContentAction: Action {
    let content: Async<String>
    
    static var job: ActionJob {
        Job<AsyncState>(reducers: [
            updateContent
        ]) { (state, newState) in
            state.content = newState.content
        }
    }
}

func fetchContent(state: AsyncState, action: Action, sideEffect: @escaping SideEffect<AsyncState>) {
    let (dispatch, context) = sideEffect()
    
    let store: AsyncStore = context.store()
    print(store.shareVariableAmongMiddlewares)
    
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
        .store(in: &context.cancellables)
}

func updateContent(state: AsyncState, action: Action) -> AsyncState {
    return state.copy { (mutation) in
        switch action {
        case let act as UpdateContentAction:
            mutation.content = act.content
        default:
            break
        }
    }
}
