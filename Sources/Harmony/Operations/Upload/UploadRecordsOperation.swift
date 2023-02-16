//
//  UploadRecordsOperation.swift
//  Harmony
//
//  Created by Riley Testut on 11/5/18.
//  Copyright © 2018 Riley Testut. All rights reserved.
//

import CoreData
import Foundation

class UploadRecordsOperation: BatchRecordOperation<RemoteRecord, UploadRecordOperation> {
    override class var predicate: NSPredicate {
        ManagedRecord.uploadRecordsPredicate
    }

    override func main() {
        syncProgress.status = .uploading

        super.main()
    }

    override func process(_ records: [AnyRecord], in context: NSManagedObjectContext, completionHandler: @escaping (Result<[AnyRecord], Error>) -> Void) {
        let operation = PrepareUploadingRecordsOperation(records: records, coordinator: coordinator, context: context)
        operation.resultHandler = { result in
            completionHandler(result)
        }

        operationQueue.addOperation(operation)
    }

    override func process(_ results: [AnyRecord: Result<RemoteRecord, RecordError>], in context: NSManagedObjectContext, completionHandler: @escaping (Result<[AnyRecord: Result<RemoteRecord, RecordError>], Error>) -> Void) {
        let operation = FinishUploadingRecordsOperation(results: results, coordinator: coordinator, context: context)
        operation.resultHandler = { result in
            completionHandler(result)
        }

        operationQueue.addOperation(operation)
    }
}
