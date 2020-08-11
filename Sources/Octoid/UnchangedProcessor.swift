// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/08/2020.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import JSONSession

public struct UnchangedProcessor: ProcessorBase {
    public let name = "unchanged"
    public let codes = [304]

    public init() {
    }
    
    public func decode(data: Data, with decoder: JSONDecoder) throws -> Decodable {
        return ""
    }
    
    public func process(decoded: Decodable, response: HTTPURLResponse, for request: Request, in session: JSONSession.Session) -> RepeatStatus {
        // if we got a 304 response, we don't need to decode anything
        octoidChannel.log("\(request.resource) was unchanged.")
        return .inherited
    }
}
