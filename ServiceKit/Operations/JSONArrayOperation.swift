//
//  JSONArrayOperation.swift
//  ServiceKit
//
//  Created by Daniel Byon on 1/27/18.
//  Copyright © 2018 Daniel Byon. All rights reserved.
//

import Foundation

public class JSONArrayOperation<T: ParsableArrayRequest>: NetworkOperation<T> {

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

                    if let error = error {
                        self.result = .failure(error)
                        return
                    }

                    if let response = response as? HTTPURLResponse {
                        guard self.request.validHTTPStatusCodes.contains(response.statusCode) else {
                            self.result = .failure(RequestQueueError.invalidStatusCode(statusCode: response.statusCode))
                            return
                        }
                    }

                    do {
                        guard let data = data else {
                            self.result = .failure(RequestQueueError.didNotReceiveData)
                            return
                        }

                        guard let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? NSArray else {
                            throw RequestQueueError.jsonDeserializationFailed
                        }

                        guard !self.isCancelled else {
                            return
                        }

                        let parsed = try self.request.parseJSONArray(json)
                        self.result = .success(parsed)
                    } catch {
                        self.result = .failure(error)
                    }
                }
                self.dataTask?.resume()
            case .failure(let error):
                self.result = .failure(error)
            }
        }
    }

    public override func cancel() {
        super.cancel()
        dataTask?.cancel()
        dataTask = nil
    }

}
