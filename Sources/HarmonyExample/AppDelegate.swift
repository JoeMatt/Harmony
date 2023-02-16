//
//  AppDelegate.swift
//  HarmonyExample
//
//  Created by Riley Testut on 1/23/18.
//  Copyright © 2018 Riley Testut. All rights reserved.
//

#if canImport(UIKit)
import UIKit
#if os(iOS) || targetEnvironment(macCatalyst)
@_exported import HarmonyExample_iOS
var MainStoryboard: UIStoryboard { HarmonyExample_iOS.main }

#elseif os(tvOS)
@_exported import HarmonyExample_tvOS
var MainStoryboard: UIStoryboard { HarmonyExample_tvOS.main }
#else
#error ("Unsupported OS")
#endif

@UIApplicationMain
open class AppDelegate: UIResponder, UIApplicationDelegate {
	public var window: UIWindow?

	public func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		let storyboard: UIStoryboard = MainStoryboard
		self.window = UIWindow(frame: UIScreen.main.bounds)
		let rootVC = storyboard.instantiateInitialViewController()

		self.window?.rootViewController = rootVC
		self.window?.makeKeyAndVisible()

        return true
    }

	public func applicationWillResignActive(_: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

	public func applicationDidEnterBackground(_: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

	public func applicationWillEnterForeground(_: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

	public func applicationDidBecomeActive(_: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

	public func applicationWillTerminate(_: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}
#else
import AppKit
import Cocoa
@_exported import HarmonyExample_macOS

@NSApplicationMain
open class AppDelegate: NSResponder, NSApplicationDelegate {
	var window: NSWindow?

	public func applicationDidFinishLaunching(_ notification: Notification) {
		let storyboard: NSStoryboard = HarmonyExample_macOS.main
		let window = storyboard.instantiateController(withIdentifier: "MainWindow") as! NSWindowController
		let rootController = storyboard.instantiateInitialController() as! NSViewController
		window.contentViewController = rootController
		window.showWindow(self)
	}

	public func applicationWillBecomeActive(_ notification: Notification) {

	}

	public func applicationDidBecomeActive(_ notification: Notification) {

	}

	public func applicationWillTerminate(_ notification: Notification) {

	}
}

#endif
