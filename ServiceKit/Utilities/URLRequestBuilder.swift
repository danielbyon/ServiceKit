//
//  URLRequestBuilder.swift
//  ServiceKit
//
//  Created by Daniel Byon on 12/27/17.
//  Copyright © 2017 Daniel Byon. All rights reserved.
//

import Foundation

public enum HTTPMethod: String {
    case GET
    case POST
    case PUT
    case DELETE
    case HEAD
    case OPTIONS
    case CONNECT
}

public typealias URLRequestBuilderCompletion = (Result<URLRequest>) -> Void

public struct URLRequestBuilder {

    public static func makeRequest(withEndpoint endpoint: Endpoint,
                                   baseURL: URL,
                                   method: HTTPMethod = .GET,
                                   queryItems: [String: String]? = nil,
                                   bodyParams: [String: String]? = nil,
                                   headerFields: [String: String]? = nil,
                                   transformers: [URLRequestTransforming]? = nil,
                                   completion: @escaping URLRequestBuilderCompletion) {
        makeRequest(withPath: endpoint.path, baseURL: baseURL, method: method, queryItems: queryItems, bodyParams: bodyParams, headerFields: headerFields, transformers: transformers, completion: completion)
    }

    public static func makeRequest(withPath path: String,
                                   baseURL: URL,
                                   method: HTTPMethod = .GET,
                                   queryItems: [String: String]? = nil,
                                   bodyParams: [String: String]? = nil,
                                   headerFields: [String: String]? = nil,
                                   transformers: [URLRequestTransforming]? = nil,
                                   completion: @escaping URLRequestBuilderCompletion) {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            completion(.failure(RequestQueueError.failedToCreateRequest))
            return
        }
        makeRequest(withURL: url, method: method, queryItems: queryItems, bodyParams: bodyParams, headerFields: headerFields, transformers: transformers, completion: completion)
    }

    public static func makeRequest(withFullURLString urlString: String,
                                   method: HTTPMethod = .GET,
                                   queryItems: [String: String]? = nil,
                                   bodyParams: [String: String]? = nil,
                                   headerFields: [String: String]? = nil,
                                   transformers: [URLRequestTransforming]? = nil,
                                   completion: @escaping URLRequestBuilderCompletion) {
        guard let url = URL(string: urlString) else {
            completion(.failure(RequestQueueError.failedToCreateRequest))
            return
        }
        makeRequest(withURL: url, method: method, queryItems: queryItems, bodyParams: bodyParams, headerFields: headerFields, transformers: transformers, completion: completion)
    }

    public static func makeRequest(withURL url: URL,
                                   method: HTTPMethod = .GET,
                                   queryItems: [String: String]? = nil,
                                   bodyParams: [String: String]? = nil,
                                   headerFields: [String: String]? = nil,
                                   transformers: [URLRequestTransforming]? = nil,
                                   completion: @escaping URLRequestBuilderCompletion) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            completion(.failure(RequestQueueError.failedToCreateRequest))
            return
        }
        makeRequest(withComponents: components, method: method, queryItems: queryItems, bodyParams: bodyParams, headerFields: headerFields, transformers: transformers, completion: completion)
    }

    public static func makeRequest(withComponents components: URLComponents,
                                   method: HTTPMethod = .GET,
                                   queryItems: [String: String]? = nil,
                                   bodyParams: [String: String]? = nil,
                                   headerFields: [String: String]? = nil,
                                   transformers: [URLRequestTransforming]? = nil,
                                   completion: @escaping URLRequestBuilderCompletion) {
        var components = components

        var allQueryItems = components.queryItems ?? []
        if let queryItems = queryItems?.map({ URLQueryItem(name: $0.key, value: $0.value) }) {
            allQueryItems += queryItems
        }
        components.queryItems = allQueryItems

        guard let url = components.url else {
            completion(.failure(RequestQueueError.failedToCreateRequest))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue

        if let bodyParams = bodyParams {
            do {
                let data = try JSONSerialization.data(withJSONObject: bodyParams)
                request.httpBody = data
            } catch {
                completion(.failure(error))
                return
            }
        }

        headerFields?.forEach {
            request.addValue($0.value, forHTTPHeaderField: $0.key)
        }

        if let transformers = transformers {
            applyTransformers(transformers, to: request, completion: completion)
        } else {
            completion(.success(request))
        }
    }

    private static func applyTransformers(_ transformers: [URLRequestTransforming], to request: URLRequest, completion: @escaping URLRequestBuilderCompletion) {
        var returnRequest = request
        var returnError: Error? = nil

        let group = DispatchGroup()
        for transformer in transformers {
            group.enter()
            transformer.transformRequest(returnRequest) { result in
                switch result {
                case .success(let transformed):
                    returnRequest = transformed
                case .failure(let error):
                    returnError = error
                }
                group.leave()
            }
            group.wait()
            if let _ = returnError {
                break
            }
        }

        if let returnError = returnError {
            completion(.failure(returnError))
        } else {
            completion(.success(returnRequest))
        }
    }

    private init() { }

}
