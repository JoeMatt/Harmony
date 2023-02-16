//
//  DownloadRecordOperation.swift
//  Harmony
//
//  Created by Riley Testut on 10/3/18.
//  Copyright © 2018 Riley Testut. All rights reserved.
//

import CoreData
import Foundation

@_implementationOnly import os.log
import Roxas

class DownloadRecordOperation: RecordOperation<LocalRecord> {
    var version: Version?

    required init<T: NSManagedObject>(record: Record<T>, coordinator: SyncCoordinator, context: NSManagedObjectContext) throws {
        try super.init(record: record, coordinator: coordinator, context: context)

        // Record itself = 1 unit, files = 3 units.
        progress.totalUnitCount = 4
    }

    override func main() {
        super.main()

        if UserDefaults.standard.isDebugModeEnabled {
            os_log("Started downloading record: %@", type: .info, String(describing: record.recordID))
        }

        downloadRecord { result in
            do {
                let localRecord = try result.get()

                self.downloadFiles(for: localRecord) { result in
                    self.managedObjectContext.perform {
                        do {
                            let files = try result.get()
                            localRecord.downloadedFiles = files

                            self.result = .success(localRecord)
                        } catch {
                            self.result = .failure(RecordError(self.record, error))

                            localRecord.removeFromContext()
                        }

                        self.finishDownload()
                    }
                }
            } catch {
                self.result = .failure(RecordError(self.record, error))
                self.finishDownload()
            }
        }
    }

    override func finish() {
        super.finish()

        if UserDefaults.standard.isDebugModeEnabled {
            os_log("Finished downloading record: %@", type: .info, "\(record.recordID)")
        }
    }
}

private extension DownloadRecordOperation {
    func finishDownload() {
        if isBatchOperation {
            finish()
        } else {
            let operation = FinishDownloadingRecordsOperation(results: [record: result!], coordinator: coordinator, context: managedObjectContext)
            operation.resultHandler = { result in
                do {
                    let results = try result.get()

                    guard let result = results.values.first else { throw RecordError.other(self.record, GeneralError.unknown) }

                    let tempLocalRecord = try result.get()

                    try self.managedObjectContext.save()

                    let localRecord = tempLocalRecord.in(self.managedObjectContext)
                    self.result = .success(localRecord)
                } catch {
                    self.result = .failure(RecordError(self.record, error))
                }

                self.finish()
            }

            operationQueue.addOperation(operation)
        }
    }

    func downloadRecord(completionHandler: @escaping (Result<LocalRecord, RecordError>) -> Void) {
        record.perform { managedRecord in
            guard let remoteRecord = managedRecord.remoteRecord else { return completionHandler(.failure(RecordError(self.record, ValidationError.nilRemoteRecord))) }

            let version: Version

            if let recordVersion = self.version {
                version = recordVersion
            } else if remoteRecord.isLocked {
                guard let previousVersion = remoteRecord.previousUnlockedVersion
                else {
                    return completionHandler(.failure(RecordError.locked(self.record)))
                }

                version = previousVersion
            } else {
                version = remoteRecord.version
            }

            let operation = ServiceOperation(coordinator: self.coordinator) { completionHandler in
                self.service.download(self.record, version: version, context: self.managedObjectContext, completionHandler: completionHandler)
            }
            operation.resultHandler = { result in
                do {
                    let localRecord = try result.get()
                    localRecord.status = .normal
                    localRecord.modificationDate = version.date
                    localRecord.version = version

                    let remoteRecord = remoteRecord.in(self.managedObjectContext)
                    remoteRecord.status = .normal

                    completionHandler(.success(localRecord))
                } catch {
                    completionHandler(.failure(RecordError(self.record, error)))
                }
            }

            self.progress.addChild(operation.progress, withPendingUnitCount: 1)
            self.operationQueue.addOperation(operation)
        }
    }

    func downloadFiles(for localRecord: LocalRecord, completionHandler: @escaping (Result<Set<File>, RecordError>) -> Void) {
        // Retrieve files from self.record.localRecord because file URLs may depend on relationships that haven't been downloaded yet.
        // If self.record.localRecord doesn't exist, we can just assume we should download all files.
        let filesByIdentifier = record.perform { managedRecord -> [String: File]? in
            guard let recordedObject = managedRecord.localRecord?.recordedObject else { return nil }

            let dictionary = Dictionary(recordedObject.syncableFiles, keyedBy: \.identifier)
            return dictionary
        }

        // Suspend operation queue to prevent download operations from starting automatically.
        operationQueue.isSuspended = true

        let filesProgress = Progress.discreteProgress(totalUnitCount: 0)

        var files = Set<File>()
        var errors = [FileError]()

        let dispatchGroup = DispatchGroup()

        for remoteFile in localRecord.remoteFiles {
            do {
                // If there _are_ cached files, compare hashes to ensure we're not unnecessarily downloading unchanged files.
                if let filesByIdentifier = filesByIdentifier {
                    guard let localFile = filesByIdentifier[remoteFile.identifier]
                    else {
                        throw FileError.unknownFile(remoteFile.identifier)
                    }

                    do {
                        let hash = try RSTHasher.sha1HashOfFile(at: localFile.fileURL)

                        if remoteFile.sha1Hash == hash {
                            // Hash is the same, so don't download file.
                            continue
                        }
                    } catch CocoaError.fileNoSuchFile {
                        // Ignore
                    } catch {
                        errors.append(FileError(remoteFile.identifier, error))
                    }
                }

                let fileIdentifier = remoteFile.identifier

                dispatchGroup.enter()

                let operation = ServiceOperation<File, FileError>(coordinator: coordinator) { completionHandler in
                        self.managedObjectContext.performAndWait {
                            self.service.download(remoteFile, completionHandler: completionHandler)
                        }
                    }
                operation.resultHandler = { result in
                    do {
                        let file = try result.get()
                        files.insert(file)
                    } catch {
                        errors.append(FileError(fileIdentifier, error))
                    }

                    dispatchGroup.leave()
                }

                filesProgress.totalUnitCount += 1
                filesProgress.addChild(operation.progress, withPendingUnitCount: 1)

                operationQueue.addOperation(operation)
            } catch {
                errors.append(FileError(remoteFile.identifier, error))
            }
        }

        if errors.isEmpty {
            progress.addChild(filesProgress, withPendingUnitCount: 3)

            operationQueue.isSuspended = false
        }

        dispatchGroup.notify(queue: .global()) {
            self.managedObjectContext.perform {
                if !errors.isEmpty {
                    completionHandler(.failure(.filesFailed(self.record, errors)))
                } else {
                    completionHandler(.success(files))
                }
            }
        }
    }
}
