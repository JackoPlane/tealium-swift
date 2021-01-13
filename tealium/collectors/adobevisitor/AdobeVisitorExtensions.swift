//
//  AdobeVisitorExtensions.swift
//  TealiumAdobeVisitorAPI
//
//  Created by Craig Rouse on 13/01/2021.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation
import TealiumCore

public extension Collectors {
    static let AdobeVisitorAPI = TealiumAdobeVisitorAPI.self
}

public struct TealiumAdobeVisitorConstants {
    public static let adobeOrgId = "adobe_org_id"
    public static let adobeCustomVisitorId = "adobe_custom_visitor_id"
    public static let adobeDataProviderId = "adobe_data_provider_id"
    public static let adobeAuthState = "adobe_auth_state"
    public static let adobeOrgIdSuffix = "@AdobeOrg"
    public static let adobeEcid = "adobe_ecid"
    public static let moduleName = "adobevisitor"
}


public extension Tealium {
    
    /// - Returns: `TealiumTagManagementProtocol` (`WKWebView` for iOS11+)
    var adobeVisitor: TealiumAdobeVisitorAPI? {
        let module = zz_internal_modulesManager?.modules.first {
            $0 is TealiumAdobeVisitorAPI
        }

        return (module as? TealiumAdobeVisitorAPI)
    }
//
//    /// Resets the Adobe Experience Cloud ID. A new ID will be requested on any subsequent track calls
//    func adobe_resetECID() {
//
//        if let module = modulesManager.getModule(forName: TealiumAdobeVisitorConstants.moduleName) as? AdobeVisitorServiceModule {
//            module.resetECID()
//        }
//    }
//
//    func adobe_linkECIDToKnownIdentifier(_ id: String) {
//        if let module = modulesManager.getModule(forName: TealiumAdobeVisitorConstants.moduleName) as? AdobeVisitorServiceModule {
//            module.linkECIDToKnownIdentifier(knownId: id)
//        }
//    }
//
//    func adobe_refreshECID() {
//        if let module = modulesManager.getModule(forName: TealiumAdobeVisitorConstants.moduleName) as? AdobeVisitorServiceModule {
////            module.refreshECID()
//        }
//    }
//
//    func adobe_getNewECID() {
//        if let module = modulesManager.getModule(forName: TealiumAdobeVisitorConstants.moduleName) as? AdobeVisitorServiceModule {
//        //            module.refreshECID()
//        }
//    }
//
//    func adobe_getNewECIDAndLinkToIdentifier() {
//        if let module = modulesManager.getModule(forName: TealiumAdobeVisitorConstants.moduleName) as? AdobeVisitorServiceModule {
//        //            module.refreshECID()
//        }
//    }

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
