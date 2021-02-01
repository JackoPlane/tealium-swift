//
//  DiskErrors.swift
//  TealiumSwift
//
//  Copyright © 2019 Tealium. All rights reserved.
//

import Foundation

public struct DiskError: Error {
    enum ErrorKind {
        case noFileFound
        case serialization
        case deserialization
        case invalidFileName
        case couldNotAccessTemporaryDirectory
        case couldNotAccessUserDomainMask
        case couldNotAccessSharedContainer
    }

    let kind: ErrorKind
    let errorInfo: [String: Any]
}
