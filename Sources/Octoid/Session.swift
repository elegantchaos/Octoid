// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 27/05/2020.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import Logger

public let sessionChannel = Channel("com.elegantchaos.octoid.session")

public enum ResponseState {
    case updated
    case unchanged
    case other
}

public protocol ResponseProcessor {
    associatedtype ResponseType: Decodable
    
    func query(for session: Session) -> Query
    func process(state: ResponseState, response: ResponseType, in session: Session) -> Bool
}

open class Session {
    public let session = URLSession.shared
    public let repo: Repository
    public let context: Context
    
    public var eventsQuery = Query(name: "events", response: Events.self) { repo in return  "repos/\(repo.fullName)/events" }
    public var workflowQuery = Query(name: "runs", response: WorkflowRuns.self) { repo in return  "repos/\(repo.fullName)/actions/workflows/Tests.yml/runs" }
    
    public init(repo: Repository, context: Context) {
        self.repo = repo
        self.context = context
    }
        
    
    public func schedule<Processor>(processor: Processor, for deadline: DispatchTime, tag: String? = nil, repeatingEvery: Int? = nil)  where Processor: ResponseProcessor {
        let query = processor.query(for: self)
        let distance = deadline.distance(to: DispatchTime.now())
        sessionChannel.log("Scheduled \(query.name) in \(distance)")
        DispatchQueue.global(qos: .background).asyncAfter(deadline: deadline) {
            self.sendRequest(processor: processor, repeatingEvery: repeatingEvery)
        }
    }

    func sendRequest<Processor>(processor: Processor, tag: String? = nil, repeatingEvery: Int? = nil) where Processor: ResponseProcessor {
        let query = processor.query(for: self)
        var request = query.request(with: context, repo: repo)
        if let tag = tag {
            request.addValue(tag, forHTTPHeaderField: "If-None-Match")
        }
        
        var updatedTag = tag
        var shouldRepeat = repeatingEvery != nil
        var repeatInterval = repeatingEvery ?? 30
        let task = session.dataTask(with: request) { data, response, error in
            networkingChannel.log("got response for \(self.repo)")
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
                    repeatInterval = max(repeatInterval, seconds)
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
                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = .iso8601
                        let decoded: Processor.ResponseType = try decoder.decode(Processor.ResponseType.self, from: data)
                        shouldRepeat = processor.process(state: state, response: decoded, in: self) || shouldRepeat
                    } catch {
                        sessionChannel.log("Error thrown processing \(query.name) for \(Processor.ResponseType.self) \(self.repo)\n\(error)\n\(data.prettyPrinted)")
                    }
                }
            } else {
                print("Couldn't decode response")
                if let data = data, let string = String(data: data, encoding: .utf8) {
                    print(string)
                }
            }
            
            if shouldRepeat {
                self.schedule(processor: processor, for: DispatchTime.now().advanced(by: DispatchTimeInterval.seconds(repeatInterval)), tag: updatedTag, repeatingEvery: repeatingEvery)
            }
        }
        
        sessionChannel.log("Sending \(query.name) for \(repo) (\(request))")
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


public extension Data {
    var prettyPrinted: String {
        if let decoded = try? JSONSerialization.jsonObject(with: self, options: []), let encoded = try? JSONSerialization.data(withJSONObject: decoded, options: .prettyPrinted), let string = String(data: encoded, encoding: .utf8) {
            return string
        }
        
        if let string = String(data: self, encoding: .utf8) {
            return string
        }
        
        return String(describing: self)
    }
}
