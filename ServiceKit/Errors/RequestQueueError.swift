//
//  RequestQueueError.swift
//  ServiceKit
//
//  Created by Daniel Byon on 1/12/18.
//  Copyright © 2018 Daniel Byon. All rights reserved.
//

import Foundation

public enum RequestQueueError: Error {
    case operationCancelled
    case didNotReceiveData
    case failedToCreateRequest
    case invalidStatusCode(statusCode: Int)
    case jsonDeserializationFailed
    case identifierMismatch(identifier: String, expectedType: Any, actualType: Any)
}
