//
//  AdobeVisitorModule.swift
//  tealium-swift
//
//  Created by Craig Rouse on 13/01/2021.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation
import TealiumCore
// TODO: Force unwrapping causes crash if keys are nil. Make sure keys are not nil, or fetch new ECID


public class TealiumAdobeVisitorAPI: Collector, DispatchValidator {
    
    public var id = "TealiumAdobeVisitorAPI"
    
    public var config: TealiumConfig
    
    public var diskStorage: TealiumDiskStorageProtocol?
    
    public var data: [String : Any]?
    
    var ecID: AdobeExperienceCloudID? {
        willSet {
            self.diskStorage?.save(newValue, completion: nil)
        }
    }
    
    var visitorAPI: AdobeVisitorAPI?
    
    
    var orgId: String?
    var dpId: String {
        config.adobeDataProviderId ?? "0"
    }
    var customVisitorId: String? {
        config.adobeCustomVisitorId
    }
    
    var authState: AdobeVisitorAuthState? {
        config.adobeAuthState
    }
    
    var delegate: ModuleDelegate?
    
    public func shouldQueue(request: TealiumRequest) -> (Bool, [String : Any]?) {
        guard orgId != nil else {
            return (false, ["adobe_error":"Org ID Not Set. ECID will be missing from track requests"])
        }
        guard let ecID = ecID?.experienceCloudID else {
            return (true, [TealiumKey.queueReason: AdobeVisitorError.missingExperienceCloudID.localizedDescription])
        }
        return (false, [TealiumAdobeVisitorConstants.adobeEcid: ecID])
    }
    
    public func shouldDrop(request: TealiumRequest) -> Bool {
        false
    }
    
    public func shouldPurge(request: TealiumRequest) -> Bool {
        false
    }
    
    required public init(context: TealiumContext,
                  delegate: ModuleDelegate?,
                  diskStorage: TealiumDiskStorageProtocol?,
                  completion: ((Result<Bool, Error>, [String : Any]?)) -> Void) {
        
        self.config = context.config
        self.delegate = delegate
        guard let orgId = config.adobeOrgId else {
//            completion(.error(["adobe_error":"Org ID Not Set. ECID will be missing from track requests"]))
            completion((.failure(AdobeVisitorError.missingOrgID), ["adobe_error":"Org ID Not Set. ECID will be missing from track requests"]))
            return
        }
        self.diskStorage = diskStorage ?? TealiumDiskStorage(config: config, forModule: "adobevisitor")
        self.orgId = orgId
        visitorAPI = AdobeVisitorAPI(adobeOrgId: orgId, enableCookies: true)
        if let ecID = getECIDFromDisk() {
            self.ecID = ecID
            if let adobeCustomVisitorId = config.adobeCustomVisitorId {
                linkECIDToKnownIdentifier(knownId: adobeCustomVisitorId)
            }
        } else {
            if let adobeCustomVisitorId = config.adobeCustomVisitorId {
                getAndLink(customVisitorId: adobeCustomVisitorId, dpId: dpId, authState: authState)
            } else {
                getECID()
            }
        }
    }
    
    func getECIDFromDisk() -> AdobeExperienceCloudID? {
        guard let visitorAPI = visitorAPI else {
            // TODO: Logging
            return nil
        }
        if let ecID = diskStorage?.retrieve(as: AdobeExperienceCloudID.self) {
            delegate?.requestDequeue(reason: "Adobe Visitor ID Retrieved Successfully")
            if ecID.nextRefresh == nil || Date() >= ecID.nextRefresh! {
                visitorAPI.refreshECID(existingECID: ecID.experienceCloudID!) { result in
                    switch result {
                    case .failure:
                        print("error")
                    case .success(let ecID):
                        self.ecID = ecID
                    }
                }
            }
            return ecID
        }
        return nil
    }
    
    /// Called when a successful response is received with a new ECID
    func saveECID(ecID: AdobeExperienceCloudID) {
        self.ecID = ecID
        delegate?.requestDequeue(reason: "Adobe Visitor ID Retrieved Successfully")
    }
    
    /// Resets the Adobe Experience Cloud ID. A new ID will be requested on any subsequent track calls
    public func resetECID() {
        self.ecID = nil
        self.diskStorage?.delete(completion: nil)
    }
    
    //    # 1 Get Only
    
    func getECID() {
        guard let visitorAPI = visitorAPI else {
            return
        }
        visitorAPI.getNewAdobeECID { result in
            switch result {
            case .success(let ecID):
                self.ecID = ecID
            case .failure:
                break
            }
        }
    }
    
    public func refreshECID() {
        guard let visitorAPI = visitorAPI, let existingECID = ecID?.experienceCloudID else {
            return
        }
        visitorAPI.refreshECID(existingECID: existingECID) { result in
            switch result {
            case .success(let ecID):
                self.ecID = ecID
            case .failure:
                break
            }
        }
    }
    
    func getAndLink(customVisitorId: String,
                    dpId: String,
                    authState: AdobeVisitorAuthState?) {
        guard let visitorAPI = visitorAPI else {
            return
        }
        visitorAPI.getNewECIDAndLink(customVisitorId: customVisitorId, dataProviderId: dpId, authState: authState) { result in
            switch result {
            case .success(let ecID):
                self.ecID = ecID
            case .failure:
                break
            }
        }
    }
    
    //    #2
    
    public func linkECIDToKnownIdentifier (knownId: String) {
        guard let visitorAPI = visitorAPI else {
            return
        }
        guard let experienceCloudId = self.ecID?.experienceCloudID else {
            visitorAPI.getNewECIDAndLink(customVisitorId: knownId, dataProviderId: dpId, authState: authState) { result in
                switch result {
                case .success(let ecID):
                    self.ecID = ecID
                case .failure:
                    break
                }
            }
            return
        }
        
        visitorAPI.linkExistingECIDToKnownIdentifier(customVisitorId: knownId, dataProviderID: dpId, experienceCloudId: experienceCloudId, authState: authState) { result in
            switch result {
            case .success(let ecID):
                 self.ecID = ecID
            case .failure:
                break
            }
        }
    }
    
    
}
