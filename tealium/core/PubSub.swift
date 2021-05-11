// 
// PubSub.swift
// tealium-swift
//
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation

struct Message {
    var topic: Topic
    var payload: [String: Any]
    var expires: DispatchTime
    let uuid = UUID()
}

//protocol Subscriber {
//    var id: String { get }
//    func didReceive(message: Message) -> Ack
//    func messagePending()
//}

//struct Ack {
//    var success: Bool
//}

enum Topic: CaseIterable {
    case deepLink
}

typealias MessageHandler = (Message) -> Void

class MessageQueue {
    
    private static var _queue: Atomic<[Message]> = Atomic(value: [Message]())
    
    static let dispatchQueue = DispatchQueue(label: "TealiumMessageQueue")
    
    static var queue: [Message] {
        get {
            let queue = _queue.setAndGet(to: _queue.value.filter {
                DispatchTime.now() < $0.expires
            })

            return queue
        }
        set {
            let queue = _queue.setAndGet(to: newValue)
            dispatchQueue.async {
                notifyTopicSubscribers(messages: queue)
            }
        }
    }
    
    static var consumed = [String: Set<UUID>]()
    
    static var allSubscribers = Atomic(value: [Topic: [(identifier: String, handler: MessageHandler)]]())
    
    static func topicSubscribers(topic: Topic) -> [String]? {
        allSubscribers.value[topic]?.map {
            $0.identifier
        }
    }
    
    static func publish(_ message: Message) {
        queue.append(message)
    }
    
    static func subscribe(topic: Topic, identifier: String, handler: @escaping MessageHandler) {
            // prevent duplicate subscription
            guard topicSubscribers(topic: topic)?.contains(identifier) ?? false == false else {
                return
            }
            allSubscribers.value[topic] = allSubscribers.value[topic] ?? [(String, MessageHandler)]()
            allSubscribers.value[topic]?.append((identifier, handler))
            dispatchQueue.sync {
                let messages = messagesForTopic(topic: topic)
                notifyTopicSubscribers(messages: messages)
            }
    }
    
    static func unsubscribe(topic: Topic, identifier: String) {
        guard var topicSubscribers = allSubscribers.value[topic] else {
            return
        }
        
        topicSubscribers.removeAll {
            $0.identifier == identifier
        }
        
        allSubscribers.value[topic] = topicSubscribers
    }
    
    static func unsubscribeAll() {
        allSubscribers.value = [:]
    }
    
    static func notifyTopicSubscribers(messages: [Message]) {
        dispatchQueue.async {
            messages.forEach { message in
                guard let subscribers = allSubscribers.value[message.topic] else {
                    // No subscribers
                    return
                }

                subscribers.forEach {
                    guard consumed[$0.identifier]?.contains(message.uuid) ?? false == false else {
                        // message already consumed
                        return
                    }
                    consumed[$0.identifier] = consumed[$0.identifier] ?? []
                    consumed[$0.identifier]?.insert(message.uuid)
                    $0.handler(message)
                }
            }
        }
    }
    
    static func messagesForTopic(topic: Topic) -> [Message] {
        return queue.filter {
            $0.topic == topic
        }
    }
    
}
