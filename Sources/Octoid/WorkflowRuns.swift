// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 27/05/2020.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import JSONSession
import CollectionExtensions

public struct WorkflowRuns: Codable {
    let total_count: Int
    let workflow_runs: [WorkflowRun]
    
    public var isEmpty: Bool {
        workflow_runs.isEmpty
    }
    
    public var latestRun: WorkflowRun {
        let sorted = workflow_runs.sorted(by: \WorkflowRun.run_number)
        return sorted.last!
    }
}

public struct WorkflowRun: Codable {
    let id: Int
    let run_number: Int
    public let status: String
    public let conclusion: String?
    public let head_commit: HeadCommit
}

public struct WorkflowResource: ResourceResolver {
    public let name: String
    public let owner: String
    public let workflow: String
    let workflowID: Int?
    let normalizedWorkflow: String
    let includeAllWorkflows: Bool
    private static let extensionStripWarning =
        "Warning: workflow '%@' includes '.yml' or '.yaml'; stripping extension when building workflow runs path."

    public init(name: String, owner: String, workflow: String = "Tests") {
        self.name = name
        self.owner = owner
        self.workflow = workflow
        workflowID = nil
        includeAllWorkflows = false
        normalizedWorkflow = Self.normalized(workflow: workflow)
    }

    public init(name: String, owner: String, workflowID: Int) {
        self.name = name
        self.owner = owner
        workflow = String(workflowID)
        self.workflowID = workflowID
        includeAllWorkflows = false
        normalizedWorkflow = workflow
    }

    private init(name: String, owner: String, workflow: String, includeAllWorkflows: Bool) {
        self.name = name
        self.owner = owner
        self.workflow = workflow
        workflowID = nil
        self.includeAllWorkflows = includeAllWorkflows
        normalizedWorkflow = workflow
    }

    public static func allWorkflows(name: String, owner: String) -> WorkflowResource {
        WorkflowResource(name: name, owner: owner, workflow: "*", includeAllWorkflows: true)
    }

    public func path(in session: JSONSession.Session) -> String {
        if includeAllWorkflows {
            return "repos/\(owner)/\(name)/actions/runs"
        }

        if let workflowID {
            return "repos/\(owner)/\(name)/actions/workflows/\(workflowID)/runs"
        }

        return "repos/\(owner)/\(name)/actions/workflows/\(normalizedWorkflow).yml/runs"
    }

    static func normalized(workflow: String) -> String {
        if let stripped = strippedWorkflowName(workflow) {
            octoidChannel.log(String(format: extensionStripWarning, workflow))
            return stripped
        }

        return workflow
    }

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
