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
public struct UnchangedProcessor: ProcessorBase {
    /// Processor display name.
    public let name = "unchanged"
    /// Supported status code list.
    public let codes = [304]
    /// Conformance adapter expected by `JSONSession`.
    public var processors: [ProcessorBase] { return [self] }
    
    /// Creates an unchanged-response processor.
    public init() {
    }
    
    /// Returns a placeholder value because 304 responses do not contain payloads.
    public func decode(data: Data, with decoder: JSONDecoder) throws -> Decodable {
        return ""
    }
    
    /// Logs unchanged responses and keeps inherited polling behavior.
    public func process(decoded: Decodable, response: HTTPURLResponse, for request: Request, in session: JSONSession.Session) -> RepeatStatus {
        octoidChannel.log("\(request.resource) was unchanged.")
        return .inherited
    }
}
