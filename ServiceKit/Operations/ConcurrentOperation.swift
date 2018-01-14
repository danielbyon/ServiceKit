//
//  ConcurrentOperation.swift
//  ServiceKit
//
//  Created by Daniel Byon on 1/12/18.
//  Copyright © 2018 Daniel Byon. All rights reserved.
//

import Foundation

public class ConcurrentOperation: Operation {

    public enum State: String {
        case ready = "isReady"
        case executing = "isExecuting"
        case finished = "isFinished"
    }

    public internal(set) var state: State = .ready {
        willSet {
            willChangeValue(forKey: newValue.rawValue)
            willChangeValue(forKey: state.rawValue)
        }
        didSet {
            didChangeValue(forKey: oldValue.rawValue)
            didChangeValue(forKey: state.rawValue)
        }
    }

    public override var isReady: Bool {
        return super.isReady && state == .ready
    }

    public override var isExecuting: Bool {
        return state == .executing
    }

    public override var isFinished: Bool {
        return state == .finished
    }

    public override var isAsynchronous: Bool {
        return true
    }

    public override func start() {
        guard !isCancelled else {
            state = .finished
            return
        }

        state = .executing
        main()
    }

    public override func cancel() {
        super.cancel()
        state = .finished
    }

}
