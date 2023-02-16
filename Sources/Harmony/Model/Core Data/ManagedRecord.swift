//
//  ManagedRecord.swift
//  Harmony
//
//  Created by Riley Testut on 1/8/18.
//  Copyright © 2018 Riley Testut. All rights reserved.
//

import CoreData
import Foundation

@objc(ManagedRecord)
public class ManagedRecord: NSManagedObject, RecordEntry {
    /* Properties */
    @NSManaged var isConflicted: Bool

    @NSManaged var isSyncingEnabled: Bool

    @NSManaged public internal(set) var recordedObjectType: String
    @NSManaged public internal(set) var recordedObjectIdentifier: String

    /* Relationships */
    @NSManaged public var localRecord: LocalRecord?
    @NSManaged public var remoteRecord: RemoteRecord?

    override private init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
}

extension ManagedRecord {
    @nonobjc class func fetchRequest() -> NSFetchRequest<ManagedRecord> {
        NSFetchRequest<ManagedRecord>(entityName: "ManagedRecord")
    }
}
