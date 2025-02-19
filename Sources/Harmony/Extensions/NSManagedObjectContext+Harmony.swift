//
//  NSManagedObjectContext+Harmony.swift
//  Harmony
//
//  Created by Riley Testut on 3/4/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

import CoreData
import ObjectiveC

private var contextCacheKey = 0

class ContextCache {
    private let changedKeys = NSMapTable<NSManagedObject, NSSet>.weakToStrongObjects()

    func changedKeys(for object: NSManagedObject) -> Set<String>? {
        let changedKeys = self.changedKeys.object(forKey: object) as? Set<String>
        return changedKeys
    }

    func setChangedKeys(_ changedKeys: Set<String>, for object: NSManagedObject) {
        self.changedKeys.setObject(changedKeys as NSSet, forKey: object)
    }
}

extension NSManagedObjectContext {
    var savingCache: ContextCache? {
        get { objc_getAssociatedObject(self, &contextCacheKey) as? ContextCache }
        set { objc_setAssociatedObject(self, &contextCacheKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}

extension NSManagedObjectContext {
    func performAndWait<T>(_ block: @escaping () -> T) -> T {
        var result: T!

        performAndWait {
            result = block()
        }

        return result
    }

    func performAndWait<T>(_ block: @escaping () throws -> T) throws -> T {
        var result: Result<T, Error>!

        performAndWait {
            result = Result { try block() }
        }

        let value = try result.get()
        return value
    }
}

extension NSManagedObjectContext {
    func fetchRecords<T: RecordEntry>(for recordIDs: Set<RecordID>) throws -> [T] {
        // To prevent exceeding SQLite query limits by combining several predicates into a compound predicate,
        // we instead use a %K IN %@ predicate which doesn't have the same limitations.
        // However, there is a chance two or more recorded objects exist with the same identifier but different types,
        // so we filter the returned results to ensure all returned records are correct.
        let predicate = NSPredicate(format: "%K IN %@", #keyPath(ManagedRecord.recordedObjectIdentifier), recordIDs.map { $0.identifier })

        let fetchRequest = T.fetchRequest() as! NSFetchRequest<T>
        fetchRequest.predicate = predicate
        fetchRequest.propertiesToFetch = [#keyPath(ManagedRecord.recordedObjectType), #keyPath(ManagedRecord.recordedObjectIdentifier)]

        // fetchBatchSize doesn't work from Swift without workarounds (due to NSArray bridging).
        // However, attempting to use it anyway may cause Core Data threading violations.
        // As a temporary workaround, just disable setting fetchBatchSize for now.
        // fetchRequest.fetchBatchSize = 100

        // Filter out any records that happen to have a matching recordedObjectIdentifier, but not matching recordedObjectType.
        let records = try fetch(fetchRequest).filter { recordIDs.contains($0.recordID) }
        return records
    }
}
