//
//  URLRequestTransforming.swift
//  ServiceKit
//
//  Created by Daniel Byon on 12/27/17.
//  Copyright © 2017 Daniel Byon. All rights reserved.
//

import Foundation

public protocol URLRequestTransforming {

    func transformRequest(_ request: URLRequest, completion: @escaping URLRequestBuilderCompletion)

}
