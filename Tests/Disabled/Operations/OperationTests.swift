//
//  OperationTests.swift
//  HarmonyTests
//
//  Created by Riley Testut on 1/22/18.
//  Copyright © 2018 Riley Testut. All rights reserved.
//

import CoreData
import XCTest

@testable import Harmony

class OperationTests: HarmonyTestCase {
    var service = MockService()

    var operationQueue: OperationQueue!

    var operationExpectation: XCTestExpectation!

    var operation: Harmony.Operation<Any, Swift.Error>!

    override func setUp() {
        super.setUp()

        operationQueue = OperationQueue()
        operationQueue.name = "OperationTests"

        operationExpectation = XCTestExpectation(description: "Operation Successfully Finishes")
    }

    override func tearDown() {
        wait(for: [operationExpectation], timeout: 2.0)

        super.tearDown()
    }
}

extension OperationTests {
    // TODO: Fix me @JoeMatt
    func prepareTestOperation() -> (Foundation.Operation & ProgressReporting) {
        guard type(of: self) == OperationTests.self else { fatalError("OperationTests subclasses must override prepareTestOperation.") }

        let operation = Harmony.Operation<Any, Swift.Error>(service: service)
        return operation
    }
}

extension OperationTests {
    func testCancelling() {
        let operation = prepareTestOperation()

        let expectation = XCTKVOExpectation(keyPath: #keyPath(Foundation.Operation.isCancelled), object: operation)
        operation.cancel()
        wait(for: [expectation], timeout: 1.0)

        XCTAssert(operation.isCancelled)
        XCTAssert(operation.progress.isCancelled)

        operationExpectation.fulfill()
    }

    func testCancellingProgress() {
        let operation = prepareTestOperation()

        let expectation = XCTKVOExpectation(keyPath: #keyPath(Foundation.Operation.isCancelled), object: operation)
        operation.progress.cancel()
        wait(for: [expectation], timeout: 1.0)

        XCTAssert(operation.isCancelled)
        XCTAssert(operation.progress.isCancelled)

        operationExpectation.fulfill()
    }
}
