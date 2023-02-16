//
//  LocalRecordTests.swift
//  HarmonyTests
//
//  Created by Riley Testut on 5/17/17.
//  Copyright © 2017 Riley Testut. All rights reserved.
//

import XCTest
@testable import Harmony
@testable @_implementationOnly import HarmonyTestData

import CoreData

class LocalRecordTests: HarmonyTestCase {}

extension LocalRecordTests {
    func testInitialization() {
        let identifier = UUID().uuidString
        let professor = Professor.make(identifier: identifier)

        var record: LocalRecord!
        XCTAssertNoThrow(record = try LocalRecord(recordedObject: professor, context: recordController.viewContext))

        XCTAssertNil(record.version)

        XCTAssertEqual(record.status, .normal)

        XCTAssertEqual(record.recordedObjectType, professor.syncableType)
        XCTAssertEqual(record.recordedObjectIdentifier, professor.syncableIdentifier)

        let recordedProfessor = recordController.viewContext.object(with: professor.objectID) as! Professor
        XCTAssertEqual(record.recordedObject!, recordedProfessor)
        XCTAssertEqual(record.recordedObjectID?.uriRepresentation(), professor.objectID.uriRepresentation())
    }

    func testInitializationWithTemporaryObject() {
        let identifier = UUID().uuidString
        let professor = Professor.make(identifier: identifier, automaticallySave: false)

        var record: LocalRecord!
        XCTAssertNoThrow(record = try LocalRecord(recordedObject: professor, context: recordController.viewContext))

        XCTAssertNil(record.recordedObject)
        XCTAssertEqual(record.recordedObjectID?.uriRepresentation(), professor.objectID.uriRepresentation())

        XCTAssertEqual(record.status, .normal)

        XCTAssertEqual(record.recordedObjectType, professor.syncableType)
        XCTAssertEqual(record.recordedObjectIdentifier, professor.syncableIdentifier)

        // Save recorded object
        try! professor.managedObjectContext?.save()

        // Check recorded object is not nil after saving.
        let recordedProfessor = recordController.viewContext.object(with: professor.objectID) as! Professor
        XCTAssertEqual(record.recordedObject!, recordedProfessor)
        XCTAssertEqual(record.recordedObjectID?.uriRepresentation(), professor.objectID.uriRepresentation())

        // Save record
        try! record.managedObjectContext?.save()

        // Check relationship is valid after saving.
        XCTAssertEqual(record.recordedObject!, recordedProfessor)
        XCTAssertEqual(record.recordedObjectID?.uriRepresentation(), professor.objectID.uriRepresentation())
    }

    func testInitializationWithTemporaryObjectInvalid() {
        let professor = Professor.make(context: nil)

        XCTAssertThrowsError(try LocalRecord(recordedObject: professor, context: recordController.viewContext))
    }
}

extension LocalRecordTests {
    func testCreatingDuplicates() {
        let homework = Homework.make()

        _ = try! LocalRecord(recordedObject: homework, context: recordController.viewContext)
        try! recordController.viewContext.save()

        _ = try! LocalRecord(recordedObject: homework, context: recordController.viewContext)
        try! recordController.viewContext.save()

        let fetchRequest: NSFetchRequest<LocalRecord> = LocalRecord.fetchRequest()
        let records = try! recordController.viewContext.fetch(fetchRequest)
        XCTAssertEqual(records.count, 1)
    }

    func testCreatingDuplicatesSimultaneously() {
        performSaveInTearDown = false

        let course = Course.make()

        _ = try! LocalRecord(recordedObject: course, context: recordController.viewContext)
        _ = try! LocalRecord(recordedObject: course, context: recordController.viewContext)

        // Assert throwing error because we have an assertion that our merge policy work only with context-level conflicts.
        XCTAssertThrowsError(try recordController.viewContext.save())

        let fetchRequest: NSFetchRequest<LocalRecord> = LocalRecord.fetchRequest()
        let records = try! recordController.viewContext.fetch(fetchRequest)
        XCTAssertEqual(records.count, 1)
    }
}

extension LocalRecordTests {
    func testFetching() {
        let record = try! LocalRecord(recordedObject: Professor.make(), context: recordController.viewContext)

        XCTAssertNoThrow(try recordController.viewContext.save())

        let fetchRequest: NSFetchRequest<LocalRecord> = LocalRecord.fetchRequest()
        let records = try! recordController.viewContext.fetch(fetchRequest)

        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first, record)
    }
}

extension LocalRecordTests {
    func testRecordedObjectIDInvalid() {
        // Nil NSManagedObjectContext
        var record = try! LocalRecord(recordedObject: Professor.make(), context: recordController.viewContext)
        recordController.viewContext.delete(record)

        try! recordController.viewContext.save()

        XCTAssertFatalError(record.recordedObjectID)

        // Deleted Store
        record = try! LocalRecord(recordedObject: Professor.make(), context: recordController.viewContext)

        for store in recordController.persistentStoreCoordinator.persistentStores {
            try! recordController.persistentStoreCoordinator.remove(store)
        }

        XCTAssertNil(record.recordedObjectID)

        performSaveInTearDown = false
    }

    func testRecordedObject() {
        let identifier = UUID().uuidString
        let professor = Professor.make(identifier: identifier)

        let record = try! LocalRecord(recordedObject: professor, context: recordController.viewContext)

        let recordedProfessor = recordController.viewContext.object(with: professor.objectID) as! Professor
        XCTAssertEqual(record.recordedObject!, recordedProfessor)
    }

    func testRecordedObjectInvalid() {
        // Nil NSManagedObjectContext
        var record = try! LocalRecord(recordedObject: Professor.make(), context: recordController.viewContext)
        recordController.viewContext.delete(record)

        try! recordController.viewContext.save()

        XCTAssertFatalError(record.recordedObject)

        // Deleted Object
        let professor = Professor.make()
        try! recordController.viewContext.save()

        persistentContainer.viewContext.delete(professor)
        try! persistentContainer.viewContext.save()

        XCTAssertThrowsError(try LocalRecord(recordedObject: professor, context: recordController.viewContext))

        // Nil External Relationship
        record = try! LocalRecord(recordedObject: Course.make(), context: recordController.viewContext)

        for store in recordController.persistentStoreCoordinator.persistentStores {
            try! recordController.persistentStoreCoordinator.remove(store)
        }

        XCTAssertNil(record.recordedObject)

        performSaveInTearDown = false
    }
}

extension LocalRecordTests {
    func testStatus() {
        // KVO
        let record = try! LocalRecord(recordedObject: Professor.make(), context: recordController.viewContext)

        let expectation = keyValueObservingExpectation(for: record, keyPath: #keyPath(LocalRecord.status), expectedValue: RecordStatus.updated.rawValue)
        record.status = .updated

        XCTAssertEqual(record.status, .updated)

        wait(for: [expectation], timeout: 1.0)

        record.status = .deleted
        XCTAssertEqual(record.status, .deleted)
    }

    func testStatusInvalid() {
        let record = try! LocalRecord(recordedObject: Course.make(), context: recordController.viewContext)
        record.setPrimitiveValue(100, forKey: #keyPath(LocalRecord.status))

        XCTAssertEqual(record.status, .updated)
    }
}
