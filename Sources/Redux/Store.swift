//
//  Store.swift
//  ReduxApp
//
//  Created by sungcheol.kim on 2021/02/04.
//

import Foundation
import Combine

open class Store<S: State>: ObservableObject {
    @Published
    public private(set) var state: S
    
    private var actions = PassthroughSubject<Action, Never>()
    private var actionQueue: [Action] = []
    private let actionQueueMutex = DispatchSemaphore(value: 1)
    private var actionJobMap: [String: Job<S>] = [:]
    public var cancellables: Set<AnyCancellable> = Set()
    
    // for testing
    internal var testResultHandler: ((S) -> Swift.Void)?
    internal var testDequeActionHandler: (() -> Swift.Void)?
    
    public init(state: S = S()) {
        self.state = state
        self.processActions()
    }
    
    public func dispatch(action: Action) {
        prepare(action: action)
        actions.send(action)
    }
    
    // Dispatch Implicit Action to the middleware without payload
    public func dispatch(middleware: @escaping (S, SideEffect<S>) -> Swift.Void) {
        func makeMiddleware(actionName: String) -> Middleware<S> {
            return { (state: S, action: Action, sideEffect: @escaping SideEffect<S>) in
                guard
                    action is ImplicitAction<Int>,
                    action.name == actionName
                else {
                    return
                }
                middleware(state, sideEffect)
            }
        }
        
        let actionName = "\(Date().timeIntervalSince1970)"
        let actionJob = Job<S>(middlewares: [
            makeMiddleware(actionName: actionName)
        ])
        let action = ImplicitAction(payload: -1, name: actionName, job: actionJob)
        dispatch(action: action)
    }
    
    // Dispatch Implicit Action to the middleware with payload
    public func dispatch<T>(payload: T, middleware: @escaping (S, T, SideEffect<S>) -> Swift.Void) {
        func makeMiddleware(actionName: String) -> Middleware<S> {
            return { (state: S, action: Action, sideEffect: @escaping SideEffect<S>) in
                guard
                    action is ImplicitAction<T>,
                    let value: T = action.get()
                else {
                    return
                }
                middleware(state, value, sideEffect)
            }
        }
        
        let actionName = "\(Date().timeIntervalSince1970)"
        let actionJob = Job<S>(middlewares: [
            makeMiddleware(actionName: actionName)
        ])
        let action = ImplicitAction(payload: payload, name: actionName, job: actionJob)
        dispatch(action: action)
    }
    
    // Dispatch Implicit Action to the reducer with payload
    public func dispatch<T>(_ keyPath: WritableKeyPath<S, T>, payload: T, reducer: @escaping (S, T) -> S) {
        func makeReducer(actionName: String) -> Reducer<S> {
            return { (state: S, action: Action) -> S in
                guard
                    action is ImplicitAction<T>,
                    action.name == actionName,
                    let value: T = action.get()
                else {
                    return state
                }
                return reducer(state, value)
            }
        }
        
        let actionName = "\(Date().timeIntervalSince1970)"
        let actionJob = Job<S>(reducers: [
            makeReducer(actionName: actionName)
        ]) { (state, newState) in
            state[keyPath: keyPath] = newState[keyPath: keyPath]
        }
        let action = ImplicitAction(payload: payload, name: actionName, job: actionJob)
        dispatch(action: action)
    }
    
    public func updateAsync<T>(_ keyPath: WritableKeyPath<S, Async<T>>, payload: Async<T>) {
        func makeReducer(actionName: String) -> Reducer<S> {
            return { (state: S, action: Action) -> S in
                guard
                    action is ImplicitAction<Async<T>>,
                    action.name == actionName,
                    let value: Async<T> = action.get()
                else {
                    return state
                }
                return state.copy { mutation in
                    mutation[keyPath: keyPath] = value
                }
            }
        }
        
        let actionName = "\(Date().timeIntervalSince1970)"
        let actionJob = Job<S>(reducers: [
            makeReducer(actionName: actionName)
        ]) { (state, newState) in
            state[keyPath: keyPath] = newState[keyPath: keyPath]
        }
        let action = ImplicitAction(payload: payload, name: actionName, job: actionJob)
        dispatch(action: action)
    }
    
    public func store<STORE: Store<S>>() -> STORE {
        return self as! STORE
    }
    
    open func beforeProcessingAction(state: S, action: Action) -> Action {
        // Override this function if need some job before processing action.
        return action
    }
    
    open func afterProcessingAction(state: S, action: Action) {
        // Override this function if need some job after processing action.
    }
    
    private func enqueueAction(action: Action) {
        actionQueueMutex.wait()
        defer { actionQueueMutex.signal() }
        prepare(action: action)
        if actionQueue.isEmpty {
            actions.send(action)
        } else {
            actionQueue.append(action)
        }
    }
    
    private func prepare(action: Action) {
        let job = action.job
        let actionName = action.name
        if self.actionJobMap[actionName] != nil {
            return
        }
        if let job = job as? Job<S> {
            self.actionJobMap[actionName] = job
        }
    }
        
    private func handleSideEffect() -> (ActionDispatcher, Store<S>) {
        return (enqueueAction, self)
    }
    
    private func processActions() {
        actions
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (action) in
                guard let strongSelf = self else { return }
                let currentAction = strongSelf.beforeProcessingAction(state: strongSelf.state, action: action)
                if type(of: currentAction) != CancelAction.self {
                    strongSelf.processMiddlewares(action: action)
                }
            }
            .store(in: &cancellables)
    }
    
    private func processMiddlewares(action: Action) {
        let actionName = action.name
        guard let job = self.actionJobMap[actionName] else { return }
        job.middlewares.publisher
            .subscribe(on: DispatchQueue.global())
            .tryReduce(state, { [weak self] s, m in
                guard let strongSelf = self else { return s }
                try m(s, action, strongSelf.handleSideEffect)
                return s
            })
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self?.state.error = (error, action)
                }
            }, receiveValue: { [weak self] _ in
                self?.state.error = nil
                self?.processReducers(action: action)
            })
            .store(in: &cancellables)
    }
    
    private func processReducers(action: Action) {
        let actionName = action.name
        guard let job = self.actionJobMap[actionName] else { return }
        job.reducers
            .publisher
            .subscribe(on: DispatchQueue.global())
            .reduce(state, { newState, reducer in
                return reducer(newState, action)
            })
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] state in
                guard let strongSelf = self else { return }
                // update state
                job.onNewState?(&strongSelf.state, state)
                
                // do job after procesing action
                strongSelf.afterProcessingAction(state: state, action: action)
                
                // for testing
                if !job.reducers.isEmpty {
                    strongSelf.testResultHandler?(strongSelf.state)
                }

                // queueing actions
                strongSelf.actionQueueMutex.wait()
                defer { strongSelf.actionQueueMutex.signal() }
                if !strongSelf.actionQueue.isEmpty {
                    strongSelf.actionQueue.forEach {
                        strongSelf.actions.send($0)
                    }
                }
                strongSelf.actionQueue = []
            })
            .store(in: &cancellables)
    }
}

// For testing
extension Store {
    internal func reset(with state: S) {
        self.state = state
    }
    
    internal func test(action: Action) {
        self.dispatch(action: action)
    }
    
    internal func wait(result: @escaping (S) -> Swift.Void) {
        self.testResultHandler = result
    }
    
    // calling after assert
    internal func againTest() {
        self.testResultHandler?(self.state)
    }
}
