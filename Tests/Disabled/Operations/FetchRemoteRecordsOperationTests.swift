//
//  FetchRemoteRecordsOperationTests.swift
//  HarmonyTests
//
//  Created by Riley Testut on 1/16/18.
//  Copyright © 2018 Riley Testut. All rights reserved.
//

import CoreData
import XCTest

@testable import Harmony

class FetchRemoteRecordsOperationTests: OperationTests {
    var professorRemoteRecord: RemoteRecord!
    var courseRemoteRecord: RemoteRecord!
    var homeworkRemoteRecord: RemoteRecord!

    override func setUp() {
        super.setUp()

        professorRemoteRecord = RemoteRecord.make(recordedObjectType: "Professor")
        courseRemoteRecord = RemoteRecord.make(recordedObjectType: "Course")
        homeworkRemoteRecord = RemoteRecord.make(recordedObjectType: "Homework")

        service.records = [professorRemoteRecord, courseRemoteRecord, homeworkRemoteRecord]
        service.changes = [professorRemoteRecord]
    }
}

extension FetchRemoteRecordsOperationTests {
    override func prepareTestOperation() -> (Foundation.Operation & ProgressReporting) {
        let operation = FetchRemoteRecordsOperation(service: service, changeToken: service.latestChangeToken, managedObjectContext: recordController.viewContext)
        return operation
    }
}

extension FetchRemoteRecordsOperationTests {
    func testInitializationWithChangeToken() {
        let operation = FetchRemoteRecordsOperation(service: service, changeToken: service.latestChangeToken, managedObjectContext: recordController.viewContext)

        XCTAssert(operation.service == service)
        XCTAssertEqual(operation.changeToken, service.latestChangeToken)
        XCTAssertEqual(operation.managedObjectContext, recordController.viewContext)

        operationExpectation.fulfill()
    }

    func testInitializationWithoutChangeToken() {
        let operation = FetchRemoteRecordsOperation(service: service, changeToken: nil, managedObjectContext: recordController.viewContext)

        XCTAssert(operation.service == service)
        XCTAssertNil(operation.changeToken)
        XCTAssertEqual(operation.managedObjectContext, recordController.viewContext)

        operationExpectation.fulfill()
    }
}

extension FetchRemoteRecordsOperationTests {
    func testExecutionWithChangeToken() {
        let operation = FetchRemoteRecordsOperation(service: service, changeToken: service.latestChangeToken, managedObjectContext: recordController.viewContext)
        operation.resultHandler = { result in
            XCTAssert(self.recordController.viewContext.hasChanges)

            // As of Swift 4.1, we cannot use XCTAssertThrowsError or else the compiler incorrectly thinks this closure is a throwing closure, ugh.
            do {
                let records = try result.value()

                XCTAssertEqual(records.0, [self.professorRemoteRecord])
                self.operationExpectation.fulfill()
            } catch {
                print(error)
            }
        }
        operationQueue.addOperation(operation)
    }

    func testExecutionWithoutChangeToken() {
        let operation = FetchRemoteRecordsOperation(service: service, changeToken: nil, managedObjectContext: recordController.viewContext)
        operation.resultHandler = { result in
            XCTAssert(self.recordController.viewContext.hasChanges)

            do {
                let records = try result.value()

                XCTAssertEqual(records.0, [self.professorRemoteRecord, self.courseRemoteRecord, self.homeworkRemoteRecord])

                self.operationExpectation.fulfill()
            } catch {
                print(error)
            }
        }
        operationQueue.addOperation(operation)
    }

    func testExecutionWithInvalidChangeToken() {
        let changeToken = Data(bytes: [22])

        let operation = FetchRemoteRecordsOperation(service: service, changeToken: changeToken, managedObjectContext: recordController.viewContext)
        operation.resultHandler = { result in
            do {
                _ = try result.value()
            } catch FetchRecordsError.invalidChangeToken {
                self.operationExpectation.fulfill()
            } catch {
                print(error)
            }
        }
        operationQueue.addOperation(operation)
    }

    func testExecutionWithInvalidManagedObjectContext() {
        class InvalidManagedObjectContext: NSManagedObjectContext {
            struct TestError: Swift.Error {}

            override func fetch(_: NSFetchRequest<NSFetchRequestResult>) throws -> [Any] {
                throw TestError()
            }
        }

        performSaveInTearDown = false

        let invalidManagedObjectContext = InvalidManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        invalidManagedObjectContext.persistentStoreCoordinator = recordController.persistentStoreCoordinator

        let operation = FetchRemoteRecordsOperation(service: service, changeToken: nil, managedObjectContext: invalidManagedObjectContext)
        operation.resultHandler = { result in
            do {
                _ = try result.value()
            } catch is InvalidManagedObjectContext.TestError {
                self.operationExpectation.fulfill()
            } catch {
                print(error)
            }
        }
        operationQueue.addOperation(operation)
    }
}

extension FetchRemoteRecordsOperationTests {
    func testExecutionByUpdatingExistingLocalRecord() {
        professorRemoteRecord.status = .updated

        let professor = Professor.make(identifier: professorRemoteRecord.recordedObjectIdentifier)

        let localRecord = try! LocalRecord(recordedObject: professor, managedObjectContext: recordController.viewContext)
        try! localRecord.managedObjectContext?.save()

        let operation = FetchRemoteRecordsOperation(service: service, changeToken: service.latestChangeToken, managedObjectContext: recordController.viewContext)
        operation.resultHandler = { result in

            XCTAssert(self.recordController.viewContext.hasChanges)

            do {
                let records = try result.value()
                let remoteRecord = records.0.first

                XCTAssertEqual(remoteRecord?.status, .updated)
                XCTAssertEqual(remoteRecord?.recordedObjectType, professor.syncableType)
                XCTAssertEqual(remoteRecord?.recordedObjectIdentifier, professor.syncableIdentifier)
                XCTAssertEqual(remoteRecord?.localRecord, localRecord)
                XCTAssertEqual(localRecord.remoteRecord, remoteRecord)

                try! self.recordController.viewContext.save()

                self.recordController.performBackgroundTask { context in
                    let localRecord = context.object(with: localRecord.objectID) as! LocalRecord

                    do {
                        let records = try context.fetch(RemoteRecord.fetchRequest(for: localRecord))
                        let remoteRecord = records.first

                        XCTAssertEqual(remoteRecord?.status, .updated)
                        XCTAssertEqual(remoteRecord?.recordedObjectType, professor.syncableType)
                        XCTAssertEqual(remoteRecord?.recordedObjectIdentifier, professor.syncableIdentifier)
                        XCTAssertEqual(remoteRecord?.localRecord, localRecord)
                        XCTAssertEqual(localRecord.remoteRecord, remoteRecord)

                        self.operationExpectation.fulfill()
                    } catch {
                        print(error)
                    }
                }
            } catch {
                print(error)
            }
        }
        operationQueue.addOperation(operation)
    }
}
