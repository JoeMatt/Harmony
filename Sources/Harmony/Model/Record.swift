//
//  Record.swift
//  Harmony
//
//  Created by Riley Testut on 11/20/18.
//  Copyright © 2018 Riley Testut. All rights reserved.
//

import CoreData

@objc public enum RecordStatus: Int16, CaseIterable {
    case normal
    case updated
    case deleted
}

public typealias AnyRecord = Record<NSManagedObject>

public struct RecordID: Hashable, Codable, CustomStringConvertible {
    public var type: String
    public var identifier: String

    public var description: String {
        type + "-" + identifier
    }

    public init(type: String, identifier: String) {
        self.type = type
        self.identifier = identifier
    }
}

public class Record<T: NSManagedObject> {
    public let recordID: RecordID

    private let managedRecord: ManagedRecord
    private let managedRecordContext: NSManagedObjectContext?

    public var localizedName: String? {
        perform { $0.localRecord?.recordedObject?.syncableLocalizedName ?? $0.remoteRecord?.localizedName }
    }

    public var localMetadata: [HarmonyMetadataKey: String]? {
        perform { $0.localRecord?.recordedObject?.syncableMetadata }
    }

    public var remoteMetadata: [HarmonyMetadataKey: String]? {
        perform { $0.remoteRecord?.metadata }
    }

    public var isConflicted: Bool {
        perform { $0.isConflicted }
    }

    public var isSyncingEnabled: Bool {
        perform { $0.isSyncingEnabled }
    }

    public var localStatus: RecordStatus? {
        perform { $0.localRecord?.status }
    }

    public var remoteStatus: RecordStatus? {
        perform { $0.remoteRecord?.status }
    }

    public var remoteVersion: Version? {
        perform { $0.remoteRecord?.version }
    }

    public var remoteAuthor: String? {
        perform { $0.remoteRecord?.author }
    }

    public var localModificationDate: Date? {
        perform { $0.localRecord?.modificationDate }
    }

    var shouldLockWhenUploading = false

    init(_ managedRecord: ManagedRecord) {
        self.managedRecord = managedRecord
        managedRecordContext = managedRecord.managedObjectContext

        let recordID: RecordID

        if let context = managedRecordContext {
            recordID = context.performAndWait { managedRecord.recordID }
        } else {
            recordID = managedRecord.recordID
        }

        self.recordID = recordID
    }
}

public extension Record {
    func perform<T>(in context: NSManagedObjectContext? = nil, closure: @escaping (ManagedRecord) -> T) -> T {
        if let context = context ?? managedRecordContext {
            return context.performAndWait {
                let record = self.managedRecord.in(context)
                return closure(record)
            }
        } else {
            return closure(managedRecord)
        }
    }

    func perform<T>(in context: NSManagedObjectContext? = nil, closure: @escaping (ManagedRecord) throws -> T) throws -> T {
        if let context = context ?? managedRecordContext {
            return try context.performAndWait {
                let record = self.managedRecord.in(context)
                return try closure(record)
            }
        } else {
            return try closure(managedRecord)
        }
    }
}

public extension Record where T == NSManagedObject {
    var recordedObject: Syncable? {
        self.perform { $0.localRecord?.recordedObject }
    }

    convenience init<R>(_ record: Record<R>) {
        let managedRecord = record.perform { $0 }
        self.init(managedRecord)
    }
}

public extension Record where T: Syncable {
    var recordedObject: T? {
        perform { $0.localRecord?.recordedObject as? T }
    }
}

public extension Record {
    func setSyncingEnabled(_ syncingEnabled: Bool) throws {
        let result = perform { managedRecord -> Result<Void, Error> in
            do {
                managedRecord.isSyncingEnabled = syncingEnabled

                try managedRecord.managedObjectContext?.save()

                return .success
            } catch {
                return .failure(error)
            }
        }

        try result.get()
    }
}

extension Record: Hashable {
    public static func == (lhs: Record, rhs: Record) -> Bool {
        lhs.recordID == rhs.recordID
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(recordID)
    }
}
