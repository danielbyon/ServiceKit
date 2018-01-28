//
//  ParsableRequest.swift
//  ServiceKit
//
//  Created by Daniel Byon on 12/27/17.
//  Copyright © 2017 Daniel Byon. All rights reserved.
//

import Foundation
import ParseKit

public protocol ParsableRequest: NetworkRequest {

    func parseJSON(_ json: NSDictionary) throws -> ResultType

}
