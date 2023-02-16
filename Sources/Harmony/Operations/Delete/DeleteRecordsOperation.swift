//
//  DeleteRecordsOperation.swift
//  Harmony
//
//  Created by Riley Testut on 11/8/18.
//  Copyright © 2018 Riley Testut. All rights reserved.
//

import CoreData
import Foundation
@_implementationOnly import os.log

class DeleteRecordsOperation: BatchRecordOperation<Void, DeleteRecordOperation> {
    private var syncableFiles = [AnyRecord: Set<File>]()

    override class var predicate: NSPredicate {
        ManagedRecord.deleteRecordsPredicate
    }

    override func main() {
        syncProgress.status = .deleting

        super.main()
    }

    override func process(_ records: [AnyRecord], in _: NSManagedObjectContext, completionHandler: @escaping (Result<[AnyRecord], Error>) -> Void) {
        for record in records {
            record.perform { managedRecord in
                guard let syncableFiles = managedRecord.localRecord?.recordedObject?.syncableFiles else { return }
                self.syncableFiles[record] = syncableFiles
            }
        }

        completionHandler(.success(records))
    }

    override func process(_ result: Result<[AnyRecord: Result<Void, RecordError>], Error>, in _: NSManagedObjectContext, completionHandler: @escaping () -> Void) {
        guard case let .success(results) = result else { return completionHandler() }

        for (record, result) in results {
            guard case .success = result else { continue }

            guard let files = syncableFiles[record] else { continue }

            for file in files {
                do {
                    try FileManager.default.removeItem(at: file.fileURL)
                } catch CocoaError.fileNoSuchFile {
                    // Ignore
                } catch {
                    os_log("Harmony failed to delete file at URL: %@", type: .error, String(describing: file.fileURL))
                }
            }
        }

        completionHandler()
    }
}
