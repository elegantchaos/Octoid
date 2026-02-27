// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 28/05/2020.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// Commit summary data included in event payloads.
public struct Commit: Codable, Sendable {
    /// Commit author details.
    let author: Author
    /// Commit message text.
    let message: String
    /// API URL for the commit.
    let url: String
    /// Indicates whether this commit is distinct in the push payload.
    let distinct: Bool
    /// Full commit SHA.
    let sha: String
}

/// Detailed commit information attached to workflow runs.
public struct HeadCommit: Codable, Sendable {
    /// Commit SHA.
    let id: String
    /// Tree object SHA.
    let tree_id: String
    /// Commit message text.
    let message: String
    /// Commit timestamp.
    let timestamp: Date
    /// Commit author details.
    let author: Author
    /// Committer details.
    let committer: Author
}
