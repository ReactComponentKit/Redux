import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(CounterStoreTests.allTests),
        testCase(AsyncStoreTests.allTests)
    ]
}
#endif
