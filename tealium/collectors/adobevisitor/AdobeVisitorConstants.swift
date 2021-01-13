//
//  AdobeVisitorConstants.swift
//  TealiumAdobeVisitorAPI
//
//  Created by Craig Rouse on 13/01/2021.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation

enum AdobeVisitorKeys: String, CaseIterable {
    case experienceCloudId = "d_mid"
    case orgId = "d_orgid"
    case dataProviderId = "d_cid"
    case region = "dcs_region"
    case encryptedMetaData = "d_blob"
    case version = "d_ver"
    case idSyncTTL = "id_sync_ttl"

    static func isValidKey(_ key: String) -> Bool {
        return AdobeVisitorKeys.allCases.map { caseItem in
            return caseItem.rawValue
        }.contains(key)
    }
}

public enum AdobeVisitorAuthState: Int, CustomStringConvertible {
    public var description: String {
        return "\(self.rawValue)"
    }

    case unknown = 0
    case authenticated = 1
    case loggedOut = 2

}


enum AdobeIntConstants: Int {
    case apiVersion = 2
}

enum AdobeStringConstants: String {
    // %01 is a non-printing control character
    case dataProviderIdSeparator = "%01"
    case defaultAdobeURL = "https://dpm.demdex.net/id"
}

public enum AdobeVisitorError: Error {
    case missingExperienceCloudID
    case missingOrgID
    case invalidJSON
}
