//
//  SyncCoordinator.swift
//  Harmony
//
//  Created by Riley Testut on 5/17/17.
//  Copyright © 2017 Riley Testut. All rights reserved.
//

import CoreData
import Foundation
@_implementationOnly import os.log
#if canImport(UIKit)
import UIKit
#endif

public extension SyncCoordinator {
    static let didStartSyncingNotification = Notification.Name("syncCoordinatorDidStartSyncingNotification")
    static let didFinishSyncingNotification = Notification.Name("syncCoordinatorDidFinishSyncingNotification")

    static let syncResultKey = "syncResult"
}

public extension SyncCoordinator {
    enum ConflictResolution {
        case local
        case remote(Version)
    }
}

public typealias SyncResult = Result<[AnyRecord: Result<Void, RecordError>], SyncError>

public final class SyncCoordinator {
    public let service: any Service
    public let persistentContainer: NSPersistentContainer

    public let recordController: RecordController

    public var account: Account? {
        managedAccount?.managedObjectContext?.performAndWait {
            guard let managedAccount = self.managedAccount else { return nil }

            let account = Account(account: managedAccount)
            return account
        }
    }

    private var managedAccount: ManagedAccount? {
        guard _managedAccount == nil else { return _managedAccount }

        let context = recordController.newBackgroundContext()
        _managedAccount = context.performAndWait {
            do {
                let accounts = try context.fetch(ManagedAccount.currentAccountFetchRequest())
                return accounts.first
            } catch {
                os_log("Failed to fetch managed account. %@", type: .error, error.localizedDescription)
                return nil
            }
        }

        return _managedAccount
    }

    private var _managedAccount: ManagedAccount? {
        didSet {
            _managedAccountContext = _managedAccount?.managedObjectContext
        }
    }

    private var _managedAccountContext: NSManagedObjectContext?

    public private(set) var isAuthenticated = false
    public private(set) var isSyncing = false

    public var isStarted: Bool {
        recordController.isStarted
    }

    private let operationQueue: OperationQueue
    private let syncOperationQueue: OperationQueue

    public init(service: any Service, persistentContainer: NSPersistentContainer) {
        self.service = service
        self.persistentContainer = persistentContainer
        recordController = RecordController(persistentContainer: persistentContainer)

        operationQueue = OperationQueue()
        operationQueue.name = "com.rileytestut.Harmony.SyncCoordinator.operationQueue"
        operationQueue.qualityOfService = .utility

        syncOperationQueue = OperationQueue()
        syncOperationQueue.name = "com.rileytestut.Harmony.SyncCoordinator.syncOperationQueue"
        syncOperationQueue.qualityOfService = .utility
        syncOperationQueue.maxConcurrentOperationCount = 1
    }

    deinit {
        do {
            try self.stop()
        } catch {
            os_log("Failed to stop SyncCoordinator. %@", type: .error, error.localizedDescription)
        }
    }
}

public extension SyncCoordinator {
    func start(completionHandler: @escaping (Result<Account?, Error>) -> Void) {
        guard !isStarted else { return completionHandler(.success(account)) }

        recordController.start { result in
            do {
                try result.get()

                self.authenticate { result in
                    do {
                        let account = try result.get()
                        completionHandler(.success(account))
                    } catch AuthenticationError.noSavedCredentials {
                        completionHandler(.success(nil))
                    } catch {
                        if self.account == nil {
                            completionHandler(.success(nil))
                        } else {
                            completionHandler(.failure(error))
                        }
                    }
                }
            } catch {
                completionHandler(.failure(error))
            }
        }
    }

    func stop() throws {
        guard isStarted else { return }

        try recordController.stop()

        // Intentionally do not deauthorize, as that also resets the database.
        // No harm in allowing user to remain authorized even if not syncing.
        // self.deauthenticate()
    }

    @discardableResult func sync() -> Progress? {
        guard let account = managedAccount, let context = account.managedObjectContext else { return nil }

        return context.performAndWait {
            // If there is already a sync operation waiting to execute, no use adding another one.
            if self.syncOperationQueue.operationCount > 1, let operation = self.syncOperationQueue.operations.last as? SyncRecordsOperation {
                return operation.syncProgress
            }

            self.isSyncing = true

            let syncRecordsOperation = SyncRecordsOperation(changeToken: account.changeToken, coordinator: self)
            syncRecordsOperation.resultHandler = { [weak syncRecordsOperation] result in
                if let changeToken = syncRecordsOperation?.updatedChangeToken {
                    let context = self.recordController.newBackgroundContext()
                    context.performAndWait {
                        let account = account.in(context)
                        account.changeToken = changeToken

                        do {
                            try context.save()
                        } catch {
                            os_log("Failed to save change token. %@", type: .error, error.localizedDescription)
                        }
                    }
                }

                NotificationCenter.default.post(name: SyncCoordinator.didFinishSyncingNotification, object: self, userInfo: [SyncCoordinator.syncResultKey: result])

                if self.syncOperationQueue.operations.isEmpty {
                    self.isSyncing = false
                }
            }
            self.syncOperationQueue.addOperation(syncRecordsOperation)

            return syncRecordsOperation.syncProgress
        }
    }
}

public extension SyncCoordinator {
#if canImport(UIKit)
    func authenticate(presentingViewController: UIViewController? = nil, completionHandler: @escaping (Result<Account, AuthenticationError>) -> Void) {
        guard isStarted
        else {
            start { result in
                switch result {
                case .success: self.authenticate(presentingViewController: presentingViewController, completionHandler: completionHandler)
                case let .failure(error): completionHandler(.failure(AuthenticationError(error)))
                }
            }

            return
        }

        let operation = ServiceOperation<Account, AuthenticationError>(coordinator: self) { completionHandler -> Progress? in
                DispatchQueue.main.async {
                    if let presentingViewController = presentingViewController {
                        self.service.authenticate(withPresentingViewController: presentingViewController, completionHandler: completionHandler)
                    } else {
                        self.service.authenticateInBackground(completionHandler: completionHandler)
                    }
                }
                return nil
            }
        operation.resultHandler = { result in
            let result = result.mapError { AuthenticationError($0) }
            switch result {
            case let .success(account):
                let context = self.recordController.newBackgroundContext()
                context.performAndWait {
                    let account = ManagedAccount(account: account, service: self.service, context: context)

                    do {
                        try context.save()

                        self.isAuthenticated = true
                    } catch {
                        os_log("Failed to save account. %@ %@", type: .error, account, error.localizedDescription)
                    }
                }

            case .failure: break
            }

            completionHandler(result)
        }

        // Don't add to operation queue, or else it might result in a deadlock
        // if another operation we've started requires reauthentication.
        operation.requiresAuthentication = false
        operation.start()
    }
	#else
	func authenticate(completionHandler: @escaping (Result<Account, AuthenticationError>) -> Void) {
		guard isStarted
		else {
			start { result in
				switch result {
				case .success: self.authenticate(completionHandler: completionHandler)
				case let .failure(error): completionHandler(.failure(AuthenticationError(error)))
				}
			}

			return
		}

		let operation = ServiceOperation<Account, AuthenticationError>(coordinator: self) { completionHandler -> Progress? in
				DispatchQueue.main.async {
					self.service.authenticateInBackground(completionHandler: completionHandler)
				}
				return nil
			}
		operation.resultHandler = { result in
			let result = result.mapError { AuthenticationError($0) }
			switch result {
			case let .success(account):
				let context = self.recordController.newBackgroundContext()
				context.performAndWait {
					let account = ManagedAccount(account: account, service: self.service, context: context)

					do {
						try context.save()

						self.isAuthenticated = true
					} catch {
						os_log("Failed to save account. %@ %@", type: .error, account, error.localizedDescription)
					}
				}

			case .failure: break
			}

			completionHandler(result)
		}

		// Don't add to operation queue, or else it might result in a deadlock
		// if another operation we've started requires reauthentication.
		operation.requiresAuthentication = false
		operation.start()
	}
	#endif

    func deauthenticate(completionHandler: @escaping (Result<Void, DeauthenticationError>) -> Void) {
        // Set isAuthenticated to false immediately to disable syncing while we attempt deauthentication.
        let isAuthenticated = self.isAuthenticated
        self.isAuthenticated = false

        let operation = ServiceOperation<Void, DeauthenticationError>(coordinator: self) { completionHandler -> Progress? in
                self.service.deauthenticate(completionHandler: completionHandler)
                return nil
            }
        operation.requiresAuthentication = false
        operation.resultHandler = { result in
            do {
                try result.get()

                try self.stop()
                try self.recordController.reset()

                self._managedAccount = nil
                self.isAuthenticated = false

                completionHandler(.success)
            } catch {
                self.isAuthenticated = isAuthenticated
                completionHandler(.failure(DeauthenticationError(error)))
            }
        }

        syncOperationQueue.cancelAllOperations()
        syncOperationQueue.addOperation(operation)
    }
}

public extension SyncCoordinator {
    @discardableResult func fetchVersions<T: NSManagedObject>(for record: Record<T>, completionHandler: @escaping (Result<[Version], RecordError>) -> Void) -> Progress {
        let operation = ServiceOperation(coordinator: self) { completionHandler -> Progress? in
            self.service.fetchVersions(for: AnyRecord(record), completionHandler: completionHandler)
        }
        operation.resultHandler = { result in
            switch result {
            case let .success(versions): completionHandler(.success(versions))
            case let .failure(error): completionHandler(.failure(RecordError(Record(record), error)))
            }
        }

        operationQueue.addOperation(operation)

        return operation.progress
    }

    @discardableResult func upload<T: NSManagedObject>(_ record: Record<T>, completionHandler: @escaping (Result<Record<T>, RecordError>) -> Void) -> Progress {
        let progress = Progress.discreteProgress(totalUnitCount: 1)

        let context = recordController.newBackgroundContext()

        do {
            let operation = try UploadRecordOperation(record: record, coordinator: self, context: context)
            operation.resultHandler = { result in
                do {
                    _ = try result.get()

                    let context = self.recordController.newBackgroundContext()
                    record.perform(in: context) { managedRecord in
                        let record = Record(managedRecord) as Record<T>
                        completionHandler(.success(record))
                    }
                } catch {
                    completionHandler(.failure(RecordError(Record(record), error)))
                }
            }

            progress.addChild(operation.progress, withPendingUnitCount: 1)

            operationQueue.addOperation(operation)
        } catch {
            completionHandler(.failure(RecordError(Record(record), error)))
        }

        return progress
    }

    @discardableResult func restore<T: NSManagedObject>(_ record: Record<T>, to version: Version, completionHandler: @escaping (Result<Record<T>, RecordError>) -> Void) -> Progress {
        let progress = Progress.discreteProgress(totalUnitCount: 1)

        let context = recordController.newBackgroundContext()

        do {
            let operation = try DownloadRecordOperation(record: record, coordinator: self, context: context)
            operation.version = version
            operation.resultHandler = { result in
                do {
                    _ = try result.get()

                    let context = self.recordController.newBackgroundContext()
                    try record.perform(in: context) { managedRecord in
                        // Mark as updated so we can upload restored version on next sync.
                        managedRecord.localRecord?.status = .updated

                        if let version = managedRecord.remoteRecord?.version {
                            // Assign to same version as RemoteRecord to prevent sync conflicts.
                            managedRecord.localRecord?.version = version
                        }

                        try context.save()

                        let record = Record(managedRecord) as Record<T>
                        completionHandler(.success(record))
                    }
                } catch {
                    completionHandler(.failure(RecordError(Record(record), error)))
                }
            }

            progress.addChild(operation.progress, withPendingUnitCount: 1)

            operationQueue.addOperation(operation)
        } catch {
            completionHandler(.failure(RecordError(Record(record), error)))
        }

        return progress
    }

    @discardableResult func resolveConflictedRecord<T: NSManagedObject>(_ record: Record<T>, resolution: ConflictResolution, completionHandler: @escaping (Result<Record<T>, RecordError>) -> Void) -> Progress {
        let progress: Progress

        record.perform { managedRecord in
            // Mark as not conflicted to prevent operations from throwing "record conflicted" errors.
            managedRecord.isConflicted = false
        }

        func finish(_ result: Result<Record<T>, RecordError>) {
            do {
                let record = try result.get()

                try record.perform { managedRecord in
                    managedRecord.isConflicted = false

                    try managedRecord.managedObjectContext?.save()

                    let resolvedRecord = Record<T>(managedRecord)
                    completionHandler(.success(resolvedRecord))
                }
            } catch {
                record.perform { managedRecord in
                    managedRecord.isConflicted = true
                }

                completionHandler(.failure(RecordError(AnyRecord(record), error)))
            }
        }

        switch resolution {
        case .local:
            progress = upload(record) { result in
                finish(result)
            }

        case let .remote(version):
            progress = restore(record, to: version) { result in
                finish(result)
            }
        }

        return progress
    }
}
