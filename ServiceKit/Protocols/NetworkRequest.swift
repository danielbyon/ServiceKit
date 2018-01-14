//
//  NetworkRequest.swift
//  ServiceKit
//
//  Created by Daniel Byon on 12/27/17.
//  Copyright © 2017 Daniel Byon. All rights reserved.
//

import Foundation

public protocol NetworkRequest: Request {

    func makeURLRequest(completion: URLRequestBuilderCompletion)

    var validHTTPStatusCodes: [Int] { get }

}

extension NetworkRequest {

    var validHTTPStatusCodes: [Int] {
        return Array(200..<300)
    }

}
