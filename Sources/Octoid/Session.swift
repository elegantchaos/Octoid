// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 22/07/2020.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import DataFetcher
import Foundation
import JSONSession
import Logger

public let octoidChannel = Channel("com.elegantchaos.Octoid")

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

open class Session: JSONSession.Session {
    public init(token: String, defaultInterval: TimeInterval = 60.0, fetcher: DataFetcher = URLSession.shared) {
        let base = URL(string: "https://api.github.com/")!
        super.init(base: base, token: token, defaultInterval: defaultInterval, fetcher: fetcher)
    }
}
