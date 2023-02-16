//
//  Syncable.swift
//  Harmony
//
//  Created by Riley Testut on 5/25/17.
//  Copyright © 2017 Riley Testut. All rights reserved.
//

import CoreData
import Foundation

public enum ConflictResolution {
    case conflict
    case local
    case remote
    case newest
    case oldest
}

public protocol Syncable: NSManagedObject {
    static var syncablePrimaryKey: AnyKeyPath { get }

    var syncableType: String { get }

    var syncableKeys: Set<AnyKeyPath> { get }
    var syncableRelationships: Set<AnyKeyPath> { get }

    var syncableFiles: Set<File> { get }
    var syncableMetadata: [HarmonyMetadataKey: String] { get }

    var syncableLocalizedName: String? { get }

    var isSyncingEnabled: Bool { get }

    func prepareForSync(_ record: AnyRecord) throws
    func awakeFromSync(_ record: AnyRecord) throws

    func resolveConflict(_ record: AnyRecord) -> ConflictResolution
}

public extension Syncable {
    var syncableType: String {
        guard let type = entity.name else { fatalError("SyncableManagedObjects must have a valid entity name.") }
        return type
    }

    var syncableFiles: Set<File> {
        []
    }

    var syncableRelationships: Set<AnyKeyPath> {
        []
    }

    var isSyncingEnabled: Bool {
        true
    }

    var syncableLocalizedName: String? {
        nil
    }

    var syncableMetadata: [HarmonyMetadataKey: String] {
        [:]
    }

    func prepareForSync(_: AnyRecord) {}

    func awakeFromSync(_: AnyRecord) {}

    func resolveConflict(_: AnyRecord) -> ConflictResolution {
        .conflict
    }
}

public extension Syncable {
    internal(set) var syncableIdentifier: String? {
        get {
            guard let keyPath = Self.syncablePrimaryKey.stringValue else { fatalError("Syncable.syncablePrimaryKey must reference an @objc String property.") }
            guard let value = value(forKeyPath: keyPath) else { return nil } // Valid to have nil value (for example, if property itself is nil, or self has been deleted).
            guard let identifier = value as? String else { fatalError("Syncable.syncablePrimaryKey must reference an @objc String property.") }

            return identifier
        }
        set {
            guard let keyPath = Self.syncablePrimaryKey.stringValue else { fatalError("Syncable.syncablePrimaryKey must reference an @objc String property.") }
            setValue(newValue, forKeyPath: keyPath)
        }
    }
}

internal extension Syncable {
    var syncableRelationshipObjects: [String: Syncable] {
        var relationshipObjects = [String: Syncable]()

        for keyPath in syncableRelationships {
            guard let stringValue = keyPath.stringValue else { continue }

            let relationshipObject = value(forKeyPath: stringValue) as? Syncable
            relationshipObjects[stringValue] = relationshipObject
        }

        return relationshipObjects
    }
}
