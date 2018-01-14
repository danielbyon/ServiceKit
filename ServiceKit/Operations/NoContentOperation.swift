//
//  NoContentOperation.swift
//  ServiceKit
//
//  Created by Daniel Byon on 1/12/18.
//  Copyright © 2018 Daniel Byon. All rights reserved.
//

import Foundation

public class NoContentOperation<T: NetworkRequest>: NetworkOperation<T> where T.Result == Void {

    private var dataTask: URLSessionDataTask?

    public override func main() {
        request.makeURLRequest { [unowned self] result in
            switch result {
            case .success(let urlRequest):
                self.dataTask = self.session.dataTask(with: urlRequest) { data, response, error in
                    defer {
                        self.dataTask = nil
                    }

                    guard !self.isCancelled else {
                        return
                    }

                    self.result = .success(())
                }
            case .failure(let error):
                self.result = .failure(error)
            }
        }
    }

}
