//
//  RemoteFile.swift
//  Harmony
//
//  Created by Riley Testut on 11/7/18.
//  Copyright © 2018 Riley Testut. All rights reserved.
//

import CoreData
import Foundation

extension RemoteFile {
    private enum CodingKeys: String, CodingKey {
        case identifier
        case sha1Hash
        case remoteIdentifier
        case versionIdentifier
        case size
    }
}

@objc(RemoteFile)
public class RemoteFile: NSManagedObject, Codable {
    @NSManaged public var identifier: String
    @NSManaged public var sha1Hash: String
    @NSManaged public var size: Int32

    @NSManaged public var remoteIdentifier: String
    @NSManaged public var versionIdentifier: String

    @NSManaged public var localRecord: LocalRecord?

    override private init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }

    public init(remoteIdentifier: String, versionIdentifier: String, size: Int, metadata: [HarmonyMetadataKey: String], context: NSManagedObjectContext) throws {
        guard let identifier = metadata[.relationshipIdentifier], let sha1Hash = metadata[.sha1Hash] else { throw ValidationError.invalidMetadata(metadata) }

        super.init(entity: RemoteFile.entity(), insertInto: context)

        self.identifier = identifier
        self.sha1Hash = sha1Hash
        self.remoteIdentifier = remoteIdentifier
        self.versionIdentifier = versionIdentifier
        self.size = Int32(size)
    }

    public required init(from decoder: Decoder) throws {
        guard let context = decoder.managedObjectContext else { throw ValidationError.nilManagedObjectContext }

        super.init(entity: RemoteFile.entity(), insertInto: nil)

        let container = try decoder.container(keyedBy: CodingKeys.self)

        identifier = try container.decode(String.self, forKey: .identifier)
        sha1Hash = try container.decode(String.self, forKey: .sha1Hash)
        remoteIdentifier = try container.decode(String.self, forKey: .remoteIdentifier)
        versionIdentifier = try container.decode(String.self, forKey: .versionIdentifier)
        size = try container.decode(Int32.self, forKey: .size)

        context.insert(self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(identifier, forKey: .identifier)
        try container.encode(sha1Hash, forKey: .sha1Hash)
        try container.encode(remoteIdentifier, forKey: .remoteIdentifier)
        try container.encode(versionIdentifier, forKey: .versionIdentifier)
        try container.encode(size, forKey: .size)
    }

    override public func willSave() {
        super.willSave()

        guard !isDeleted else { return }

        if localRecord == nil {
            managedObjectContext?.delete(self)
        }
    }
}
