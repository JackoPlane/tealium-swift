//
//  Encodable+Tealium.swift
//  TealiumCore
//
//  Created by Christina S on 1/8/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation

public extension Encodable {
    var dictionary: [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)).flatMap { $0 as? [String: Any] }
    }
}
