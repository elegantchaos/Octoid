// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 28/05/2020.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

public struct Commit: Codable {
    let author: Author
    let message: String
    let url: String
    let distinct: Bool
    let sha: String
}

public struct HeadCommit: Codable {
    let id: String
    let tree_id: String
    let message: String
    let timestamp: Date
    let author: Author
    let committer: Author
}
