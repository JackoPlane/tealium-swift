//
//  AdobeUtils.swift
//  TealiumAdobeVisitorAPI
//
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation

public typealias NetworkResult = Result<(URLResponse, Data), Error>

extension URLSession: NetworkSession {
    public func loadData(from request: URLRequest,
                         completionHandler: @escaping (NetworkResult) -> Void) {

        let task = dataTask(with: request) { data, urlResponse, error in
            if let error = error {
                completionHandler(.failure(error))
            } else {
                guard let urlResponse = urlResponse,
                      let data = data else {
                    let error = NSError(domain: "error", code: 0, userInfo: nil)
                    completionHandler(.failure(error))
                    return
                }
                completionHandler(.success((urlResponse, data)))
            }
        }

        task.resume()
    }

    public func invalidateAndClose() {
        self.finishTasksAndInvalidate()
    }
    
    public func reset() {
        self.reset(completionHandler: {})
    }
}


public protocol NetworkSession {

    func loadData(from request: URLRequest,
                  completionHandler: @escaping (NetworkResult) -> Void)

    func invalidateAndClose()
    
    func reset()
}
