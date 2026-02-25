// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 28/05/2020.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

/// Metadata describing the GitHub account that triggered an event.
public struct Actor: Codable {
    /// Display name shown for the account.
    let display_login: String
    /// Numeric GitHub account identifier.
    let id: Int
    /// GitHub login name.
    let login: String
    /// URL for the account avatar image.
    let avatar_url: String
    /// API URL for the account resource.
    let url: String
    /// Legacy Gravatar identifier.
    let gravatar_id: String
}

/// Metadata describing a GitHub organization associated with an event.
public struct Org: Codable {
    /// Numeric GitHub organization identifier.
    let id: Int
    /// GitHub organization login.
    let login: String
    /// URL for the organization avatar image.
    let avatar_url: String
    /// API URL for the organization resource.
    let url: String
    /// Legacy Gravatar identifier.
    let gravatar_id: String
}
