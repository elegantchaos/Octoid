// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 24/02/2026.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import JSONSession

public struct Workflows: Codable {
    public let total_count: Int
    public let workflows: [Workflow]
}

public struct Workflow: Codable {
    public let id: Int
    public let name: String
    public let path: String
    public let state: String
}

public struct WorkflowsResource: ResourceResolver {
    public let name: String
    public let owner: String

    public init(name: String, owner: String) {
        self.name = name
        self.owner = owner
    }

    public func path(in session: JSONSession.Session) -> String {
        "repos/\(owner)/\(name)/actions/workflows"
    }
}

extension WorkflowsResource: CustomStringConvertible {
    public var description: String {
        "\(owner)/\(name) workflows"
    }
}
