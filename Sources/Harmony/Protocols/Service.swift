//
//  Service.swift
//  Harmony
//
//  Created by Riley Testut on 6/4/17.
//  Copyright © 2017 Riley Testut. All rights reserved.
//

import CoreData
import Foundation

#if canImport(UIKit)
    import UIKit
#endif

public typealias AuthenticationResult = Result<Account, AuthenticationError>

public protocol Service: Equatable {
    var localizedName: String { get }
    var identifier: String { get }

    #if canImport(UIKit)
        func authenticate(withPresentingViewController viewController: UIViewController, completionHandler: @escaping (AuthenticationResult) -> Void)
    #else
        func authenticate(completionHandler: @escaping (AuthenticationResult) -> Void)
    #endif
    func authenticateInBackground(completionHandler: @escaping (AuthenticationResult) -> Void)

    func deauthenticate(completionHandler: @escaping (Result<Void, DeauthenticationError>) -> Void)

    func fetchAllRemoteRecords(context: NSManagedObjectContext, completionHandler: @escaping (Result<(Set<RemoteRecord>, Data), FetchError>) -> Void) -> Progress
    func fetchChangedRemoteRecords(changeToken: Data, context: NSManagedObjectContext, completionHandler: @escaping (Result<(Set<RemoteRecord>, Set<String>, Data), FetchError>) -> Void) -> Progress

    func upload(_ record: AnyRecord, metadata: [HarmonyMetadataKey: Any], context: NSManagedObjectContext, completionHandler: @escaping (Result<RemoteRecord, RecordError>) -> Void) -> Progress
    func download(_ record: AnyRecord, version: Version, context: NSManagedObjectContext, completionHandler: @escaping (Result<LocalRecord, RecordError>) -> Void) -> Progress
    func delete(_ record: AnyRecord, completionHandler: @escaping (Result<Void, RecordError>) -> Void) -> Progress

    func upload(_ file: File, for record: AnyRecord, metadata: [HarmonyMetadataKey: Any], context: NSManagedObjectContext, completionHandler: @escaping (Result<RemoteFile, FileError>) -> Void) -> Progress
    func download(_ remoteFile: RemoteFile, completionHandler: @escaping (Result<File, FileError>) -> Void) -> Progress
    func delete(_ remoteFile: RemoteFile, completionHandler: @escaping (Result<Void, FileError>) -> Void) -> Progress

    func updateMetadata(_ metadata: [HarmonyMetadataKey: Any], for record: AnyRecord, completionHandler: @escaping (Result<Void, RecordError>) -> Void) -> Progress

    func fetchVersions(for record: AnyRecord, completionHandler: @escaping (Result<[Version], RecordError>) -> Void) -> Progress
}

public extension Equatable where Self: Service {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.identifier == rhs.identifier
    }

    static func != (lhs: Self, rhs: Self) -> Bool {
        !(lhs == rhs)
    }

    static func ~= (lhs: Self, rhs: Self) -> Bool {
        lhs == rhs
    }
}

@available(tvOS 13.0, *)
public extension Identifiable where Self: Service {
    var id: String { identifier }
}
