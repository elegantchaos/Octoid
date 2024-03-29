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
    
    public init(name: String, owner: String, workflow: String = "Tests") {
        self.name = name
        self.owner = owner
        self.workflow = workflow
    }

    public func path(in session: JSONSession.Session) -> String {
        return "repos/\(owner)/\(name)/actions/workflows/\(workflow).yml/runs"
    }
}

extension WorkflowResource: CustomStringConvertible {
    public var description: String {
        return "\(owner)/\(name) \(workflow).yml"
    }
}
