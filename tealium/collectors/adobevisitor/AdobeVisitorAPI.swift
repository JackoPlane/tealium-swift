//
//  AdobeVisitorAPI.swift
//  TealiumAdobeVisitorAPI
//
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

// 3 use cases:
// 1/ Already have an MID (initialize with MID), but need to link MID with a custom identifier (e.g. email or other ID)
// 2/ Do not have an MID and need to generate it
// 3/ Do not have MID. Need to generate it (case 2), THEN need to provide custom identifier (case 1)
// on init, check for existing ID. If existing ID, add to data layer, link known ID if available
// https://marketing.adobe.com/resources/help/en_US/mcvid/mcvid-direct-integration-examples.html - outdated
//https://docs.adobe.com/content/help/en/id-service/using/implementation/direct-integration-examples.html
// https://github.com/Adobe-Marketing-Cloud/audiencemanager-profilelink

// Remote Command/Module functionality:
// TODO: Support re-synchronization interval based on TTL returned from Adobe


import Foundation

public typealias AdobeResult = Result<AdobeVisitor?, Error>

public typealias AdobeCompletion = ((AdobeResult) -> Void)


public protocol AdobeExperienceCloudIDService {
    var experienceCloudId: AdobeVisitor? { get set }
    
    func getNewECID(completion: @escaping AdobeCompletion)
    
    func getNewECIDAndLink(customVisitorId: String,
                                  dataProviderId: String,
                                  authState: AdobeVisitorAuthState?,
                                  completion: AdobeCompletion?)
    
    func linkExistingECIDToKnownIdentifier(customVisitorId: String,
                                                      dataProviderID: String,
                                                      experienceCloudId: String,
                                                      authState: AdobeVisitorAuthState?,
                                                      completion: AdobeCompletion?)
    
    func refreshECID(existingECID: String,
                                completion: @escaping AdobeCompletion)
    
    func resetSession()
    
}


public class AdobeVisitorAPI: AdobeExperienceCloudIDService {

    public var experienceCloudId: AdobeVisitor?
    var networkSession: NetworkSession
    var adobeOrgId: String

    /// - Parameters:
    /// - networkSession: `NetworkSession` to use for all network requests. Used for unit testing. Defaults to `URLSession.shared`
    /// - adobeOrgId: `String` representing the Adobe Org ID, including the `@AdobeOrg` suffix
    public init(networkSession: NetworkSession = URLSession.shared,
                adobeOrgId: String,
                existingVisitor: AdobeVisitor? = nil) {
        if let urlSession = networkSession as? URLSession {
            urlSession.configuration.httpCookieStorage = nil
        }
        self.experienceCloudId = existingVisitor
        self.adobeOrgId = adobeOrgId
        self.networkSession = networkSession
    }


    /// Allows the API user to determine whether cookies will be maintained on future requests to the Visitor API
    /// If disabled, cookies may be sent on subsequent requests in the same session, but will not be stored for future sessions (ephemeral URLSession)
    /// - Parameters:
    /// - adobeOrgId: `String` representing the Adobe Org ID, including the `@AdobeOrg` suffix
    /// - enableCookies: `Bool` to determine if cookies should be persisted for future sessions. Recommended: `true`.
    public convenience init(adobeOrgId: String,
                            enableCookies: Bool) {
        var urlSessionConfig: URLSessionConfiguration

        if !enableCookies {
            urlSessionConfig = URLSessionConfiguration.ephemeral
        } else {
            urlSessionConfig = URLSessionConfiguration.default
        }

        let urlSession = URLSession(configuration: urlSessionConfig)

        self.init(networkSession: urlSession, adobeOrgId: adobeOrgId)
    }

    // MARK: Utility Functions
    /// Removes unneeded keys from the Adobe Visitor API response
    func removeExtraKeys(_ adobeVistorResponse: [String: Any]) -> [String: Any] {
        return adobeVistorResponse.filter { (key, value) in
            return AdobeVisitorKeys.isValidKey(key)
        }
    }

    /// Sends a request to the Adobe Visitor API, and calls completion with `Result`
    /// - Parameters:
    /// - url: `URL` for the request to be sent to
    /// - completion: Optional `AdobeCompletion` block to be called when the response is returned
    func sendRequest(url: URL,
                     completion: AdobeCompletion?) {

        let urlRequest = URLRequest(url: url)
        networkSession.loadData(from: urlRequest) { result in
            switch result {
            case .success((_, let data)):
                if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let adobeValues = AdobeVisitor.initWithDictionary(self.removeExtraKeys(json)) {
                    completion?(.success(adobeValues))
                } else if let ecID = self.experienceCloudId {
                    completion?(.success(ecID))
                } else {
                    completion?(.failure(AdobeVisitorError.invalidJSON))
                }
            case .failure(let error):
                completion?(.failure(error))
            }

        }
    }

    /// Generates the Adobe CID URL parameter
    /// - Parameters:
    /// - dataProviderId: `String` containing the data provider ID for this custom visitor id (DPID comes from the Adobe Audience Manager UI)
    /// - customVistorId: `String` containing the custom visitor ID (e.g. email address or other known visitor ID)
    /// - authState: Optional `AdobeVisitorAuthState` determining the current authentication state of the visitor
    /// - Returns: `String containing the encoded d_cid parameter`
    func generateCID(dataProviderId: String,
                     customVisitorId: String,
                     authState: AdobeVisitorAuthState?) -> String {
        return [dataProviderId, customVisitorId, authState?.rawValue.description].compactMap {
                    $0
                }
                .joined(separator: AdobeStringConstants.dataProviderIdSeparator.rawValue)
    }


    /// Generates a Demdex URL for a new visitor with no prior ECID
    /// - Parameters:
    /// - withAdobeOrgId: `String` representing the Adobe Org ID, including the `@AdobeOrg` suffix
    /// - version: `Int` representing the API version. Can be omitted.
    /// - Returns: `URL` for a request to the Adobe Visitor API to retrieve a new ECID for the current user
    func getNewUserAdobeIdURL(withAdobeOrgId orgId: String,
                              existingECID: String? = nil,
                              version: Int = AdobeIntConstants.apiVersion.rawValue) -> URL? {
        if let existingECID = existingECID {
            return URL(string: "\(AdobeStringConstants.defaultAdobeURL.rawValue)?\(AdobeVisitorKeys.orgId.rawValue)=\(orgId)&\(AdobeVisitorKeys.experienceCloudId.rawValue)=\(existingECID)&\(AdobeVisitorKeys.version.rawValue)=\(version)")
        } else {
            return URL(string: "\(AdobeStringConstants.defaultAdobeURL.rawValue)?\(AdobeVisitorKeys.orgId.rawValue)=\(orgId)&\(AdobeVisitorKeys.version.rawValue)=\(version)")
        }
    }

    /// Generates a Demdex URL to link a known visitor ID to an ECID
    /// - Parameters:
    /// - version: `Int` representing the API version. Can be omitted.
    /// - customVistorId: `String` containing the custom visitor ID (e.g. email address or other known visitor ID)
    /// - dataProviderId: `String` containing the data provider ID for this custom visitor id (DPID comes from the Adobe Audience Manager UI)
    /// - experienceCloudID: `String` containing the current ECID for this visitor
    /// - authState: Optional `AdobeVisitorAuthState` determining the current authentication state of the visitor
    /// - Returns: `URL` for a request to the Adobe Visitor API to link a known visitor ID to an ECID
    func getExistingUserIdURL(version: Int = AdobeIntConstants.apiVersion.rawValue,
                              customVisitorId: String,
                              dataProviderId: String,
                              experienceCloudId: String,
                              authState: AdobeVisitorAuthState?
    ) -> URL? {
        let dataProviderString = generateCID(dataProviderId: dataProviderId, customVisitorId: customVisitorId, authState: authState)

        return URL(string: "\(AdobeStringConstants.defaultAdobeURL.rawValue)?\(AdobeVisitorKeys.experienceCloudId.rawValue)=\(experienceCloudId)&\(AdobeVisitorKeys.dataProviderId.rawValue)=\(dataProviderString)&\(AdobeVisitorKeys.version)=\(version.description)")
    }

    // MARK: Public API

    /// Requests a new Adobe ECID from the Adobe Visitor API
    /// - Parameter completion: `AdobeCompletion` to be called when the new ID is returned from the Adobe Visitor API
    public func getNewECID(completion: @escaping AdobeCompletion) {
        if let url = getNewUserAdobeIdURL(withAdobeOrgId: adobeOrgId) {
            sendRequest(url: url) { result in
                // attempt to store current state in memory
                self.experienceCloudId = try? result.get()
                completion(result)
            }
        }
    }
    
    /// Resets the URLSession to delete cookies
    public func resetSession() {
        networkSession.reset()
    }
    
    /// Requests a new Adobe ECID from the Adobe Visitor API
    /// - Parameter existingECID: `String` containing the last known ECID to refresh
    /// - Parameter completion: `AdobeCompletion` to be called when the new ID is returned from the Adobe Visitor API
    public func refreshECID(existingECID: String,
                            completion: @escaping AdobeCompletion) {
        if let url = getNewUserAdobeIdURL(withAdobeOrgId: adobeOrgId, existingECID: existingECID) {
            sendRequest(url: url) { result in
                // attempt to store current state in memory
                self.experienceCloudId = try? result.get()
                completion(result)
            }
        }
    }

    /// Links a known visitor ID to an ECID
    /// - Parameters:
    /// - customVistorId: `String` containing the custom visitor ID (e.g. email address or other known visitor ID)
    /// - dataProviderId: `String` containing the data provider ID for this custom visitor id (DPID comes from the Adobe Audience Manager UI)
    /// - experienceCloudID: `String` containing the current ECID for this visitor
    /// - authState: Optional `AdobeVisitorAuthState` determining the current authentication state of the visitor
    /// - completion: Optional `AdobeCompletion` block to be called when the response is returned
    public func linkExistingECIDToKnownIdentifier(customVisitorId: String,
                                                  dataProviderID: String,
                                                  experienceCloudId: String,
                                                  authState: AdobeVisitorAuthState?,
                                                  completion: AdobeCompletion?) {
        if let url = getExistingUserIdURL(customVisitorId: customVisitorId,
                                          dataProviderId: dataProviderID,
                                          experienceCloudId: experienceCloudId,
                                          authState: authState) {
            sendRequest(url: url) { result in
                switch result {
                case .success (var ECID):
                    // ensure ECID is always present in response
                    if ECID?.experienceCloudID == nil {
                        ECID?.experienceCloudID = experienceCloudId
                    }
                    completion?(.success(ECID))
                case .failure:
                    // although the call failed, this is ok, as we already have a known ECID, but no new ECID was returned
                    completion?(.success(self.experienceCloudId))
                }
            }
        }

    }

    /// Gets a new Adobe Experience Cloud ID, then links it to a known ID with a 2nd HTTP request
    /// - Parameters:
    /// - customVistorId: `String` containing the custom visitor ID (e.g. email address or other known visitor ID)
    /// - dataProviderId: `String` containing the data provider ID for this custom visitor id (DPID comes from the Adobe Audience Manager UI)
    /// - authState: Optional `AdobeVisitorAuthState` determining the current authentication state of the visitor
    /// - completion: Optional `AdobeCompletion` block to be called when the response is returned
    public func getNewECIDAndLink(customVisitorId: String,
                                  dataProviderId: String,
                                  authState: AdobeVisitorAuthState?,
                                  completion: AdobeCompletion?) {

            getNewECID { result in
                switch result {
                case .success(let result):
                    guard let experienceCloudID = result?.experienceCloudID  else {
                        completion?(.failure(AdobeVisitorError.missingExperienceCloudID))
                        return
                    }
                    self.linkExistingECIDToKnownIdentifier(customVisitorId: customVisitorId,
                                                               dataProviderID: dataProviderId,
                                                               experienceCloudId: experienceCloudID,
                                                               authState: authState) { result in
                        switch result {
                        case .success (let ECID):
                            completion?(.success(ECID))
                        case .failure (let error):
                            completion?(.failure(error))
                        }
                    }
                case .failure(let error):
                    completion?(.failure(error))
                }
            }
    }

    deinit {
        networkSession.invalidateAndClose()
    }
}
