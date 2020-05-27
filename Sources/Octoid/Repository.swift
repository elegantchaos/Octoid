// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 27/05/2020.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

public struct Repository {
    public let name: String
    public let owner: String
    
    public init(name: String, owner: String) {
        self.name = name
        self.owner = owner
    }
    
    public var fullName: String { return "\(owner)/\(name)" }

}

extension Repository: CustomStringConvertible {
    public var description: String {
        return fullName
    }
}
