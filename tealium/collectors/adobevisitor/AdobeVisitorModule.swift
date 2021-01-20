//
//  AdobeVisitorModule.swift
//  tealium-swift
//
//  Created by Craig Rouse on 13/01/2021.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation
import TealiumCore


public class TealiumAdobeVisitorAPI: Collector {

    
    
    public var id = "TealiumAdobeVisitorAPI"
    
    public var config: TealiumConfig
    
    public var diskStorage: TealiumDiskStorageProtocol?
    
    public var data: [String : Any]? {
        get {
            if let ecID = ecID?.experienceCloudID {
                return [TealiumAdobeVisitorConstants.adobeEcid: ecID]
            } else {
                return nil
            }
        }
    }
    
    var ecID: AdobeExperienceCloudID? {
        willSet {
            if newValue == nil {
                diskStorage?.delete(completion: nil)
            } else if newValue?.isEmpty == false {
                diskStorage?.save(newValue, completion: nil)
                delegate?.requestDequeue(reason: "Adobe Visitor ID Retrieved Successfully")
            }
        }
    }
    
    var visitorAPI: AdobeVisitorAPI?
    
    var error: Error? {
        willSet {
            delegate?.requestDequeue(reason: "Adobe Visitor ID suffered unrecoverable error")
        }
    }
    
    var orgId: String?
    
    var dpId: String {
        config.adobeDataProviderId ?? "0"
    }
    
    var delegate: ModuleDelegate?
    
    public required convenience init(context: TealiumContext, delegate: ModuleDelegate?, diskStorage: TealiumDiskStorageProtocol?, completion: ((Result<Bool, Error>, [String : Any]?)) -> Void) {
        self.init(context:context, delegate: delegate, diskStorage: diskStorage, adobeVisitorAPI: nil, completion: completion)
    }
    
    init(context: TealiumContext,
                  delegate: ModuleDelegate?,
                  diskStorage: TealiumDiskStorageProtocol?,
                  adobeVisitorAPI: AdobeVisitorAPI? = nil,
                  completion: ((Result<Bool, Error>, [String : Any]?)) -> Void) {
        
        self.config = context.config
        self.delegate = delegate
        guard let orgId = config.adobeOrgId else {
            completion((.failure(AdobeVisitorError.missingOrgID), ["adobe_error":"Org ID Not Set. ECID will be missing from track requests"]))
            return
        }
        self.diskStorage = diskStorage ?? TealiumDiskStorage(config: config, forModule: "adobevisitor")
        self.orgId = orgId
        visitorAPI = adobeVisitorAPI ?? AdobeVisitorAPI(adobeOrgId: orgId, enableCookies: true)
        if let existingId = config.adobeExistingECID {
            self.ecID = AdobeExperienceCloudID(experienceCloudID: existingId, idSyncTTL: nil, dcsRegion: nil, blob: nil, nextRefresh: nil)
            refreshECID()
        }
        if let ecID = getECIDFromDisk() {
            self.ecID = ecID
            if let adobeCustomVisitorId = config.adobeCustomVisitorId {
                linkECIDToKnownIdentifier(knownId: adobeCustomVisitorId)
            }
        } else {
            if let adobeCustomVisitorId = config.adobeCustomVisitorId {
                getAndLink(customVisitorId: adobeCustomVisitorId, dpId: dpId, authState: config.adobeAuthState)
            } else {
                getECID()
            }
        }
    }
    
    func getECIDFromDisk() -> AdobeExperienceCloudID? {
        if let ecID = diskStorage?.retrieve(as: AdobeExperienceCloudID.self), !ecID.isEmpty {
            delegate?.requestDequeue(reason: "Adobe Visitor ID Retrieved Successfully")
            if let nextRefresh = ecID.nextRefresh, Date() >= nextRefresh || ecID.nextRefresh == nil {
                refreshECID()
            }
            return ecID
        }
        return nil
    }
    
    /// Resets the Adobe Experience Cloud ID. A new ID will be requested on any subsequent track calls
    public func resetECID() {
        self.ecID = nil
        visitorAPI?.resetSession()
        getECID()
    }
    
    /// Retrieves a new ECID from the Adobe Visitor API
    func getECID(retries: Int = 0) {
        guard let visitorAPI = visitorAPI else {
            return
        }
        visitorAPI.getNewECID { result in
            switch result {
            case .success(let ecID):
                self.ecID = ecID
            case .failure(let error):
                if retries < self.config.adobeRetries {
                    TealiumQueues.backgroundSerialQueue.asyncAfter(deadline: .now() + Double.random(in: 10.0...30.0)) {
                        self.getECID(retries: retries + 1)
                    }
                } else {
                    self.error = error
                }
            }
        }
    }
    
    func getAndLink(customVisitorId: String,
                    dpId: String,
                    authState: AdobeVisitorAuthState?,
                    retries: Int = 0) {
        guard let visitorAPI = visitorAPI else {
            return
        }
        visitorAPI.getNewECIDAndLink(customVisitorId: customVisitorId, dataProviderId: dpId, authState: authState) { result in
            switch result {
            case .success(let ecID):
                self.ecID = ecID
            case .failure(let error):
                if retries < self.config.adobeRetries {
                    TealiumQueues.backgroundSerialQueue.asyncAfter(deadline: .now() + Double.random(in: 10.0...30.0)) {
                        self.getAndLink(customVisitorId: customVisitorId, dpId: dpId, authState:authState, retries: retries + 1)
                    }
                } else {
                    self.error = error
                }
            }
        }
    }
    
    public func linkECIDToKnownIdentifier (knownId: String,
                                           retries: Int = 0) {
        guard let visitorAPI = visitorAPI else {
            return
        }
        guard let experienceCloudId = self.ecID?.experienceCloudID else {
            visitorAPI.getNewECIDAndLink(customVisitorId: knownId, dataProviderId: dpId, authState: config.adobeAuthState) { result in
                switch result {
                case .success(let ecID):
                    self.ecID = ecID
                case .failure(let error):
                    if retries < self.config.adobeRetries {
                        TealiumQueues.backgroundSerialQueue.asyncAfter(deadline: .now() + Double.random(in: 10.0...30.0)) {
                            self.linkECIDToKnownIdentifier(knownId: knownId, retries: retries + 1)
                        }
                    } else {
                        self.error = error
                    }
                }
            }
            return
        }
        
        visitorAPI.linkExistingECIDToKnownIdentifier(customVisitorId: knownId, dataProviderID: dpId, experienceCloudId: experienceCloudId, authState: config.adobeAuthState) { result in
            switch result {
            case .success(let ecID):
                 self.ecID = ecID
            case .failure(let error):
                if retries < self.config.adobeRetries {
                    TealiumQueues.backgroundSerialQueue.asyncAfter(deadline: .now() + Double.random(in: 10.0...30.0)) {
                        self.linkECIDToKnownIdentifier(knownId: knownId, retries: retries + 1)
                    }
                } else {
                    self.error = error
                }
            }
        }
    }
    
    /// Sends a refresh request to the Adobe Visitor API. Used if the TTL has expired.
    public func refreshECID(retries: Int = 0) {
        guard let visitorAPI = visitorAPI, let existingECID = ecID?.experienceCloudID else {
            return
        }
        visitorAPI.refreshECID(existingECID: existingECID) { result in
            switch result {
            case .success(let ecID):
                self.ecID = ecID
            case .failure(let error):
                if retries < self.config.adobeRetries {
                    TealiumQueues.backgroundSerialQueue.asyncAfter(deadline: .now() + Double.random(in: 10.0...30.0)) {
                        self.refreshECID(retries: retries + 1)
                    }
                } else {
                    self.error = error
                }
            }
        }
    }
}

extension TealiumAdobeVisitorAPI: DispatchValidator {
    public func shouldQueue(request: TealiumRequest) -> (Bool, [String : Any]?) {
        guard orgId != nil else {
            return (false, ["adobe_error":"Org ID Not Set. ECID will be missing from track requests"])
        }
        if let error = error {
            return (false, ["adobe_error":"Unrecoverable error: \(error.localizedDescription)"])
        }
        guard let data = self.data else {
            return (true, [TealiumKey.queueReason: AdobeVisitorError.missingExperienceCloudID.localizedDescription])
        }
        return (false, data)
    }
    
    public func shouldDrop(request: TealiumRequest) -> Bool {
        false
    }
    
    public func shouldPurge(request: TealiumRequest) -> Bool {
        false
    }
}
