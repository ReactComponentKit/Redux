import XCTest
@testable import Redux

struct ReduxState: State {
    var count: Int = 0
}

class ReduxStore: Store<ReduxState> {
    init() {
        super.init(state: ReduxState())
    }
    
    @Published
    var doubleCount: Int = 0
    
    @Published
    var conditionalDoubleEven: Int = 0
    
    override func computed(new: ReduxState, old: ReduxState) {
        doubleCount = new.count * 2
        
        if old.count % 2 == 0 && new.count % 2 == 1 {
            conditionalDoubleEven = old.count * 2
        }
    }
}

class WorksBeforeCommitStore: Store<ReduxState> {
    init() {
        super.init(state: ReduxState())
    }
    
    override func worksBeforeCommit() -> [(inout ReduxState) -> Void] {
        return [
            { (mutableState) in
                mutableState.count = -10
            }
        ]
    }
}

class WorksAfterCommitStore: Store<ReduxState> {
    init() {
        super.init(state: ReduxState())
    }
    
    override func worksAfterCommit() -> [(inout ReduxState) -> Void] {
        return [
            { (mutableState) in
                mutableState.count *= 2
            }
        ]
    }
}

final class ReduxTests: XCTestCase {
    private var store: ReduxStore!
    
    override func setUp() {
        super.setUp()
        store = ReduxStore()
    }
    
    override func tearDown() {
        super.tearDown()
        store = nil
    }
    
    func testCommit() {
        store.commit(mutation: { mutableState, number in
            mutableState.count += number
        }, payload: 10)
        XCTAssertEqual(10, store.state.count)
    }
    
    func testDispatchSync() {
        store.dispatch(action: { store, payload in
            store.commit(mutation: { mutableState, number in
                mutableState.count += number
            }, payload: payload * 2)
        }, payload: 10)
        XCTAssertEqual(20, store.state.count)
    }
    
    func testDispatchAsync() async {
        await store.dispatch(action: { store, payload in
            await Task.sleep(1 * 1_000_000_000)
            store.commit(mutation: { mutableState, number in
                mutableState.count += number
            }, payload: payload * 2)
        }, payload: 10)
        XCTAssertEqual(20, store.state.count)
    }
    
    func testWorksBeforeCommit() {
        let store = WorksBeforeCommitStore()
        store.commit(mutation: { mutableState, number in
            mutableState.count += number
        }, payload: 1)
        XCTAssertNotEqual(1, store.state.count)
        store.commit(mutation: { mutableState, number in
            mutableState.count += number
        }, payload: 1)
        XCTAssertNotEqual(2, store.state.count)
        XCTAssertEqual(-9, store.state.count)
    }
    
    func testWorksAfterCommit() async {
        let store = WorksAfterCommitStore()
        store.commit(mutation: { mutableState, number in
            mutableState.count += number
        }, payload: 1) // 1 * 2 = 2
        await contextSwitching()
        XCTAssertEqual(2, store.state.count)
        
        store.commit(mutation: { mutableState, number in
            mutableState.count += number
        }, payload: 1) // 3 * 2 = 6
        await contextSwitching()
        XCTAssertEqual(6, store.state.count)
    }
    
    func testComputed() async {
        store.commit(mutation: { mutableState, number in
            mutableState.count += number
        }, payload: 10)
        XCTAssertEqual(10, store.state.count)
        
        await contextSwitching()
        XCTAssertEqual(20, store.doubleCount)
    }
    
    func testContitionalComputed() async {
        for i in 1...10 {
            store.commit(mutation: { mutableState, number in
                mutableState.count += number
            }, payload: i)
        }
        XCTAssertEqual(55, store.state.count)
        
        await contextSwitching()
        XCTAssertEqual(110, store.doubleCount)
        
        // old      new
        // 0        1
        // 10       15
        // 36       45
        XCTAssertEqual(72, store.conditionalDoubleEven)
    }
}