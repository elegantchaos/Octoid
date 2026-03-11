// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 05/08/2020.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import JSONSession

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Standard GitHub API error payload.
public struct Message: Codable, Sendable {
    /// Human-readable error message.
    public let message: String
    /// URL to documentation for the error condition.
    public let documentation_url: String
}

extension Message: CustomStringConvertible {
    /// Combined message and documentation URL.
    public var description: String {
        return "\(message): \(documentation_url)"
    }
}

/// Receives decoded error messages from `MessageProcessor`.
public protocol MessageReceiver: Sendable {
    /// Handles a decoded API message and returns the follow-up polling behavior.
    func received(_ message: Message, response: HTTPURLResponse, for request: Request<Self>) async -> RepeatStatus
}

/// Processor that decodes standard GitHub error payloads for common error status codes.
public struct MessageProcessor<Context: MessageReceiver>: Processor {
    public typealias Payload = Message

    /// Processor display name.
    public let name = "message"
    /// Supported HTTP status codes.
    public let codes = [400, 401, 403, 404]

    /// Creates a message processor.
    public init() {
    }

    /// Logs and forwards decoded API messages to the session receiver.
    public func process(
        _ message: Message,
        response: HTTPURLResponse,
        for request: Request<Context>,
        in context: Context
    ) async -> RepeatStatus {
        octoidChannel.log("\(request.resource) \(message)")
        return await context.received(message, response: response, for: request)
    }
}
