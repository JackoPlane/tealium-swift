//
//  MediaService.swift
//  TealiumCore
//
//  Created by Christina S on 1/6/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation
//#if media
import TealiumCore
//#endif

// config.addMediaSession(MediaSession)
// media.add(MediaSession)
// media.remove(MediaSession)
// media.removeAll()


// Abstract MediaSessionFactory -> HeartBeat, Signifigant, Milestone, Summary
// Create Audio/Video Codable objects - decodeIfPresent from optional meta data


public enum StreamType: String {
    case vod
    case live
    case linear
    case podcast
    case audiobook
    case aod
    case song
    case radio
    case ugc = "UGC"
    case dvod = "DVoD"
    case custom = "Custom"
}
public enum MediaType: String {
    case all
    case audio
    case video
}
public enum TrackingType: String {
    case heartbeat, signifigant, milestone, summary
}
public struct QOE: Codable {
    var bitrate: Int
    
    public init(bitrate: Int) {
        self.bitrate = bitrate
    }
}

public protocol MediaSession {
    var delegate: ModuleDelegate? { get set }
    // var delegate: SummaryDelegate? { get set }
    var media: TealiumMedia { get set }
    func track(_ event: MediaEvent)
}

public extension MediaSession {
    
    func start() {
        
    }
    
    func play() {
        print("MEDIA: play")
        track(.play)
    }
    func pause() {
        print("MEDIA: pause")
        track(.pause)
    }
    func stop() {
        print("MEDIA: stop")
        track(.stop)
    }

    func track(_ event: MediaEvent) {
        let mediaRequest = TealiumMediaTrackRequest(event: event, parameters: media)
        delegate?.requestTrack(mediaRequest.trackRequest)
    }
}

public struct TealiumMedia {
    var name: String
    var streamType: StreamType
    var mediaType: MediaType
    var qoe: QOE
    var trackingType: TrackingType
    var customId: String?
    var duration: Int?
    var playerName: String?
    var channelName: String?
    var metadata: [String: String]?
    var milestone: String?
    var summary: SummaryInfo?
    
    public init(
        name: String,
        streamType: StreamType,
        mediaType: MediaType,
        qoe: QOE,
        trackingType: TrackingType = .signifigant,
        customId: String? = nil,
        duration: Int? = nil,
        playerName: String? = nil,
        channelName: String? = nil,
        metadata: [String: String]? = nil) {
            self.name = name
            self.streamType = streamType
            self.mediaType = mediaType
            self.qoe = qoe
            self.trackingType = trackingType
            self.customId = customId
            self.duration = duration
            self.playerName = playerName
            self.channelName = channelName
            self.metadata = metadata
    }
}

struct MediaServiceFactory {
    static func create(from media: TealiumMedia,
                       with delegate: ModuleDelegate?) -> MediaSession {
        switch media.trackingType {
        case .signifigant:
            return Signifigant(media: media, delegate: delegate)
        case .heartbeat:
            return Heartbeat(media: media, delegate: delegate)
        case .milestone:
            return Milestone(media: media, delegate: delegate)
        case .summary:
            return Summary(media: media, delegate: delegate)
        }
    }
}

protocol SignifigantEventMediaService: MediaSession {
    
}

protocol HeartbeatMediaService: MediaSession {
    func ping()
}

protocol MilestoneMediaService: MediaSession {
    func milestone()
}

protocol SummaryMediaService: MediaSession {
    //var summary: SummaryInfo { get set }
    func update(summary: SummaryInfo)
}

// might change to class
struct Signifigant: SignifigantEventMediaService {
    var media: TealiumMedia
    var delegate: ModuleDelegate?
}

// might change to class
struct Heartbeat: HeartbeatMediaService {
    var media: TealiumMedia
    var delegate: ModuleDelegate?
    
    func ping() {
        print("MEDIA: ping")
        // track ping
    }
}

// might change to class
struct Milestone: MilestoneMediaService {
    var media: TealiumMedia
    var delegate: ModuleDelegate?
    
    func milestone() {
        print("MEDIA: milestone")
        // track milestone
    }
    
}

//public protocol SummaryDelegate {
//    func update(summary: SummaryInfo)
//}

// might change to class 
struct Summary: SummaryMediaService {
    var media: TealiumMedia
    var delegate: ModuleDelegate?
    
    func update(summary: SummaryInfo) {
        print("MEDIA: update")
    }
}


public struct SummaryInfo: Codable {
    var plays: Int = 0
    var pauses: Int = 0
    var stops: Int = 0
    var ads: Int = 0
    var chapters: Int = 0
}

public struct Chapter {
    public init() { }
}
public struct Ad {
    public init() { }
}
public struct AdBreak {
    public init() { }
}
