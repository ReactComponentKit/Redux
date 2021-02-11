//
//  Store.swift
//  ReduxApp
//
//  Created by sungcheol.kim on 2021/02/04.
//

import Foundation
import Combine

open class Store<S: State>: ObservableObject, StoreContext {
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
        prepare(action: type(of: action))
        actions.send(action)
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
        prepare(action: type(of: action))
        if actionQueue.isEmpty {
            actions.send(action)
        } else {
            actionQueue.append(action)
        }
    }
    
    private func prepare(action: Action.Type) {
        let job = action.job
        let actionName = "\(action)"
        if self.actionJobMap[actionName] != nil {
            return
        }
        if let job = job as? Job<S> {
            self.actionJobMap[actionName] = job
        }
    }
        
    private func handleSideEffect() -> (ActionDispatcher, StoreContext) {
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
    
    public func processMiddlewares(action: Action) {
        let actionName = "\(type(of: action))"
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
        let actionName = "\(type(of: action))"
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
                strongSelf.testResultHandler?(strongSelf.state)

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
    
    // For testing
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
