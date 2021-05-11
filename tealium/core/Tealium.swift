//
//  Tealium.swift
//  tealium-swift
//
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import Foundation

///  Public interface for the Tealium library.
public class Tealium {

    var enableCompletion: ((_ result: Result<Bool, Error>) -> Void)?
    public static var lifecycleListeners = TealiumLifecycleListeners()
    public var dataLayer: DataLayerManagerProtocol
    // swiftlint:disable identifier_name
    public var zz_internal_modulesManager: ModulesManager?
    // swiftlint:enable identifier_name
    public var migrator: Migratable
    private var token: NotificationToken?

    static var pubSub = MessageQueue()
    
    /// Initializer.
    ///
    /// - Parameter config: `TealiumConfig` Object created with Tealium account, profile, environment, optional loglevel)
    /// - Parameter enableCompletion: `((_ result: Result<Bool, Error>) -> Void)` block to be called when library has finished initializing
    public init(config: TealiumConfig,
                dataLayer: DataLayerManagerProtocol? = nil,
                modulesManager: ModulesManager? = nil,
                migrator: Migratable? = nil,
                enableCompletion: ((_ result: Result<Bool, Error>) -> Void)?) {
        defer {
            TealiumQueues.backgroundSerialQueue.async {
                enableCompletion?(.success(true))
            }
        }
        self.enableCompletion = enableCompletion
        self.dataLayer = dataLayer ?? DataLayer(config: config)
        self.migrator = migrator ?? Migrator(config: config)
        if config.shouldMigratePersistentData {
            self.migrator.migratePersistent(dataLayer: self.dataLayer)
        }
        let context = TealiumContext(config: config, dataLayer: self.dataLayer, tealium: self)
        #if os(iOS)
        if config.appDelegateProxyEnabled {
            TealiumDelegateProxy.setup(context: context)
        }
        #endif
//        Tealium.pubSub.subscribe(subscriber: self)
        TealiumQueues.backgroundSerialQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            self.zz_internal_modulesManager = modulesManager ?? ModulesManager(context)
        }
        TealiumInstanceManager.shared.addInstance(self, config: config)
        TealiumQueues.backgroundSerialQueue.asyncAfter(deadline: .now() + 1.0) {
            self.subscribeToNotifications()
        }
    }

    /// - Parameter config: `TealiumConfig` Object created with Tealium account, profile, environment, optional loglevel)
    public convenience init(config: TealiumConfig) {
        self.init(config: config, enableCompletion: nil)
    }

    /// Suspends all library activity, may release internal objects.
    public func disable() {
        TealiumQueues.backgroundSerialQueue.async {
            if let config = self.zz_internal_modulesManager?.config {
                TealiumInstanceManager.shared.removeInstance(config: config)
            }
            self.zz_internal_modulesManager = nil
        }
    }

    /// Sends all queued dispatches immediately. Requests may still be blocked by DispatchValidators such as Consent Manager
    public func flushQueue() {
        TealiumQueues.backgroundSerialQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            self.zz_internal_modulesManager?.requestDequeue(reason: "Flush Queue Called")
        }
    }

    /// Track an event
    ///
    /// - Parameter dispatch: `TealiumDispatch` containing the event/view name and the data layer object for this event
    public func track(_ dispatch: TealiumDispatch) {
        TealiumQueues.backgroundSerialQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            self.zz_internal_modulesManager?.sendTrack(dispatch.trackRequest)

        }
    }
    
    func subscribeToNotifications() {
        MessageQueue.subscribe(topic: .deepLink, identifier: "core") {
            guard let deepLink = $0.payload[TealiumKey.deepLinkURL] as? URL else {
                            return
            }
            self.handleDeepLink(deepLink)
        }
    }

    deinit {
        #if os(iOS)
        TealiumDelegateProxy.tearDown()
        #endif
    }

}
