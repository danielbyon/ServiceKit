//
//  NetworkOperation.swift
//  ServiceKit
//
//  Created by Daniel Byon on 1/12/18.
//  Copyright © 2018 Daniel Byon. All rights reserved.
//

import Foundation

public class NetworkOperation<T: Request>: RequestQueueOperation<T> {

    public let session: URLSession

    public init(request: T, session: URLSession) {
        self.session = session
        super.init(request: request)
    }

}
