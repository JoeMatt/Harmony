//
//  NSPersistentStore+Configuration.swift
//  Harmony
//
//  Created by Riley Testut on 10/22/17.
//  Copyright © 2017 Riley Testut. All rights reserved.
//

import CoreData

public extension NSManagedObjectModel {
    enum Configuration: String {
        case harmony = "Harmony"
        case external = "External"
    }
}

public extension NSPersistentStore {
    var configuration: NSManagedObjectModel.Configuration? {
        let configuration = NSManagedObjectModel.Configuration(rawValue: configurationName)
        return configuration
    }
}
