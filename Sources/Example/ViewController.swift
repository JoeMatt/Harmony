//
//  ViewController.swift
//  Example
//
//  Created by Riley Testut on 1/23/18.
//  Copyright © 2018 Riley Testut. All rights reserved.
//

import UIKit
import CoreData
@_implementationOnly import os.log

import Harmony

import Roxas

class ViewController: UITableViewController
{
	private var persistentContainer: NSPersistentContainer!

	private var changeToken: Data?

	private var syncCoordinators: [SyncCoordinator] = SyncCoordinator]()
	private var services: [Service] = [Service]()

	private lazy var dataSource = self.makeDataSource()

	override func viewDidLoad() {
		super.viewDidLoad()

		let model = NSManagedObjectModel.mergedModel(from: nil)!
		let harmonyModel = NSManagedObjectModel.harmonyModel(byMergingWith: [model])!

		self.persistentContainer = RSTPersistentContainer(name: "Harmony Example", managedObjectModel: harmonyModel)
		self.persistentContainer.loadPersistentStores { (description, error) in
			os_log("Loaded with error:", error as Any)

			self.tableView.dataSource = self.dataSource
		}

		startSyncCoordinators()

		NotificationCenter.default.addObserver(self, selector: #selector(ViewController.syncDidFinish(_:)), name: SyncCoordinator.didFinishSyncingNotification, object: self.syncCoordinator)

	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	// MARK: Public
	public func add(service: Service) {
		guard !services.contains(service) else {
			return
		}

		let syncCoordinator = SyncCoordinator(service: service, persistentContainer: self.persistentContainer)
		services.append(service)
	}

	// MARK: Private
	private func startSyncCoordinators() {
		syncCoordinators.forEach { syncCoordinator in
			syncCoordinator.start { (result) in
				do {
					_ = try result.value()
					os.log("Started Sync Coordinator")
				} catch {
					os.log(.error, "Failed to start Sync Coordinator. \(error.localizedDescription)")
				}
			}
		}
	}

}

private extension ViewController {
	func makeDataSource() -> RSTFetchedResultsTableViewDataSource<Homework> {
		let fetchRequest = Homework.fetchRequest() as NSFetchRequest<Homework>
		fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Homework.identifier, ascending: true)]

		let dataSource = RSTFetchedResultsTableViewDataSource(fetchRequest: fetchRequest, managedObjectContext: self.persistentContainer.viewContext)
		dataSource.proxy = self
		dataSource.cellConfigurationHandler = { (cell, homework, indexPath) in
			cell.textLabel?.text = homework.name
			cell.detailTextLabel?.numberOfLines = 3
			cell.detailTextLabel?.text = "ID: \(homework.identifier ?? "nil")\nCourse Name: \(homework.course?.name ?? "nil")\nCourse ID: \(homework.course?.name ?? "nil")"
		}

		return dataSource
	}
}

private extension ViewController {
	@IBAction func authenticate(_ sender: UIBarButtonItem) {
		services.forEach { service in
//#if canImport(Harmony_Drive)
//		DriveService.shared.authenticate(withPresentingViewController: self) { (result) in
//			switch result
//			{
//			case .success: os_log("Authentication successful")
//			case .failure(let error): os_log(error.localizedDescription)
//			}
//		}
//#endif

		}
	}

	@IBAction func addHomework(_ sender: UIBarButtonItem) {
		self.persistentContainer.performBackgroundTask { (context) in
			let course = Course(context: context)
			course.name = "CSCI-170"
			course.identifier = "CSCI-170"

			let homework = Homework(context: context)
			homework.name = UUID().uuidString
			homework.identifier = UUID().uuidString
			homework.dueDate = Date()
			homework.course = course

			let fileURL = Bundle.main.url(forResource: "Project1", withExtension: "pdf")!
			try! FileManager.default.copyItem(at: fileURL, to: homework.fileURL!)

			try! context.save()
		}
	}

	@IBAction func sync(_ sender: UIBarButtonItem) {
		self.syncCoordinator.sync()
	}

	@objc func syncDidFinish(_ notification: Notification) {
		guard let result = notification.userInfo?[SyncCoordinator.syncResultKey] as? Result<[Result<Void>]> else { return }

		do {
			_ = try result.value()

			os_log("Sync Succeeded", type: .info)
		}
		catch
		{
			os_log("Sync Failed: %@", type:.error, error)
		}
	}
}

extension ViewController
{
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		let homework = self.dataSource.item(at: indexPath)

		self.persistentContainer.performBackgroundTask { (context) in
			let homework = context.object(with: homework.objectID) as! Homework
			homework.name = UUID().uuidString

			try! context.save()
		}
	}

	override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath)
	{
		guard editingStyle == .delete else { return }

		let homework = self.dataSource.item(at: indexPath)

		self.persistentContainer.performBackgroundTask { (context) in
			let homework = context.object(with: homework.objectID) as! Homework
			context.delete(homework)

			try! context.save()
		}
	}
}
