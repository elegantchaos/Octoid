// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 28/05/2020.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation



public protocol Processor {
    associatedtype Payload: Decodable
    
    func query(for session: Session) -> Query
    func process(state: ResponseState, response: Payload, in session: Session) -> Bool
}

public extension Processor {
    internal func decode(response: HTTPURLResponse, data: Data, in session: Session) throws -> Bool {
        switch response.statusCode {
            case 200:
                networkingChannel.log("got updates")
                return try decode(data: data, state: .updated, in: session)
            
            case 304:
                networkingChannel.log("no changes")
                return try decode(data: data, state: .unchanged, in: session)
            
            case 404:
                networkingChannel.log("error")
                return try decodeError(data)
            
            default:
                throw Session.Errors.unexpectedResponse(response.statusCode)
        }
    }
    
    fileprivate func decode(data: Data, state: ResponseState, in session: Session) throws -> Bool {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(Payload.self, from: data)
        return process(state: state, response: decoded, in: session)
    }
    
    fileprivate func decodeError(_ data: Data) throws -> Bool {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let error = try decoder.decode(Failure.self, from: data)
        if !error.canIgnore {
            throw Session.Errors.apiError(error)
        }
        
        return false
    }
}
