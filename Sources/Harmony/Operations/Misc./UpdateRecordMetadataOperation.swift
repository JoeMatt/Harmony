//
//  UpdateRecordMetadataOperation.swift
//  Harmony
//
//  Created by Riley Testut on 11/5/18.
//  Copyright © 2018 Riley Testut. All rights reserved.
//

import CoreData
import Foundation

class UpdateRecordMetadataOperation: RecordOperation<Void> {
    var metadata = [HarmonyMetadataKey: Any]()

    required init<T: NSManagedObject>(record: Record<T>, coordinator: SyncCoordinator, context: NSManagedObjectContext) throws {
        metadata[.recordedObjectType] = record.recordID.type
        metadata[.recordedObjectIdentifier] = record.recordID.identifier

        try super.init(record: record, coordinator: coordinator, context: context)
    }

    override func main() {
        super.main()

        let operation = ServiceOperation(coordinator: coordinator) { completionHandler -> Progress? in
                self.service.updateMetadata(self.metadata, for: self.record, completionHandler: completionHandler)
            }
        operation.resultHandler = { result in
            do {
                try result.get()

                self.result = .success
            } catch {
                self.result = .failure(RecordError(self.record, error))
            }

            self.finish()
        }

        progress.addChild(operation.progress, withPendingUnitCount: 1)
        operationQueue.addOperation(operation)
    }
}
