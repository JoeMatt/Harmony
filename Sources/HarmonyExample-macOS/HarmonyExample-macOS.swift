//
//  HarmonyExample-macOS.swift
//
//
//  Created by Joseph Mattiello on 2/16/23.
//

import Foundation
#if canImport(AppKit)

import AppKit
import Cocoa

@objcMembers
@objc public final class HarmonyExample_macOS: NSObject {
	public class var resources: Bundle {
		#if FRAMEWORK
			let bundle = Bundle(for: HarmonyExample_macOS.self)
		#elseif SWIFT_PACKAGE
			let bundle = Bundle.module
		#elseif STATIC_LIBRARY
			let bundle: Bundle
			if let bundleURL = Bundle.main.url(forResource: "HarmonyExample_macOS", withExtension: "bundle") {
				bundle = Bundle(url: bundleURL)!
			} else {
				bundle = .main
			}
		#else
			let bundle = Bundle.main
		#endif

		return bundle
	}

	public class var main: NSStoryboard { NSStoryboard(name: "Main", bundle: resources) }
}
#endif
