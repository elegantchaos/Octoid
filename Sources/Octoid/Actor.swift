// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 28/05/2020.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

public struct Actor: Codable {
    let display_login: String
    let id: Int
    let login: String
    let avatar_url: String
    let url: String
    let gravatar_id: String
}

public struct Org: Codable {
    let id: Int
    let login: String
    let avatar_url: String
    let url: String
    let gravatar_id: String
}
