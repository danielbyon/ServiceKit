//
//  RequestQueueOperation.swift
//  ServiceKit
//
//  Created by Daniel Byon on 1/12/18.
//  Copyright © 2018 Daniel Byon. All rights reserved.
//

import Foundation

public class RequestQueueOperation<T: Request>: ConcurrentOperation {

    public internal(set) var result: Result<T.ResultType>? {
        didSet {
            state = .finished
        }
    }

    public let request: T

    public init(request: T) {
        self.request = request
    }

}
