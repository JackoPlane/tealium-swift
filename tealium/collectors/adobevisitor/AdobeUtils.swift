//
//  AdobeUtils.swift
//  TealiumAdobeVisitorAPI
//
//  Created by Craig Rouse on 13/01/2021.
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


struct AdobeHelpers {

}

public extension HTTPURLResponse {
    func adobeSessionId() -> String? {
        let headers = self.allHeaderFields
        if let sessionIdHeader = headers["Location"] as? String {
            let parts = sessionIdHeader.split(separator: "/")
            if let substring = parts.last {
                return String(substring)
            }
        }

        return nil
    }
}

public func urlPOSTRequestWithJSONString(_ jsonString: String, dispatchURL: String) -> URLRequest? {
    if let dispatchURL = URL(string: dispatchURL) {
        var request = URLRequest(url: dispatchURL)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = jsonString.data(using: .utf8)
        return request
    }
    return nil
}

public func urlPOSTRequestWithJSONString(_ jsonString: String, dispatchURL: URL?) -> URLRequest? {
    if let dispatchURL = dispatchURL {
        var request = URLRequest(url: dispatchURL)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = jsonString.data(using: .utf8)
        return request
    }
    return nil
}
