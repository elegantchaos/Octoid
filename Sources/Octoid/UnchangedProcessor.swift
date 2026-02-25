// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/08/2020.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import JSONSession

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Processor handling HTTP 304 responses for poll requests.
public struct UnchangedProcessor<Context: Sendable>: ProcessorGroup {
    /// Processor display name.
    public let name = "unchanged"
    /// Wrapped processor chain containing the single unchanged-response handler.
    public let processors: [AnyProcessor<Context>]

    /// Creates an unchanged-response processor.
    public init() {
        processors = [
            AnyProcessor(
                name: name,
                codes: [304],
                decode: { _, _ in () },
                process: { _, _, request, _ in
                    octoidChannel.log("\(request.resource) was unchanged.")
                    return .inherited
                })
        ]
    }
}
