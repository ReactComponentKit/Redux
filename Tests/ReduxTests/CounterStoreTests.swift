import XCTest
@testable import Redux

final class CounterStoreTests: XCTestCase {
    
    private var store: CounterStore!
    
    override func setUp() {
        super.setUp()
        store = CounterStore()
    }
    
    override func tearDown() {
        super.tearDown()
        store = nil
    }
    
    func testInitialState() {
        XCTAssertEqual(0, store.count)
        XCTAssertNil(store.error)
    }
    
    func testIncrementAction() {
        let test = Test<CounterState>()
        
        test
            .dispatch(action: IncrementAction(payload: 1))
            .to(store)
        
        wait(for: test) { state in
            XCTAssertEqual(1, state.count)
        }
    }
    
    func testDecrementAction() {
        let test = Test<CounterState>()

        test
            .dispatch(action: DecrementAction(payload: 1))
            .to(store)

        wait(for: test) { state in
            XCTAssertEqual(-1, state.count)
        }
    }

    func testMultipleIncrementActions() {
        let test = Test<CounterState>()

        test
            .dispatch(action: IncrementAction(payload: 1))
            .dispatch(action: IncrementAction(payload: 1))
            .test { state in
                XCTAssertEqual(2, state.count)
            }
            .dispatch(action: IncrementAction(payload: 1))
            .dispatch(action: IncrementAction(payload: 1))
            .dispatch(action: IncrementAction(payload: 1))
            .to(store)

        wait(for: test) { (state) in
            XCTAssertEqual(5, state.count)
        }
    }

    func testMultipleDecrementActions() {
        let test = Test<CounterState>()

        test
            .dispatch(action: DecrementAction(payload: 1))
            .dispatch(action: DecrementAction(payload: 1))
            .dispatch(action: DecrementAction(payload: 1))
            .dispatch(action: DecrementAction(payload: 1))
            .dispatch(action: DecrementAction(payload: 1))
            .to(store)

        wait(for: test) { (state) in
            XCTAssertEqual(-5, state.count)
        }
    }

    func testMultipleIncDecActions() {
        let test = Test<CounterState>()
        let counterState = CounterState(count: 10, error: nil)
        test.reset(store: store!, state: counterState)

        XCTAssertEqual(10, store.count)
        XCTAssertNil(store.error)

        test.dispatch(action: IncrementAction(payload: 1))
            .dispatch(action: IncrementAction(payload: 2))
            .dispatch(action: IncrementAction(payload: 3))
            .test { state in
                XCTAssertEqual(16, state.count)
            }
            .dispatch(action: DecrementAction(payload: 1))
            .dispatch(action: DecrementAction(payload: 2))
            .dispatch(action: DecrementAction(payload: 3))
            .test { state in
                XCTAssertEqual(10, state.count)
            }
            .dispatch(action: IncrementAction(payload: 1))
            .dispatch(action: DecrementAction(payload: 2))
            .to(store)

        wait(for: test) { (state) in
            XCTAssertEqual(9, state.count)
        }
    }
    

    static var allTests = [
        ("testInitialState", testInitialState),
    ]
}
