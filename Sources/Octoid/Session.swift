// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 27/05/2020.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

public class Session {
    let repo: Repository
    let context: Context
    var lastEvent: Date
    
    public var fullName: String { return "\(repo.owner)/\(repo.name)" }
    var tagKey: String { return "\(fullName)-tag" }
    var lastEventKey: String { return "\(fullName)-lastEvent" }
    
    var eventsQuery: String { return  "repos/\(repo.owner)/\(repo.name)/events" }
    var workflowQuery: String { return  "repos/\(repo.owner)/\(repo.name)/actions/workflows/Tests.yml/runs" }
    
    public init(repo: Repository, context: Context) {
        self.repo = repo
        self.context = context
        self.lastEvent = Date(timeIntervalSinceReferenceDate: 0)
        load()
    }
    
    func load() {
        let seconds = UserDefaults.standard.double(forKey: lastEventKey)
        if seconds != 0 {
            lastEvent = Date(timeIntervalSinceReferenceDate: seconds)
        }
    }
    
    func save() {
        let defaults = UserDefaults.standard
        defaults.set(lastEvent.timeIntervalSinceReferenceDate, forKey: lastEventKey)
    }
        
    enum ResponseState {
        case updated
        case unchanged
        case other
    }
    
    typealias Handler = (ResponseState, Data) throws -> Bool
    
    func sendRequest(query: String, tag: String? = nil, repeating: Bool, completionHandler: @escaping Handler ) {
        let authorization = "bearer \(context.token)"
        var request = URLRequest(url: context.endpoint.appendingPathComponent(query))
        request.addValue(authorization, forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        if let tag = tag {
            request.addValue(tag, forHTTPHeaderField: "If-None-Match")
        }
        
        var updatedTag = tag
        var shouldRepeat = repeating
        var repeatInterval = DispatchTimeInterval.seconds(60)
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            networkingChannel.log("got response for \(self.fullName)")
            if let error = error {
                networkingChannel.log(error)
            }
            
            var state: ResponseState
            if let response = response as? HTTPURLResponse,
                let remaining = response.value(forHTTPHeaderField: "X-RateLimit-Remaining"),
                let tag = response.value(forHTTPHeaderField: "Etag"),
                let data = data {
                networkingChannel.log("rate limit remaining: \(remaining)")
                if let seconds = response.value(forHTTPHeaderField: "X-Poll-Interval").asInt {
                    repeatInterval = DispatchTimeInterval.seconds(seconds)
                }
                
                switch response.statusCode {
                    case 200:
                        networkingChannel.log("got updates")
                        state = .updated
                    
                    case 304:
                        networkingChannel.log("no changes")
                        state = .unchanged
                    
                    default:
                        networkingChannel.log("Unexpected response: \(response)")
                        state = .other
                }
                
                updatedTag = tag
                if state != .other {
                    do {
                        shouldRepeat = try shouldRepeat && completionHandler(state, data)
                    } catch {
                        networkingChannel.log("Error thrown processing data \(error)")
                    }
                }
            } else {
                print("Couldn't decode response")
                if let data = data, let string = String(data: data, encoding: .utf8) {
                    print(string)
                }
            }
            
            if shouldRepeat {
                DispatchQueue.global(qos: .background).asyncAfter(deadline: DispatchTime.now().advanced(by: repeatInterval)) {
                    self.sendRequest(query: query, tag: updatedTag, repeating: repeating, completionHandler: completionHandler)
                }
            }
        }
        
        networkingChannel.log("sent request for \(fullName)")
        task.resume()
    }
}

extension Sequence {
    func sorted<T: Comparable>(by keyPath: KeyPath<Element, T>) -> [Element] {
        return sorted { a, b in
            return a[keyPath: keyPath] < b[keyPath: keyPath]
        }
    }
}

extension Optional where Wrapped == String {
    var asInt: Int? {
        if let value = self {
            return Int(value)
        } else {
            return nil
        }
    }
}

