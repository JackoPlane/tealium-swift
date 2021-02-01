//
//  AdobeVisitorModule.swift
//  tealium-swift
//
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation
import TealiumCore

protocol Retryable {
    init(queue: DispatchQueue,
         delay: TimeInterval?)
    func submit(completion: @escaping ()-> Void)
}

class RetryManager: Retryable {
    var queue: DispatchQueue
    var delay: TimeInterval?
    required init(queue: DispatchQueue, delay: TimeInterval?) {
        self.queue = queue
        self.delay = delay
    }
    
    func submit(completion: @escaping () -> Void) {
        if let delay = delay {
            queue.asyncAfter(deadline: .now() + delay, execute: completion)
        } else {
            queue.async {
                completion()
            }
        }
    }
}

public class TealiumAdobeVisitorModule: Collector {

    public var id = "TealiumAdobeVisitorModule"
    
    public var config: TealiumConfig
    
    var diskStorage: TealiumDiskStorageProtocol?
    
    public var data: [String : Any]? {
        get {
            if let ecID = visitor?.experienceCloudID {
                return [TealiumAdobeVisitorConstants.adobeEcid: ecID]
            } else {
                return nil
            }
        }
    }
    
    public var visitor: AdobeVisitor? {
        willSet {
            if newValue == nil {
                diskStorage?.delete(completion: nil)
            } else if newValue?.isEmpty == false {
                diskStorage?.save(newValue, completion: nil)
                delegate?.requestDequeue(reason: AdobeVisitorModuleConstants.successMessage)
            }
        }
    }
    
    var visitorAPI: AdobeExperienceCloudIDService?
    
    var error: Error? {
        willSet {
            delegate?.requestDequeue(reason: AdobeVisitorModuleConstants.failureMessage)
        }
    }
    
    var orgId: String?
    
    var dpId: String {
        config.adobeDataProviderId ?? "0"
    }
    
    var delegate: ModuleDelegate?
    var retryManager: Retryable
    
    public required convenience init(context: TealiumContext, delegate: ModuleDelegate?, diskStorage: TealiumDiskStorageProtocol?, completion: ((Result<Bool, Error>, [String : Any]?)) -> Void) {
        self.init(context:context, delegate: delegate, diskStorage: diskStorage, adobeVisitorAPI: nil, completion: completion)
    }
    
    init(context: TealiumContext,
                  delegate: ModuleDelegate?,
                  diskStorage: TealiumDiskStorageProtocol?,
                  retryManager: Retryable? = nil,
                  adobeVisitorAPI: AdobeExperienceCloudIDService? = nil,
                  completion: ((Result<Bool, Error>, [String : Any]?)) -> Void) {
        
        self.retryManager = retryManager ?? RetryManager(queue: TealiumQueues.backgroundSerialQueue, delay: Double.random(in: 10.0...30.0))
        self.config = context.config
        self.delegate = delegate
        guard let orgId = config.adobeOrgId else {
            completion((.failure(AdobeVisitorError.missingOrgID), [AdobeVisitorModuleKeys.error:AdobeVisitorModuleConstants.missingOrgId]))
            return
        }
        self.diskStorage = diskStorage ?? TealiumDiskStorage(config: config, forModule: self.id)
        self.orgId = orgId
        visitorAPI = adobeVisitorAPI ?? AdobeVisitorAPI(adobeOrgId: orgId, enableCookies: false)
        if let existingId = config.adobeExistingECID {
            self.visitor = AdobeVisitor(experienceCloudID: existingId, idSyncTTL: nil, dcsRegion: nil, blob: nil, nextRefresh: nil)
            self.visitorAPI?.experienceCloudId = visitor
            refreshECID(ecID: visitor)
        }
        if let ecID = getECIDFromDisk() {
            self.visitor = ecID
            self.visitorAPI?.experienceCloudId = visitor
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
    
    func getECIDFromDisk() -> AdobeVisitor? {
        if let ecID = diskStorage?.retrieve(as: AdobeVisitor.self), !ecID.isEmpty {
            delegate?.requestDequeue(reason: AdobeVisitorModuleConstants.successMessage)
            if let nextRefresh = ecID.nextRefresh, Date() >= nextRefresh || ecID.nextRefresh == nil {
                refreshECID(ecID: ecID)
            }
            return ecID
        }
        return nil
    }
    
    /// Retrieves a new ECID from the Adobe Visitor API
    func getECID(retries: Int = 0) {
        guard let visitorAPI = visitorAPI else {
            return
        }
        visitorAPI.getNewECID { result in
            switch result {
            case .success(let ecID):
                if ecID != nil {
                    self.visitor = ecID
                }
            case .failure(let error):
                if retries < self.config.adobeRetries {
                    self.retryManager.submit {
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
                if ecID != nil {
                    self.visitor = ecID
                }
            case .failure(let error):
                if retries < self.config.adobeRetries {
                    self.retryManager.submit {
                        self.getAndLink(customVisitorId: customVisitorId, dpId: dpId, authState:authState, retries: retries + 1)
                    }
                } else {
                    self.error = error
                }
            }
        }
    }
    
    func linkECIDToKnownIdentifier(knownId: String,
                                   retries: Int = 0) {
        guard let visitorAPI = visitorAPI else {
            return
        }
        guard let experienceCloudId = self.visitor?.experienceCloudID else {
            getAndLink(customVisitorId: knownId, dpId: dpId, authState: config.adobeAuthState)
            return
        }
        
        visitorAPI.linkExistingECIDToKnownIdentifier(customVisitorId: knownId, dataProviderID: dpId, experienceCloudId: experienceCloudId, authState: config.adobeAuthState) { result in
            switch result {
            case .success(let ecID):
                if ecID != nil {
                    self.visitor = ecID
                }
            case .failure(let error):
                if retries < self.config.adobeRetries {
                    self.retryManager.submit {
                        self.linkECIDToKnownIdentifier(knownId: knownId, retries: retries + 1)
                    }
                } else {
                    self.error = error
                }
            }
        }
    }
    
    /// Sends a refresh request to the Adobe Visitor API. Used if the TTL has expired.
    func refreshECID(retries: Int = 0,
                            ecID: AdobeVisitor?) {
        guard let visitorAPI = visitorAPI,
              let existingECID = ecID?.experienceCloudID else {
            return
        }
        visitorAPI.refreshECID(existingECID: existingECID) { result in
            switch result {
            case .success(let ecID):
                if ecID != nil {
                    self.visitor = ecID
                }
            case .failure(let error):
                if retries < self.config.adobeRetries {
                    self.retryManager.submit {
                        self.refreshECID(retries: retries + 1, ecID: ecID)
                    }
                } else {
                    self.error = error
                }
            }
        }
    }
}

// Public API methods
public extension TealiumAdobeVisitorModule {
    /// Links a known visitor ID to an ECID
    /// - Parameters:
    /// - knownId: `String` containing the custom visitor ID (e.g. email address or other known visitor ID)
    func linkECIDToKnownIdentifier(_ knownId: String) {
        linkECIDToKnownIdentifier(knownId: knownId)
    }
    
    /// Resets the Adobe Experience Cloud ID. A new ID will be requested on any subsequent track calls
    func resetECID() {
        self.visitor = nil
        self.visitorAPI?.experienceCloudId = nil
        visitorAPI?.resetSession()
        getECID()
    }
    
}


extension TealiumAdobeVisitorModule: DispatchValidator {
    public func shouldQueue(request: TealiumRequest) -> (Bool, [String : Any]?) {
        guard orgId != nil else {
            return (false, [AdobeVisitorModuleKeys.error: AdobeVisitorModuleConstants.missingOrgId])
        }
        if let error = error {
            return (false, [AdobeVisitorModuleKeys.error:"Unrecoverable error: \(error.localizedDescription)"])
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
