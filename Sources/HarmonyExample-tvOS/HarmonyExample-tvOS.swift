//
//  HarmonyExample-tvOS.swift
//
//
//  Created by Joseph Mattiello on 2/16/23.
//

import Foundation
#if canImport(UIKit)
import UIKit

@objcMembers
@objc public final class HarmonyExample_tvOS: NSObject {
	public class var resources: Bundle {
		#if FRAMEWORK
			let bundle = Bundle(for: HarmonyExample_tvOS.self)
		#elseif SWIFT_PACKAGE
			let bundle = Bundle.module
		#elseif STATIC_LIBRARY
			let bundle: Bundle
			if let bundleURL = Bundle.main.url(forResource: "HarmonyExample_tvOS", withExtension: "bundle") {
				bundle = Bundle(url: bundleURL)!
			} else {
				bundle = .main
			}
		#else
			let bundle = Bundle.main
		#endif

		return bundle
	}

	public class var launchScreen: UIStoryboard { UIStoryboard(name: "LaunchScreen", bundle: resources) }
	public class var main: UIStoryboard { UIStoryboard(name: "Main", bundle: resources) }
}
#endif
