//
//  AppStore.swift
//  ReduxApp
//
//  Created by burt on 2021/02/04.
//

import Foundation

enum MyError: Error {
    case tempError
}

func logging(state: State, action: Action, dispatcher: @escaping ActionDispatcher) {
    print("logging")
    print(state)
}

func asyncJob(state: State, action: Action, dispatcher: @escaping ActionDispatcher) {
    Thread.sleep(forTimeInterval: 2)
    dispatcher(IncrementAction(payload: 2))
}

func asyncJobWithError(state: State, action: Action, dispatcher: @escaping ActionDispatcher) throws {
    Thread.sleep(forTimeInterval: 2)
    throw MyError.tempError
}

func counterReducer(state: State, action: Action) -> State {
    guard var mutableState = state as? AppState else {
        return state
    }
    
    switch action {
    case let act as IncrementAction:
        mutableState.count += act.payload
    case let act as DecrementAction:
        mutableState.count -= act.payload
    default:
        break
    }
    
    return mutableState
}

struct AsyncIncrementAction: Action {
    var middlewares: [Middleware] = [
        logging,
        asyncJob
    ]
}

struct IncrementAction: Action {
    let payload: Int
    
    var middlewares: [Middleware] = [
        logging
    ]
    
    var reducers: [Reducer] = [
        counterReducer
    ]
    
    init(payload: Int = 1) {
        self.payload = payload
    }
}

struct DecrementAction: Action {
    let payload: Int
    
    var middlewares: [Middleware] = [
        logging
    ]
    
    var reducers: [Reducer] = [
        counterReducer
    ]
    
    init(payload: Int = 1) {
        self.payload = payload
    }
}

struct TestAsyncErrorAction: Action {
    var middlewares: [Middleware] = [
        logging,
        asyncJobWithError
    ]
}

struct AppState: State {
    var count: Int = 0
    var error: (Error, Action)?
}

class AppStore: Store<AppState> {
}
