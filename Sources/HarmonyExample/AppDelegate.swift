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
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		let storyboard: UIStoryboard = MainStoryboard
		self.window = UIWindow(frame: UIScreen.main.bounds)
		let rootVC = storyboard.instantiateInitialViewController()

		self.window?.rootViewController = rootVC
		self.window?.makeKeyAndVisible()

        return true
    }

    func applicationWillResignActive(_: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}
#else
import AppKit
import Cocoa
@_exported import HarmonyExample_macOS

@NSApplicationMain
class AppDelegate: NSResponder, NSApplicationDelegate {
	var window: NSWindow?

	func applicationDidFinishLaunching(_ notification: Notification) {
		let storyboard: NSStoryboard = HarmonyExample_macOS.main
		let window = storyboard.instantiateController(withIdentifier: "MainWindow") as! NSWindowController
		let rootController = storyboard.instantiateInitialController() as! NSViewController
		window.contentViewController = rootController
		window.showWindow(self)
	}

	func applicationWillBecomeActive(_ notification: Notification) {

	}

	func applicationDidBecomeActive(_ notification: Notification) {

	}

	func applicationWillTerminate(_ notification: Notification) {

	}
}

#endif
