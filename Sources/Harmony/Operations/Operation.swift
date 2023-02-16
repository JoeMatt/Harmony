//
//  Operation.swift
//  Harmony
//
//  Created by Riley Testut on 1/16/18.
//  Copyright © 2018 Riley Testut. All rights reserved.
//

import CoreData
import Foundation

import Roxas

class Operation<ResultType, ErrorType: Swift.Error>: RSTOperation, ProgressReporting {
    let coordinator: SyncCoordinator

    let progress = Progress.discreteProgress(totalUnitCount: 1)

    let operationQueue: OperationQueue

    public typealias OperationResult = Result<ResultType, ErrorType>
    var result: OperationResult?
    var resultHandler: ((OperationResult) -> Void)?

    var service: any Service {
        self.coordinator.service
    }

    var recordController: RecordController {
        coordinator.recordController
    }

    init(coordinator: SyncCoordinator) {
        self.coordinator = coordinator

        operationQueue = OperationQueue()
        operationQueue.name = "com.rileytestut.Harmony.\(type(of: self)).operationQueue"
        operationQueue.qualityOfService = .utility

        super.init()

        progress.cancellationHandler = { [weak self] in
            self?.cancel()
        }
    }

    override public func cancel() {
        super.cancel()

        if !progress.isCancelled {
            progress.cancel()
        }

        operationQueue.cancelAllOperations()
    }

    override public func finish() {
        guard !isFinished
        else {
            return
        }

        super.finish()

        if !progress.isFinished {
            progress.completedUnitCount = progress.totalUnitCount
        }

        let result: Result<ResultType, ErrorType>?

        if isCancelled {
            let cancelledResult = Result<ResultType, Swift.Error>.failure(GeneralError.cancelled)

            if let cancelledResult = cancelledResult as? Result<ResultType, ErrorType> {
                result = cancelledResult
            } else {
                result = self.result
            }
        } else {
            result = self.result
        }

        if let resultHandler = resultHandler, let result = result {
            resultHandler(result)
        } else {
            assertionFailure("There should always be a result handler and a result.")
        }
    }
}
