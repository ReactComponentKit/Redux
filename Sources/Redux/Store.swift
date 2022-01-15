//
//  Store.swift
//  Redux
//
//  Created by sungcheol.kim on 2021/11/06.
//  email: skyfe79@gmail.com
//  github: https://github.com/skyfe79
//  github: https://github.com/ReactComponentKit
//

import Foundation
import Combine

// @dynamicMemberLookup
open class Store<S: State>: ObservableObject {
    private(set) public var state: S
    private var workListBeforeCommit: [(S) -> Void] = []
    private var workListAfterCommit: [(S) -> Void] = []
    
    public init(state: S) {
        self.state = state
    }
    
//
//    comment it to read state value more explicitly
//
//    public subscript<T>(dynamicMember keyPath: KeyPath<S, T>) -> T {
//        return state[keyPath: keyPath]
//    }
//
  
    open func worksBeforeCommit() -> [(S) -> Void] {
        return []
    }
    
    open func worksAfterCommit() -> [(S) -> Void] {
        return []
    }
    
    private func doWorksBeforeCommit() {
        if workListBeforeCommit.isEmpty {
            let works = worksBeforeCommit()
            if works.isEmpty {
                return
            }
            workListBeforeCommit = works
        }
        for work in workListBeforeCommit {
            work(self.state)
        }
    }
    
    private func doWorksAfterCommit() {
        if workListAfterCommit.isEmpty {
            let works = worksAfterCommit()
            if works.isEmpty {
                return
            }
            workListAfterCommit = works
        }
        for work in workListAfterCommit {
            work(self.state)
        }
    }
    
    @MainActor
    private func computeOnMainThread(new: S, old: S) async {
        if new != old {
            computed(new: new, old: old)
        }
    }
    
    public func commit<P>(mutation: (inout S, P) -> Void, payload: P) {
        doWorksBeforeCommit()
        let old = state
        mutation(&state, payload)
        doWorksAfterCommit()
        Task {
            await computeOnMainThread(new: state, old: old)
        }
    }
    
    public func dispatch<P>(action: (Store<S>, P) async -> Void, payload: P) async {
        await action(self, payload)
    }
    
    public func dispatch<P>(action: (Store<S>, P) -> Void, payload: P) {
        action(self, payload)
    }
    
    open func computed(new: S, old: S) {
        // override it
    }
}
