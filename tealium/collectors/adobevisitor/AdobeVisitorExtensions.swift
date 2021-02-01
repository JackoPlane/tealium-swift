//
//  AdobeVisitorExtensions.swift
//  TealiumAdobeVisitorAPI
//
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation
import TealiumCore

public extension Collectors {
    static let AdobeVisitorAPI = TealiumAdobeVisitorModule.self
}

public struct TealiumAdobeVisitorConstants {
    public static let adobeOrgId = "adobe_org_id"
    public static let adobeCustomVisitorId = "adobe_custom_visitor_id"
    public static let adobeExistingECID = "adobe_existing_ecid"
    public static let adobeDataProviderId = "adobe_data_provider_id"
    public static let adobeAuthState = "adobe_auth_state"
    public static let adobeOrgIdSuffix = "@AdobeOrg"
    public static let adobeEcid = "adobe_ecid"
    public static let moduleName = "adobevisitor"
    public static let retries = "retries"
}


public extension Tealium {
    
    /// - Returns: `TealiumTagManagementProtocol` (`WKWebView` for iOS11+)
    var adobeVisitorAPI: TealiumAdobeVisitorModule? {
        let module = zz_internal_modulesManager?.modules.first {
            $0 is TealiumAdobeVisitorModule
        }

        return (module as? TealiumAdobeVisitorModule)
    }

}


public extension TealiumConfig {
    
    var adobeOrgId: String? {
        get {
            options[TealiumAdobeVisitorConstants.adobeOrgId] as? String
        }
        
        set {
            if var orgId = newValue {
                if !orgId.hasSuffix(TealiumAdobeVisitorConstants.adobeOrgIdSuffix) {
                   orgId = "\(orgId)\(TealiumAdobeVisitorConstants.adobeOrgIdSuffix)"
                }
                options[TealiumAdobeVisitorConstants.adobeOrgId] = orgId
            }
        }
    }
    
    var adobeCustomVisitorId: String? {
        get {
            options[TealiumAdobeVisitorConstants.adobeCustomVisitorId] as? String
        }
        
        set {
            options[TealiumAdobeVisitorConstants.adobeCustomVisitorId] = newValue
        }
    }
    
    var adobeExistingECID: String? {
        get {
            options[TealiumAdobeVisitorConstants.adobeExistingECID] as? String
        }
        
        set {
            options[TealiumAdobeVisitorConstants.adobeExistingECID] = newValue
        }
    }
    
    var adobeRetries: Int {
        get {
            options[TealiumAdobeVisitorConstants.retries] as? Int ?? 5
        }
        
        set {
            options[TealiumAdobeVisitorConstants.retries] = newValue
        }
    }
    
    var adobeDataProviderId: String? {
        get {
            options[TealiumAdobeVisitorConstants.adobeDataProviderId] as? String
        }
        
        set {
            options[TealiumAdobeVisitorConstants.adobeDataProviderId] = newValue
        }
    }
    
    var adobeAuthState: AdobeVisitorAuthState? {
        get {
            options[TealiumAdobeVisitorConstants.adobeAuthState] as? AdobeVisitorAuthState
        }
        
        set {
            options[TealiumAdobeVisitorConstants.adobeAuthState] = newValue
        }
    }
    
}
