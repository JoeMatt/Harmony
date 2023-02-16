//
//  SyncRecordsOperation.swift
//  Harmony
//
//  Created by Riley Testut on 5/22/17.
//  Copyright © 2017 Riley Testut. All rights reserved.
//

import CoreData
import Foundation
@_implementationOnly import os.log
import Roxas

#if canImport(UIKit)
import UIKit
#endif

class SyncRecordsOperation: Operation<[Record<NSManagedObject>: Result<Void, RecordError>], SyncError> {
    let changeToken: Data?

    let syncProgress = SyncProgress(parent: nil, userInfo: nil)

    private let dispatchGroup = DispatchGroup()

    private(set) var updatedChangeToken: Data?
#if canImport(UIKit)
    private var backgroundTaskIdentifier: UIBackgroundTaskIdentifier?
	#endif
    private var recordResults = [Record<NSManagedObject>: Result<Void, RecordError>]()

    override var isAsynchronous: Bool {
        true
    }

    init(changeToken: Data?, coordinator: SyncCoordinator) {
        self.changeToken = changeToken

        super.init(coordinator: coordinator)

        syncProgress.totalUnitCount = 1
        operationQueue.maxConcurrentOperationCount = 1
    }

    override func main() {
        super.main()

        progress.addChild(syncProgress, withPendingUnitCount: 1)
		#if canImport(UIKit)
        backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(withName: "com.rileytestut.Harmony.SyncRecordsOperation") { [weak self] in
                guard let identifier = self?.backgroundTaskIdentifier else { return }
                UIApplication.shared.endBackgroundTask(identifier)
            }
		#endif

        NotificationCenter.default.post(name: SyncCoordinator.didStartSyncingNotification, object: nil)

        let fetchRemoteRecordsOperation = FetchRemoteRecordsOperation(changeToken: changeToken, coordinator: coordinator, recordController: recordController)
        fetchRemoteRecordsOperation.resultHandler = { [weak self] result in
            if case let .success((_, changeToken)) = result {
                self?.updatedChangeToken = changeToken
            }

            self?.finish(result, debugTitle: "Fetch Records Result:")
        }
        syncProgress.status = .fetchingChanges
        syncProgress.addChild(fetchRemoteRecordsOperation.progress, withPendingUnitCount: 0)

        let conflictRecordsOperation = ConflictRecordsOperation(coordinator: coordinator)
        conflictRecordsOperation.resultHandler = { [weak self, unowned conflictRecordsOperation] result in
            self?.finishRecordOperation(conflictRecordsOperation, result: result, debugTitle: "Conflict Result:")
        }
        conflictRecordsOperation.syncProgress = syncProgress

        let uploadRecordsOperation = UploadRecordsOperation(coordinator: coordinator)
        uploadRecordsOperation.resultHandler = { [weak self, unowned uploadRecordsOperation] result in
            self?.finishRecordOperation(uploadRecordsOperation, result: result, debugTitle: "Upload Result:")
        }
        uploadRecordsOperation.syncProgress = syncProgress

        let downloadRecordsOperation = DownloadRecordsOperation(coordinator: coordinator)
        downloadRecordsOperation.resultHandler = { [weak self, unowned downloadRecordsOperation] result in
            self?.finishRecordOperation(downloadRecordsOperation, result: result, debugTitle: "Download Result:")
        }
        downloadRecordsOperation.syncProgress = syncProgress

        let deleteRecordsOperation = DeleteRecordsOperation(coordinator: coordinator)
        deleteRecordsOperation.resultHandler = { [weak self, unowned deleteRecordsOperation] result in
            self?.finishRecordOperation(deleteRecordsOperation, result: result, debugTitle: "Delete Result:")
        }
        deleteRecordsOperation.syncProgress = syncProgress

        let operations = [fetchRemoteRecordsOperation, conflictRecordsOperation, uploadRecordsOperation, downloadRecordsOperation, deleteRecordsOperation]
        for operation in operations {
            dispatchGroup.enter()
            operationQueue.addOperation(operation)
        }

        dispatchGroup.notify(queue: .global()) { [weak self] in
            guard let self = self else { return }

            // Fetch all conflicted records and add conflicted errors for them all to recordResults.
            let context = self.recordController.newBackgroundContext()
            context.performAndWait {
                let fetchRequest = ManagedRecord.fetchRequest() as NSFetchRequest<ManagedRecord>
                fetchRequest.predicate = ManagedRecord.conflictedRecordsPredicate

                do {
                    let records = try context.fetch(fetchRequest)

                    for record in records {
                        let record = Record<NSManagedObject>(record)
                        self.recordResults[record] = .failure(RecordError.conflicted(record))
                    }
                } catch {
                    os_log("%@", type: .error, error.localizedDescription)
                }
            }

            let didFail = self.recordResults.values.contains(where: { result in
                switch result {
                case .success: return false
                case .failure: return true
                }
            })

            if didFail {
                self.result = .failure(SyncError.partial(self.recordResults))
            } else {
                self.result = .success(self.recordResults)
            }

            self.finish()

            if UserDefaults.standard.isDebugModeEnabled {
                self.recordController.printRecords()
            }
        }
    }

    override func finish() {
        guard !isFinished else { return }

        if isCancelled {
            result = .failure(SyncError(GeneralError.cancelled))
        }

        super.finish()
#if canImport(UIKit)
        if let identifier = backgroundTaskIdentifier {
            UIApplication.shared.endBackgroundTask(identifier)

            backgroundTaskIdentifier = nil
        }
		#endif
    }
}

private extension SyncRecordsOperation {
    func finish<T, U: HarmonyError>(_ result: Result<T, U>, debugTitle _: String) {
        do {
            _ = try result.get()

            let context = recordController.newBackgroundContext()
            let recordCount = try context.performAndWait { () -> Int in
                let fetchRequest = ManagedRecord.fetchRequest() as NSFetchRequest<ManagedRecord>
                fetchRequest.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [ConflictRecordsOperation.predicate,
                                                                                            UploadRecordsOperation.predicate,
                                                                                            DownloadRecordsOperation.predicate,
                                                                                            DeleteRecordsOperation.predicate])

                let count = try context.count(for: fetchRequest)
                return count
            }

            syncProgress.totalUnitCount = Int64(recordCount)
        } catch let error as HarmonyError {
            self.operationQueue.cancelAllOperations()

            self.result = .failure(SyncError(error))
            self.finish()
        } catch {
            fatalError("Non-HarmonyError thrown from SyncRecordsOperation.finish")
        }

        dispatchGroup.leave()
    }

    func finishRecordOperation<R, T>(_ operation: BatchRecordOperation<R, T>, result: Result<[AnyRecord: Result<R, RecordError>], Error>, debugTitle: String) {
        // Map operation.recordResults to use Result<Void, RecordError>.
        let recordResults = operation.recordResults.mapValues { result in
            result.map { _ in () }
        }

        os_log("%@ %@", type: .debug, debugTitle, String(describing: result))

        do {
            for (record, result) in recordResults {
                self.recordResults[record] = result
            }

            _ = try result.get()
        } catch {
            self.result = .failure(SyncError.partial(self.recordResults))
            finish()
        }

        dispatchGroup.leave()
    }
}
