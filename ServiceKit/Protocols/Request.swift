//
//  Request.swift
//  ServiceKit
//
//  Created by Daniel Byon on 12/27/17.
//  Copyright © 2017 Daniel Byon. All rights reserved.
//

import Foundation

public protocol Request: Equatable {

    associatedtype ResultType

    var identifier: String { get }

    var shouldCoalesceMultipleCompletions: Bool { get }

}

extension Request {

    public var shouldCoalesceMultipleCompletions: Bool {
        return true
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.identifier == rhs.identifier
    }

}
