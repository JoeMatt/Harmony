//
//  Course.swift
//  HarmonyTests
//
//  Created by Riley Testut on 10/21/17.
//  Copyright © 2017 Riley Testut. All rights reserved.
//

import CoreData
import Foundation

import Harmony

@objc(Course)
public class Course: NSManagedObject {}

extension Course: Syncable {
    public class var syncablePrimaryKey: AnyKeyPath {
        \Course.identifier
    }

    public var syncableKeys: Set<AnyKeyPath> {
        [\Course.name]
    }
}
