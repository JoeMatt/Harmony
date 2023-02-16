//
//  MockService.swift
//  HarmonyTests
//
//  Created by Riley Testut on 1/16/18.
//  Copyright © 2018 Riley Testut. All rights reserved.
//

import CoreData
import Foundation
import UIKit

@testable import Harmony

struct MockService {
    let localizedName = "MockService"
    let identifier = "MockService"

    let latestChangeToken = Data([1, 2, 3, 4, 5])

    var records = Set<RemoteRecord>()
    var changes = Set<RemoteRecord>()
}

extension MockService: Service {
    func fetchAllRemoteRecords(context: NSManagedObjectContext, completionHandler: @escaping (Result<(Set<RemoteRecord>, Data), FetchError>) -> Void) -> Progress {
        let progress = Progress(totalUnitCount: 0)

        context.perform {
            let result = Result<(Set<RemoteRecord>, Data), FetchError>.success((self.records, Data()))

            progress.totalUnitCount = Int64(self.changes.count)
            progress.completedUnitCount = Int64(self.changes.count)

            completionHandler(result)
        }

        return progress
    }

    func fetchChangedRemoteRecords(changeToken: Data, context: NSManagedObjectContext, completionHandler: @escaping (Result<(Set<RemoteRecord>, Set<String>, Data), FetchError>) -> Void) -> Progress {
        let progress = Progress(totalUnitCount: 0)

        context.perform {
            let result: Result<(Set<RemoteRecord>, Set<String>, Data), FetchError>

            if changeToken == self.latestChangeToken {
                result = .success((self.changes, [], Data()))

                progress.totalUnitCount = Int64(self.changes.count)
                progress.completedUnitCount = Int64(self.changes.count)
            } else {
                result = .failure(.invalidChangeToken(changeToken))
            }

            completionHandler(result)
        }

        return progress
    }

    func authenticate(withPresentingViewController _: UIViewController, completionHandler _: @escaping (Result<Account, AuthenticationError>) -> Void) {}

    func authenticateInBackground(completionHandler _: @escaping (Result<Account, AuthenticationError>) -> Void) {}

    func deauthenticate(completionHandler _: @escaping (Result<Void, DeauthenticationError>) -> Void) {}

    func upload(_: AnyRecord, metadata _: [HarmonyMetadataKey: Any], context _: NSManagedObjectContext, completionHandler _: @escaping (Result<RemoteRecord, RecordError>) -> Void) -> Progress {
        fatalError()
    }

    func download(_: AnyRecord, version _: Version, context _: NSManagedObjectContext, completionHandler _: @escaping (Result<LocalRecord, RecordError>) -> Void) -> Progress {
        fatalError()
    }

    func delete(_: AnyRecord, completionHandler _: @escaping (Result<Void, RecordError>) -> Void) -> Progress {
        fatalError()
    }

    func upload(_: File, for _: AnyRecord, metadata _: [HarmonyMetadataKey: Any], context _: NSManagedObjectContext, completionHandler _: @escaping (Result<RemoteFile, FileError>) -> Void) -> Progress {
        fatalError()
    }

    func download(_: RemoteFile, completionHandler _: @escaping (Result<File, FileError>) -> Void) -> Progress {
        fatalError()
    }

    func delete(_: RemoteFile, completionHandler _: @escaping (Result<Void, FileError>) -> Void) -> Progress {
        fatalError()
    }

    func updateMetadata(_: [HarmonyMetadataKey: Any], for _: AnyRecord, completionHandler _: @escaping (Result<Void, RecordError>) -> Void) -> Progress {
        fatalError()
    }

    func fetchVersions(for _: AnyRecord, completionHandler _: @escaping (Result<[Version], RecordError>) -> Void) -> Progress {
        fatalError()
    }
}
