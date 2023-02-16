//
//  JSONDecoder+ManagedObjectContext.swift
//  Harmony
//
//  Created by Riley Testut on 10/3/18.
//  Copyright © 2018 Riley Testut. All rights reserved.
//

import CoreData
import Foundation

private extension CodingUserInfoKey {
    static let managedObjectContext = CodingUserInfoKey(rawValue: "managedObjectContext")!
}

public extension JSONDecoder {
    var managedObjectContext: NSManagedObjectContext? {
        get {
            let managedObjectContext = userInfo[.managedObjectContext] as? NSManagedObjectContext
            return managedObjectContext
        }
        set {
            userInfo[.managedObjectContext] = newValue
        }
    }
}

public extension Decoder {
    var managedObjectContext: NSManagedObjectContext? {
        let managedObjectContext = userInfo[.managedObjectContext] as? NSManagedObjectContext
        return managedObjectContext
    }
}
