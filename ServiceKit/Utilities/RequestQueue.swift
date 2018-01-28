//
//  RequestQueue.swift
//  ServiceKit
//
//  Created by Daniel Byon on 1/13/18.
//  Copyright © 2018 Daniel Byon. All rights reserved.
//

import Foundation
import ReactiveKit

public protocol RequestQueueProtocol {

    var currentlyExecuting: Property<Bool> { get }
    
    @discardableResult
    func performRequest<T: NetworkRequest>(_ request: T, completion: ((Result<T.ResultType>) -> Void)?) -> Operation where T.ResultType == Void

    @discardableResult
    func performRequest<T: DataRequest>(_ request: T, completion: ((Result<T.ResultType>) -> Void)?) -> Operation

    @discardableResult
    func performRequest<T: ParsableRequest>(_ request: T, completion: ((Result<T.ResultType>) -> Void)?) -> Operation

    @discardableResult
    func performRequest<T: ParsableArrayRequest>(_ request: T, completion: ((Result<T.ResultType>) -> Void)?) -> Operation

    func requestCurrentlyExecuting<T: Request>(_ request: T) -> Operation?

}

public class RequestQueue: RequestQueueProtocol {

    // MARK: Public Variables

    public var currentlyExecuting = Property(false)

    public var isSuspended: Bool {
        get { return queue.isSuspended }
        set { queue.isSuspended = newValue }
    }

    // MARK: Private Variables

    private let queue: OperationQueue
    private let session: URLSession
    private let callbackManipulationQueue: DispatchQueue
    private var callbacks: [String: CallbackWrapperBlock] = [:]

    private typealias CallbackWrapperBlock = (TypeErasedResult) -> Void
    private enum TypeErasedResult {
        case success(Any)
        case failure(Error)
    }

    // MARK: Init

    public init(queue: OperationQueue = OperationQueue(), session: URLSession = .shared) {
        self.queue = queue
        self.session = session
        callbackManipulationQueue = DispatchQueue(label: "com.danielbyon.ServiceKit.RequestQueueCallbackManipulation")
    }

    // MARK: Public Methods

    @discardableResult
    public func performRequest<T: NetworkRequest>(_ request: T, completion: ((Result<T.ResultType>) -> Void)?) -> Operation where T.ResultType == Void {
        var returnOperation: RequestQueueOperation<T>?
        callbackManipulationQueue.sync { [unowned self] in
            if request.shouldCoalesceMultipleCompletions,
                let existingOperation = self.checkForExistingOperation(request, completion: completion) {
                returnOperation = existingOperation
            }

            let operation = NoContentOperation(request: request, session: session)
            self.addOperation(operation, completion: completion)
            returnOperation = operation
        }
        assert(returnOperation != nil)
        return returnOperation!
    }

    @discardableResult
    public func performRequest<T: DataRequest>(_ request: T, completion: ((Result<T.ResultType>) -> Void)?) -> Operation {
        var returnOperation: RequestQueueOperation<T>?
        callbackManipulationQueue.sync { [unowned self] in
            if request.shouldCoalesceMultipleCompletions,
                let existingOperation = self.checkForExistingOperation(request, completion: completion) {
                returnOperation = existingOperation
            }

            let operation = DataOperation(request: request, session: session)
            self.addOperation(operation, completion: completion)
            returnOperation = operation
        }
        assert(returnOperation != nil)
        return returnOperation!
    }

    @discardableResult
    public func performRequest<T: ParsableRequest>(_ request: T, completion: ((Result<T.ResultType>) -> Void)?) -> Operation {
        var returnOperation: RequestQueueOperation<T>?
        callbackManipulationQueue.sync { [unowned self] in
            if request.shouldCoalesceMultipleCompletions,
                let existingOperation = self.checkForExistingOperation(request, completion: completion) {
                returnOperation = existingOperation
            }

            let operation = JSONOperation(request: request, session: session)
            self.addOperation(operation, completion: completion)
            returnOperation = operation
        }
        assert(returnOperation != nil)
        return returnOperation!
    }

    @discardableResult
    public func performRequest<T: ParsableArrayRequest>(_ request: T, completion: ((Result<T.ResultType>) -> Void)?) -> Operation {
        var returnOperation: RequestQueueOperation<T>?
        callbackManipulationQueue.sync { [unowned self] in
            if request.shouldCoalesceMultipleCompletions,
                let existingOperation = self.checkForExistingOperation(request, completion: completion) {
                returnOperation = existingOperation
            }

            let operation = JSONArrayOperation(request: request, session: session)
            self.addOperation(operation, completion: completion)
            returnOperation = operation
        }
        assert(returnOperation != nil)
        return returnOperation!
    }

    public func requestCurrentlyExecuting<T: Request>(_ request: T) -> Operation? {
        return queue.operations.flatMap { $0 as? RequestQueueOperation<T> }
            .first { ($0.isReady && $0.isExecuting) && $0.request == request }
    }

    // MARK: Private Methods

    private func checkForExistingOperation<T: Request>(_ request: T, completion: ((Result<T.ResultType>) -> Void)?) -> RequestQueueOperation<T>? {
        let callbackIdentifier = request.identifier
        guard let existingOperation = self.requestCurrentlyExecuting(request) as? RequestQueueOperation<T>,
            let wrappedCompletion = self.callbacks[callbackIdentifier] else {
                return nil
        }

        let rewrappedCompletion: CallbackWrapperBlock = { result in
            // Call the existing completion first
            wrappedCompletion(result)

            // Then call the new completion
            switch result {
            case .success(let value as T.ResultType):
                completion?(.success(value))
            case .failure(let error):
                completion?(.failure(error))
            case .success(let value):
                completion?(.failure(RequestQueueError.identifierMismatch(identifier: callbackIdentifier, expectedType: T.ResultType.self, actualType: type(of: value))))
            }
        }
        self.callbacks[callbackIdentifier] = rewrappedCompletion
        return existingOperation
    }

    private func addOperation<T>(_ operation: RequestQueueOperation<T>, completion: ((Result<T.ResultType>) -> Void)?) {
        operation.completionBlock = { [weak self, weak operation] in
            guard let strongSelf = self,
                let operation = operation,
                let result = operation.result else {
                    completion?(.failure(RequestQueueError.operationCancelled))
                    return
            }

            let callbackIdentifier = operation.request.identifier

            var finalCompletion: CallbackWrapperBlock?
            strongSelf.callbackManipulationQueue.sync {
                finalCompletion = strongSelf.callbacks.removeValue(forKey: callbackIdentifier)
            }
            guard let completion = finalCompletion else {
                assertionFailure("Missing callback for identifier \(callbackIdentifier), this shouldn't happen.")
                return
            }
            switch result {
            case .success(let value):
                completion(.success(value))
            case .failure(let error):
                completion(.failure(error))
            }
        }

        let callbackIdentifier = operation.request.identifier
        let wrappedCompletion: CallbackWrapperBlock = { result in
            switch result {
            case .success(let value as T.ResultType):
                completion?(.success(value))
            case .failure(let error):
                completion?(.failure(error))
            case .success(let value):
                completion?(.failure(RequestQueueError.identifierMismatch(identifier: callbackIdentifier, expectedType: T.ResultType.self, actualType: type(of: value))))
            }
        }
        self.callbacks[callbackIdentifier] = wrappedCompletion
        self.queue.addOperation(operation)
    }

}
