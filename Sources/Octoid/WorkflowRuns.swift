// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 27/05/2020.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import JSONSession

/// GitHub workflow runs payload for a repository or specific workflow.
public struct WorkflowRuns: Codable, Sendable {
    /// Number of runs reported by GitHub.
    let total_count: Int
    /// Decoded workflow run list.
    let workflow_runs: [WorkflowRun]
    
    /// Indicates whether the run list is empty.
    public var isEmpty: Bool {
        workflow_runs.isEmpty
    }
    
    /// Latest run by `run_number`.
    public var latestRun: WorkflowRun {
        guard let latest = workflow_runs.max(by: { $0.run_number < $1.run_number }) else {
            preconditionFailure("Attempted to read latestRun from an empty workflow run list.")
        }
        return latest
    }
}

/// Metadata describing a single GitHub Actions workflow run.
public struct WorkflowRun: Codable, Sendable {
    /// Numeric run identifier.
    let id: Int
    /// Monotonic run number for the workflow.
    let run_number: Int
    /// Current run status.
    public let status: String
    /// Final run conclusion when complete.
    public let conclusion: String?
    /// Head commit metadata associated with the run.
    /// GitHub can return `null` for some run/event types.
    public let head_commit: HeadCommit?
}

/// Resource resolver for workflow-runs endpoints.
/// Supports lookup by workflow file name, workflow ID, or across all workflows.
public struct WorkflowResource: ResourceResolver, Sendable {
    /// Repository name.
    public let name: String
    /// Repository owner.
    public let owner: String
    /// Workflow selector as provided by the caller.
    public let workflow: String
    /// Workflow identifier when using ID-based targeting.
    let workflowID: Int?
    /// Normalized workflow name with extension stripped for path composition.
    let normalizedWorkflow: String
    /// Indicates use of the all-workflows runs endpoint.
    let includeAllWorkflows: Bool
    private static let extensionStripWarning =
        "Warning: workflow '%@' includes '.yml' or '.yaml'; stripping extension when building workflow runs path."

    /// Creates a workflow resource targeting a workflow file name.
    /// Accepts `name`, `name.yml`, or `name.yaml`.
    public init(name: String, owner: String, workflow: String = "Tests") {
        self.name = name
        self.owner = owner
        self.workflow = workflow
        workflowID = nil
        includeAllWorkflows = false
        normalizedWorkflow = Self.normalized(workflow: workflow)
    }

    /// Creates a workflow resource targeting a workflow by numeric ID.
    public init(name: String, owner: String, workflowID: Int) {
        self.name = name
        self.owner = owner
        workflow = String(workflowID)
        self.workflowID = workflowID
        includeAllWorkflows = false
        normalizedWorkflow = workflow
    }

    /// Internal initializer used by convenience constructors.
    private init(name: String, owner: String, workflow: String, includeAllWorkflows: Bool) {
        self.name = name
        self.owner = owner
        self.workflow = workflow
        workflowID = nil
        self.includeAllWorkflows = includeAllWorkflows
        normalizedWorkflow = workflow
    }

    /// Creates a workflow resource targeting the repository-wide runs endpoint.
    public static func allWorkflows(name: String, owner: String) -> WorkflowResource {
        WorkflowResource(name: name, owner: owner, workflow: "*", includeAllWorkflows: true)
    }

    /// API path for the configured workflow runs endpoint.
    public var path: String {
        if includeAllWorkflows {
            "repos/\(owner)/\(name)/actions/runs"
        } else if let workflowID {
            "repos/\(owner)/\(name)/actions/workflows/\(workflowID)/runs"
        } else {
            "repos/\(owner)/\(name)/actions/workflows/\(normalizedWorkflow).yml/runs"
        }
    }

    /// Normalizes supported workflow file suffixes before composing endpoint paths.
    private static func normalized(workflow: String) -> String {
        if let stripped = strippedWorkflowName(workflow) {
            octoidChannel.log(String(format: extensionStripWarning, workflow))
            return stripped
        }

        return workflow
    }

    /// Removes a trailing `.yml` or `.yaml` suffix when present.
    private static func strippedWorkflowName(_ workflow: String) -> String? {
        let lowercaseWorkflow = workflow.lowercased()
        if lowercaseWorkflow.hasSuffix(".yaml") {
            return String(workflow.dropLast(5))
        }

        if lowercaseWorkflow.hasSuffix(".yml") {
            return String(workflow.dropLast(4))
        }

        return nil
    }
}

extension WorkflowResource: CustomStringConvertible {
    /// Human-readable repository/workflow target description.
    public var description: String {
        if includeAllWorkflows {
            return "\(owner)/\(name) all workflows"
        }

        if let workflowID {
            return "\(owner)/\(name) workflow id \(workflowID)"
        }

        return "\(owner)/\(name) \(normalizedWorkflow).yml"
    }
}
