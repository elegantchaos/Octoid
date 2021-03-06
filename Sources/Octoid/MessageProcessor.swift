// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 05/08/2020.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import JSONSession

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public struct Message: Codable {
    public let message: String
    public let documentation_url: String
}

extension Message: CustomStringConvertible {
    public var description: String {
        return "\(message): \(documentation_url)"
    }
}

public protocol MessageReceiver {
    func received(_ message: Message, response: HTTPURLResponse, for request: Request) -> RepeatStatus
}

public struct MessageProcessor<S>: Processor where S: Session, S: MessageReceiver {
    public let name = "message"
    public let codes = [400, 401, 403, 404]
    public var processors: [ProcessorBase] { return [self] }

    public init() {
    }
    
    public func process(_ message: Message, response: HTTPURLResponse, for request: Request, in session: S) -> RepeatStatus {
        octoidChannel.log("\(request.resource) \(message)")
        return session.received(message, response: response, for: request)
    }
}
