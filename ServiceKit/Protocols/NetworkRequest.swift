//
//  NetworkRequest.swift
//  ServiceKit
//
//  Created by Daniel Byon on 12/27/17.
//  Copyright © 2017 Daniel Byon. All rights reserved.
//

import Foundation

public protocol NetworkRequest: Request {

    func makeURLRequest(completion: @escaping URLRequestBuilderCompletion)

    var validHTTPStatusCodes: [Int] { get }

}

public extension NetworkRequest {

    public var validHTTPStatusCodes: [Int] {
        return Array(200..<300)
    }

}
