//
//  TestServiceManager.swift
//  
//
//  Created by Joseph Mattiello on 2/16/23.
//

import Foundation
import CoreData
@_implementationOnly import HarmonyTestData
@_implementationOnly import os.log
import Harmony
import Roxas

public class ServiceManager {
	public static let shared: ServiceManager = .init()
	public var services = [any Service]()
}
