// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 27/05/2020.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import JSONSession

/// Event list payload returned by GitHub repository events endpoint.
public typealias Events = [Event]

/// Resource resolver for repository events endpoint.
public struct EventsResource: ResourceResolver {
    /// Repository name.
    public let name: String
    /// Repository owner.
    public let owner: String
    
    /// Creates an events resource for the given repository.
    public init(name: String, owner: String) {
        self.name = name
        self.owner = owner
    }

    /// API path used to list repository events.
    public func path(in session: JSONSession.Session) -> String {
        return "repos/\(owner)/\(name)/events"
    }
}

extension EventsResource: CustomStringConvertible {
    /// Human-readable repository target description.
    public var description: String {
        return "\(owner)/\(name)"
    }
}

/// Event-specific payload fields returned by GitHub.
public struct EventPayload: Codable {
    /// Git ref associated with the event.
    let ref: String?
    /// Ref type such as `branch` or `tag`.
    let ref_type: String?
    /// Free-form description attached to the event.
    let description: String?
    /// Repository default branch at event time.
    let master_branch: String?
    /// Pusher account type.
    let pusher_type: String?
    /// Commit SHA before the push.
    let before: String?
    /// Numeric push identifier.
    let push_id: Int?
    /// Number of commits in the push.
    let size: Int?
    /// Number of distinct commits in the push.
    let distinct_size: Int?
    /// Commit SHA at the head of the push.
    let head: String?
    /// Commit summaries included in the push.
    let commits: [Commit]?
}


/// Repository event metadata from the GitHub Events API.
public struct Event: Codable {
    /// Event identifier.
    public let id: String
    /// Event type name.
    public let type: String
    /// Event creation timestamp.
    public let created_at: Date
    /// Indicates whether the event is public.
    public let `public`: Bool
    /// Actor that triggered the event.
    public let actor: Actor
    /// Organization associated with the event.
    public let org: Org
    /// Event-specific payload details.
    public let payload: EventPayload
}
