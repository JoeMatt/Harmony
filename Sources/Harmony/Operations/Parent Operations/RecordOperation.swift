//
//  RecordOperation.swift
//  Harmony
//
//  Created by Riley Testut on 10/23/18.
//  Copyright © 2018 Riley Testut. All rights reserved.
//

import CoreData
import Foundation

class RecordOperation<ResultType>: Operation<ResultType, RecordError> {
    let record: AnyRecord
    let managedObjectContext: NSManagedObjectContext

    var isBatchOperation = false

    override var isAsynchronous: Bool {
        true
    }

    required init<T: NSManagedObject>(record: Record<T>, coordinator: SyncCoordinator, context: NSManagedObjectContext) throws {
        let record = AnyRecord(record)
        guard !record.isConflicted else { throw RecordError.conflicted(record) }

        self.record = record

        managedObjectContext = context

        super.init(coordinator: coordinator)

        progress.totalUnitCount = 1
        operationQueue.maxConcurrentOperationCount = 2
    }

    override func start() {
        record.perform { _ in
            super.start()
        }
    }

    override func finish() {
        managedObjectContext.performAndWait {
            if self.isCancelled {
                self.result = .failure(RecordError(self.record, GeneralError.cancelled))
            }

            super.finish()
        }
    }
}
