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
    @Published
    private(set) public var state: S
    public init(state: S) {
        self.state = state
    }
    
    private var workListBeforeCommit: [(inout S) -> Void] = []
    private var workListAfterCommit: [(inout S) -> Void] = []

//
//    comment it to read state value more explicitly
//
//    public subscript<T>(dynamicMember keyPath: KeyPath<S, T>) -> T {
//        return state[keyPath: keyPath]
//    }
//
    
    open func worksBeforeCommit() -> [(inout S) -> Void] {
        return []
    }
    
    open func worksAfterCommit() -> [(inout S) -> Void] {
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
            work(&self.state)
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
            work(&self.state)
        }
    }
    
    public func commit<P>(mutation: (inout S, P) -> Void, payload: P) {
        doWorksBeforeCommit()
        let original = state
        mutation(&state, payload)
        if original != state {
            computed(new: state, old: original)
        }
        doWorksAfterCommit()
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
