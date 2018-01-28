//
//  ParsableArrayRequest.swift
//  ServiceKit
//
//  Created by Daniel Byon on 1/27/18.
//  Copyright © 2018 Daniel Byon. All rights reserved.
//

import Foundation

public protocol ParsableArrayRequest: NetworkRequest {

    func parseJSONArray(_ json: NSArray) throws -> ResultType

}
