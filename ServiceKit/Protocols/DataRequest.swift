//
//  DataRequest.swift
//  ServiceKit
//
//  Created by Daniel Byon on 12/27/17.
//  Copyright © 2017 Daniel Byon. All rights reserved.
//

import Foundation

public protocol DataRequest: NetworkRequest {

    func processData(_ data: Data) throws -> ResultType

}
