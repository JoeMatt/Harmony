//
//  DownloadRecordsOperation.swift
//  Harmony
//
//  Created by Riley Testut on 11/5/18.
//  Copyright © 2018 Riley Testut. All rights reserved.
//

import CoreData
import Foundation

class DownloadRecordsOperation: BatchRecordOperation<LocalRecord, DownloadRecordOperation> {
    override class var predicate: NSPredicate {
        ManagedRecord.downloadRecordsPredicate
    }

    override func main() {
        syncProgress.status = .downloading

        super.main()
    }

    override func process(_ results: [AnyRecord: Result<LocalRecord, RecordError>], in context: NSManagedObjectContext, completionHandler: @escaping (Result<[AnyRecord: Result<LocalRecord, RecordError>], Error>) -> Void) {
        let operation = FinishDownloadingRecordsOperation(results: results, coordinator: coordinator, context: context)
        operation.resultHandler = { result in
            completionHandler(result)
        }

        operationQueue.addOperation(operation)
    }
}
