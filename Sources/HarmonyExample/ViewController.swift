//
//  ViewController.swift
//  HarmonyExample
//
//  Created by Riley Testut on 1/23/18.
//  Copyright © 2018 Riley Testut. All rights reserved.
//

#if canImport(UIKit)
import CoreData
@_exported import HarmonyTestData
import os.log

import UIKit

@_exported import Harmony
@_exported import RoxasUIKit
@_exported import Roxas

open class ViewController: UITableViewController {
    private var persistentContainer: NSPersistentContainer!

    private var changeToken: Data?

    private var syncCoordinators: [SyncCoordinator] = .init() {
        didSet {
            addObservers()
        }
    }

    private var services: [any Service] { syncCoordinators.map { $0.service } }

    private lazy var dataSource = self.makeDataSource()

    override public func viewDidLoad() {
        super.viewDidLoad()

        let model = NSManagedObjectModel.mergedModel(from: nil)!
        let harmonyModel = NSManagedObjectModel.harmonyModel(byMergingWith: [model])!

        persistentContainer = RSTPersistentContainer(name: "Harmony Example", managedObjectModel: harmonyModel)
        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                os_log("Loaded with error: %@", type: .error, error.localizedDescription)
            }

            self.tableView.dataSource = self.dataSource
        }

        startSyncCoordinators()
        addObservers()
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: Public

    public func add(service: any Service) {
        guard !services.contains(where: { $0.identifier == service.identifier })
        else {
            return
        }

        let syncCoordinator = SyncCoordinator(service: service,
                                              persistentContainer: persistentContainer)
        syncCoordinators.append(syncCoordinator)
    }

    // MARK: Private

    private func startSyncCoordinators() {
        syncCoordinators.forEach { syncCoordinator in
            syncCoordinator.start { result in
                do {
                    _ = try result.get()
                    os_log("Started Sync Coordinator")
                } catch {
                    os_log("Failed to start Sync Coordinator %@", type: .error, error.localizedDescription)
                }
            }
        }
    }

    private func addObservers() {
        // Clear any existing observers
        removeObservers()
        syncCoordinators.forEach { syncCoordinator in
            // Add new observer
            NotificationCenter.default.addObserver(self, selector: #selector(ViewController.syncDidFinish(_:)), name: SyncCoordinator.didFinishSyncingNotification, object: syncCoordinator)
        }
    }

    private func removeObservers() {
        syncCoordinators.forEach { syncCoordinator in
            NotificationCenter.default.removeObserver(self, name: SyncCoordinator.didFinishSyncingNotification, object: syncCoordinator)
        }
    }
}

private extension ViewController {
    func makeDataSource() -> RSTFetchedResultsTableViewDataSource<Homework> {
        let fetchRequest = Homework.fetchRequest() as NSFetchRequest<Homework>
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Homework.identifier, ascending: true)]

        let dataSource = RSTFetchedResultsTableViewDataSource(fetchRequest: fetchRequest, managedObjectContext: persistentContainer.viewContext)
        dataSource.proxy = self
        dataSource.cellConfigurationHandler = { cell, homework, _ in
            cell.textLabel?.text = homework.name
            cell.detailTextLabel?.numberOfLines = 3
            cell.detailTextLabel?.text = "ID: \(homework.identifier ?? "nil")\nCourse Name: \(homework.course?.name ?? "nil")\nCourse ID: \(homework.course?.name ?? "nil")"
        }

        return dataSource
    }
}

private extension ViewController {
    @IBAction func authenticate(_: UIBarButtonItem) {
        services.forEach { _ in
            // TODO: Add protocol/method to services to call here
            // #if canImport(Harmony_Drive)
            //		DriveService.shared.authenticate(withPresentingViewController: self) { (result) in
            //			switch result
            //			{
            //			case .success: os_log("Authentication successful")
            //			case .failure(let error): os_log(error.localizedDescription)
            //			}
            //		}
            // #endif
        }
    }

    @IBAction func addHomework(_: UIBarButtonItem) {
        persistentContainer.performBackgroundTask { context in
            let course = Course(context: context)
            course.name = "CSCI-170"
            course.identifier = "CSCI-170"

            let homework = Homework(context: context)
            homework.name = UUID().uuidString
            homework.identifier = UUID().uuidString
            homework.dueDate = Date()
            homework.course = course

            let fileURL = HarmonyTestData.project1_pdf
            try! FileManager.default.copyItem(at: fileURL, to: homework.fileURL!)

            try! context.save()
        }
    }

    @IBAction func sync(_: UIBarButtonItem) {
        syncCoordinators.forEach { syncCoordinator in
            syncCoordinator.sync()
        }
    }

    @objc func syncDidFinish(_ notification: Notification) {
        typealias ResultType = Result<[Record<NSManagedObject>: Result<Void, RecordError>], SyncError>
        guard let result = notification.userInfo?[SyncCoordinator.syncResultKey] as? ResultType else { return }

        do {
            _ = try result.get()
            os_log("Sync Succeeded", type: .info)
        } catch {
            os_log("Sync Failed: %@", type: .error, error.localizedDescription)
        }
    }
}

public extension ViewController {
    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let homework = dataSource.item(at: indexPath)

        persistentContainer.performBackgroundTask { context in
            let homework = context.object(with: homework.objectID) as! Homework
            homework.name = UUID().uuidString

            try! context.save()
        }
    }

    override func tableView(_: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }

        let homework = dataSource.item(at: indexPath)

        persistentContainer.performBackgroundTask { context in
            let homework = context.object(with: homework.objectID) as! Homework
            context.delete(homework)

            try! context.save()
        }
    }
}
#endif
