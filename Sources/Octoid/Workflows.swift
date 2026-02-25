// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 24/02/2026.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import JSONSession

/// GitHub workflow listing payload for a repository.
public struct Workflows: Codable {
    /// Number of workflows reported by GitHub.
    public let total_count: Int
    /// Workflows available in the repository.
    public let workflows: [Workflow]

    /// Preferred workflow for polling:
    /// first active workflow when present, otherwise the first listed workflow.
    public var preferredWorkflow: Workflow? {
        workflows.first(where: { $0.state == "active" }) ?? workflows.first
    }
}

/// Metadata describing a single GitHub Actions workflow.
public struct Workflow: Codable {
    /// Numeric workflow identifier.
    public let id: Int
    /// Workflow display name.
    public let name: String
    /// Repository-relative workflow file path.
    public let path: String
    /// Workflow state, e.g. `active` or `disabled_manually`.
    public let state: String
}

/// Resource resolver for repository workflow discovery endpoint.
public struct WorkflowsResource: ResourceResolver {
    /// Repository name.
    public let name: String
    /// Repository owner.
    public let owner: String

    /// Creates a workflow discovery resource for a repository.
    public init(name: String, owner: String) {
        self.name = name
        self.owner = owner
    }

    /// API path used to list workflows in the repository.
    public func path(in session: JSONSession.Session) -> String {
        "repos/\(owner)/\(name)/actions/workflows"
    }
}

extension WorkflowsResource: CustomStringConvertible {
    /// Human-readable repository/workflow target description.
    public var description: String {
        "\(owner)/\(name) workflows"
    }
}
