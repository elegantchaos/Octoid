// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 27/05/2020.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import JSONSession

public typealias Events = [Event]

public struct EventsResource: ResourceResolver {
    public let name: String
    public let owner: String
    
    public init(name: String, owner: String) {
        self.name = name
        self.owner = owner
    }

    public func path(in session: JSONSession.Session) -> String {
        return "repos/\(owner)/\(name)/events"
    }
}

public struct EventPayload: Codable {
    let ref: String?
    let ref_type: String?
    let description: String?
    let master_branch: String?
    let pusher_type: String?
    let before: String?
    let push_id: Int?
    let size: Int?
    let distinct_size: Int?
    let head: String?
    let commits: [Commit]?
}


public struct Event: Codable {
    public let id: String
    public let type: String
    public let created_at: Date
    public let `public`: Bool
    public let actor: Actor
    public let org: Org
    public let payload: EventPayload
}

