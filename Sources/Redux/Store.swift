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
    private var cancellable: Set<AnyCancellable> = Set()
    
    private var actionJobMap: [String: Job<S>] = [:]
    
    public init(state: S = S()) {
        self.state = state
        self.processActions()
        self.registerJobs()
    }
    
    public func dispatch(action: Action) {
        actions.send(action)
    }
    
    open func beforeProcessingAction(state: S, action: Action) -> Action {
        // Override this function if need some job before processing action.
        return action
    }
    
    open func afterProcessingAction(state: S, action: Action) {
        // Override this function if need some job after processing action.
    }
    
    open func registerJobs() {
        // 
    }
    
    private func enqueueAction(action: Action) {
        actionQueueMutex.wait()
        defer { actionQueueMutex.signal() }
        if actionQueue.isEmpty {
            actions.send(action)
        } else {
            actionQueue.append(action)
        }
    }
    
    private func handleSideEffect() -> (ActionDispatcher, Set<AnyCancellable>) {
        return (enqueueAction, cancellable)
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
            .store(in: &cancellable)
    }
    
    public func process(action: Action.Type, job: () -> Job<S>) {
        let job = job()
        let actionName = "\(action)"
        self.actionJobMap[actionName] = job
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
            .store(in: &cancellable)
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
            .store(in: &cancellable)
    }
}