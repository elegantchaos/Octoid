// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 27/05/2020.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

struct WorkflowRuns: Codable {
    let total_count: Int
    let workflow_runs: [WorkflowRun]
    
    var latestRun: WorkflowRun {
        let sorted = workflow_runs.sorted(by: \WorkflowRun.run_number)
        return sorted[total_count - 1]
    }
}

struct WorkflowRun: Codable {
    let id: Int
    let run_number: Int
    let status: String
    let conclusion: String?
}
