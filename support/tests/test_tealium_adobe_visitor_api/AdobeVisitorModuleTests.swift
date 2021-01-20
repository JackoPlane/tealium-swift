//
//  AdobeVisitorModuleTests.swift
//  TealiumAdobeVisitorAPITests
//
//  Created by Craig Rouse on 19/01/2021.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import XCTest
@testable import TealiumAdobeVisitorAPI
import TealiumCore

class AdobeVisitorModuleTests: XCTestCase {
    
    var mockVisitorAPISuccess = AdobeVisitorAPI(networkSession: MockNetworkSessionVisitorSuccess(), adobeOrgId: AdobeVisitorAPITestHelpers.adobeOrgId)
    var mockVisitorAPISuccessEmptyECID = AdobeVisitorAPI(networkSession: MockNetworkSessionVisitorSuccessEmptyECID(), adobeOrgId: AdobeVisitorAPITestHelpers.adobeOrgId)
    static var testConfig: TealiumConfig {
        get {
            let config = TealiumConfig(account: "tealiummobile", profile: "demo", environment: "dev")
            config.collectors = [Collectors.AdobeVisitorAPI]
            config.appDelegateProxyEnabled = false
            config.adobeOrgId = AdobeVisitorAPITestHelpers.adobeOrgId
            config.dispatchers = []
            return config
        }
    }
    static let dataLayer = DataLayer(config: testConfig)
    static var tealium: Tealium {
        get {
       let teal = Tealium(config: testConfig)
        return teal
    }}
    static var testContext = TealiumContext(config: testConfig, dataLayer: dataLayer, tealium: tealium)
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testShouldQueueReturnsTrueWhenECIDIsMissing() {
        
    }
    
    func testShouldQueueReturnsFalseWhenECIDIsAvailable() {
        
    }
    
    func testRetryOnAPIError() {
        
    }
    
    func testDequeueAfterMaxRetriesOnAPIError() {
        
    }
    
    func testCollectorReturnsExpectedData() {
        
    }
    
    func testGetNewIDOnInit() {
        
    }
    
    func testExistingECIDUsedOnFailure() {
        
    }
    
    func testNewECIDRequestedOnInvalidResponse() {
        
    }
    
    /// came through as <null> when invalid response received
    func testECIDNotNullOnInvalidResponse() {
        let config = AdobeVisitorModuleTests.testConfig.copy
        let context = TealiumContext(config: config, dataLayer: AdobeVisitorModuleTests.dataLayer, tealium: AdobeVisitorModuleTests.tealium)
        
        let module = TealiumAdobeVisitorAPI(context: context, delegate: nil, diskStorage: MockAdobeVisitorDiskStorageEmpty(), adobeVisitorAPI: mockVisitorAPISuccessEmptyECID) { _, _ in
            
        }
        
        module.getECID()
        XCTAssertNil(module.ecID)
    
    }
    
    func testECIDAvailableOnSuccessfulResponse() {
        let config = AdobeVisitorModuleTests.testConfig.copy
        let context = TealiumContext(config: config, dataLayer: AdobeVisitorModuleTests.dataLayer, tealium: AdobeVisitorModuleTests.tealium)
        
        let module = TealiumAdobeVisitorAPI(context: context, delegate: nil, diskStorage: nil, adobeVisitorAPI: mockVisitorAPISuccess) { _, _ in
            
        }
        
        module.getECID()
        XCTAssertEqual(module.ecID!.experienceCloudID!, AdobeVisitorAPITestHelpers.ecID)
    }
    
    func testDataNotReturnedIfECIDMissing() {
        let config = AdobeVisitorModuleTests.testConfig.copy
        let context = TealiumContext(config: config, dataLayer: AdobeVisitorModuleTests.dataLayer, tealium: AdobeVisitorModuleTests.tealium)
        
        let module = TealiumAdobeVisitorAPI(context: context, delegate: nil, diskStorage: MockAdobeVisitorDiskStorageEmpty(), adobeVisitorAPI: mockVisitorAPISuccessEmptyECID) { _, _ in
            
        }
        
        module.ecID = AdobeExperienceCloudID(experienceCloudID: nil, idSyncTTL: "1", dcsRegion: "1", blob: "1", nextRefresh: Date())
        XCTAssertNil(module.data)
    }
    
    func testDataReturnedIfECIDIsSet() {
        let config = AdobeVisitorModuleTests.testConfig.copy
        let context = TealiumContext(config: config, dataLayer: AdobeVisitorModuleTests.dataLayer, tealium: AdobeVisitorModuleTests.tealium)
        
        let module = TealiumAdobeVisitorAPI(context: context, delegate: nil, diskStorage: MockAdobeVisitorDiskStorageEmpty(), adobeVisitorAPI: mockVisitorAPISuccessEmptyECID) { _, _ in
            
        }
        
        module.ecID = AdobeExperienceCloudID(experienceCloudID: AdobeVisitorAPITestHelpers.ecID, idSyncTTL: "1", dcsRegion: "1", blob: "1", nextRefresh: Date())
        XCTAssertNotNil(module.data)
        XCTAssertEqual(module.data!["adobe_ecid"] as! String, AdobeVisitorAPITestHelpers.ecID)
    }

}


class MockAdobeVisitorDiskStorageEmpty: TealiumDiskStorageProtocol {


    init() {

    }

    func append(_ data: [String: Any], fileName: String, completion: TealiumCompletion?) { }

    func update<T>(value: Any, for key: String, as type: T.Type, completion: TealiumCompletion?) where T: Decodable, T: Encodable { }

    func save(_ data: AnyCodable, completion: TealiumCompletion?) { }

    func save(_ data: AnyCodable, fileName: String, completion: TealiumCompletion?) { }

    func save<T>(_ data: T, completion: TealiumCompletion?) where T: Encodable {

    }

    func save<T>(_ data: T, fileName: String, completion: TealiumCompletion?) where T: Encodable { }

    func append<T>(_ data: T, completion: TealiumCompletion?) where T: Decodable, T: Encodable { }

    func append<T>(_ data: T, fileName: String, completion: TealiumCompletion?) where T: Decodable, T: Encodable { }

    func retrieve<T>(as type: T.Type) -> T? where T: Decodable {
        return nil
    }

    func retrieve<T>(_ fileName: String, as type: T.Type) -> T? where T: Decodable {
        return nil
    }

    func retrieve(fileName: String, completion: (Bool, [String: Any]?, Error?) -> Void) { }

    func append(_ data: [String: Any], forKey: String, fileName: String, completion: TealiumCompletion?) { }

    func delete(completion: TealiumCompletion?) { }

    func totalSizeSavedData() -> String? {
        return "1000"
    }

    func saveStringToDefaults(key: String, value: String) { }

    func getStringFromDefaults(key: String) -> String? {
        return ""
    }

    func saveToDefaults(key: String, value: Any) { }

    func getFromDefaults(key: String) -> Any? {
        return ""
    }

    func removeFromDefaults(key: String) { }

    func canWrite() -> Bool {
        return true
    }
}
