//
//  ConflictRecordsOperation.swift
//  Harmony
//
//  Created by Riley Testut on 11/8/18.
//  Copyright © 2018 Riley Testut. All rights reserved.
//

import CoreData
import Foundation

class ConflictRecordsOperation: BatchRecordOperation<Void, ConflictRecordOperation> {
    override class var predicate: NSPredicate {
        ManagedRecord.conflictRecordsPredicate
    }

    override func main() {
        // Not worth having an additional state for just conflicting records.
        syncProgress.status = .fetchingChanges

        super.main()
    }
}
