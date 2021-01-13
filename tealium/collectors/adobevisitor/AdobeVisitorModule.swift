//
//  AdobeVisitorModule.swift
//  tealium-swift
//
//  Created by Craig Rouse on 13/01/2021.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation
import TealiumCore

class TealiumAdobeVisitorAPI: Collector, DispatchValidator {
    
    var id = "TealiumAdobeVisitorAPI"
    
    var config: TealiumConfig
    
    var data: [String : Any]?
    
    func shouldQueue(request: TealiumRequest) -> (Bool, [String : Any]?) {
        (true, [:])
    }
    
    func shouldDrop(request: TealiumRequest) -> Bool {
        false
    }
    
    func shouldPurge(request: TealiumRequest) -> Bool {
        false
    }
    
    required init(context: TealiumContext,
                  delegate: ModuleDelegate?,
                  diskStorage: TealiumDiskStorageProtocol?,
                  completion: ((Result<Bool, Error>, [String : Any]?)) -> Void) {
        self.config = context.config
    }
    
    
    
}
