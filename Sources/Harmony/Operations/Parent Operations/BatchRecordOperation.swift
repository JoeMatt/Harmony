//
//  BatchRecordOperation.swift
//  Harmony
//
//  Created by Riley Testut on 10/3/18.
//  Copyright © 2018 Riley Testut. All rights reserved.
//

import CoreData
import Foundation
@_implementationOnly import os.log

class BatchRecordOperation<ResultType, OperationType: RecordOperation<ResultType>>: Operation<[Record<NSManagedObject>: Result<ResultType, RecordError>], Error> {
    class var predicate: NSPredicate {
        fatalError()
    }

    var syncProgress: SyncProgress!

    private(set) var recordResults = [AnyRecord: Result<ResultType, RecordError>]()

    override var isAsynchronous: Bool {
        true
    }

    override init(coordinator: SyncCoordinator) {
        super.init(coordinator: coordinator)

        operationQueue.maxConcurrentOperationCount = 5
    }

    override func main() {
        super.main()

        let fetchRequest = ManagedRecord.fetchRequest() as NSFetchRequest<ManagedRecord>
        fetchRequest.predicate = type(of: self).predicate
        fetchRequest.returnsObjectsAsFaults = false

        let dispatchGroup = DispatchGroup()

        recordController.performBackgroundTask { fetchContext in
            let saveContext = self.recordController.newBackgroundContext()

            do {
                let records = try fetchContext.fetch(fetchRequest).map(Record.init)
                records.forEach { self.recordResults[$0] = .failure(RecordError.other($0, GeneralError.unknown)) }

                if !records.isEmpty {
                    // We'll increment totalUnitCount as we add operations.
                    self.progress.totalUnitCount = 0
                }

                var remainingRecordsCount = records.count
                let remainingRecordsOutputQueue = DispatchQueue(label: "com.rileytestut.BatchRecordOperation.remainingRecordsOutputQueue")

                self.process(records, in: fetchContext) { result in
                    do {
                        let records = try result.get()

                        let operations = records.compactMap { record -> OperationType? in
                            do {
                                let operation = try OperationType(record: record, coordinator: self.coordinator, context: saveContext)
                                operation.isBatchOperation = true
                                operation.resultHandler = { result in
                                    self.recordResults[record] = result
                                    dispatchGroup.leave()

                                    if UserDefaults.standard.isDebugModeEnabled {
                                        remainingRecordsOutputQueue.async {
                                            remainingRecordsCount = remainingRecordsCount - 1
                                            os_log("Remaining %@ operations: %@", type: .info, "\(type(of: self))", remainingRecordsCount)
                                        }
                                    }
                                }

                                self.progress.totalUnitCount += 1
                                self.progress.addChild(operation.progress, withPendingUnitCount: 1)

                                dispatchGroup.enter()

                                return operation
                            } catch {
                                self.recordResults[record] = .failure(RecordError(record, error))
                            }

                            return nil
                        }

                        if !records.isEmpty {
                            self.syncProgress.addChild(self.progress, withPendingUnitCount: self.progress.totalUnitCount)
                            self.syncProgress.activeProgress = self.progress
                        } else {
                            self.syncProgress.addChild(self.progress, withPendingUnitCount: 0)
                        }

                        self.operationQueue.addOperations(operations, waitUntilFinished: false)

                        dispatchGroup.notify(queue: .global()) {
                            saveContext.perform {
                                self.process(self.recordResults, in: saveContext) { result in
                                    saveContext.perform {
                                        do {
                                            self.recordResults = try result.get()

                                            guard !self.isCancelled else { throw GeneralError.cancelled }

                                            try saveContext.save()

                                            self.result = .success(self.recordResults)
                                        } catch {
                                            self.result = .failure(error)
                                            self.propagateFailure(error: error)
                                        }

                                        self.process(self.result!, in: saveContext) {
                                            saveContext.perform {
                                                self.finish()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    } catch {
                        self.result = .failure(error)
                        self.propagateFailure(error: error)

                        saveContext.perform {
                            self.finish()
                        }
                    }
                }
            } catch {
                self.result = .failure(error)
                self.propagateFailure(error: error)

                saveContext.perform {
                    self.finish()
                }
            }
        }
    }

    func process(_ records: [Record<NSManagedObject>], in _: NSManagedObjectContext, completionHandler: @escaping (Result<[Record<NSManagedObject>], Error>) -> Void) {
        completionHandler(.success(records))
    }

    func process(_ results: [Record<NSManagedObject>: Result<ResultType, RecordError>],
                 in _: NSManagedObjectContext,
                 completionHandler: @escaping (Result<[Record<NSManagedObject>: Result<ResultType, RecordError>], Error>) -> Void) {
        completionHandler(.success(results))
    }

    func process(_: Result<[Record<NSManagedObject>: Result<ResultType, RecordError>], Error>, in _: NSManagedObjectContext, completionHandler: @escaping () -> Void) {
        completionHandler()
    }

    override func finish() {
        recordController.processPendingUpdates()

        super.finish()
    }
}

private extension BatchRecordOperation {
    func propagateFailure(error: Error) {
        for (record, _) in recordResults {
            recordResults[record] = .failure(RecordError(record, error))
        }
    }
}
