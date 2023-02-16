//
//  TestServiceManager.swift
//  
//
//  Created by Joseph Mattiello on 2/16/23.
//

import Foundation
import CoreData
@_exported import HarmonyTestData
@_exported import Harmony
@_exported import Roxas

public class ServiceManager {
	public static let shared: ServiceManager = .init()
	public var services = [any Service]()
}
