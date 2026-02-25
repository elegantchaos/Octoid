// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 22/07/2020.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import JSONSession
import Logger

/// Logging channel used by Octoid components.
public let octoidChannel = Channel("com.elegantchaos.Octoid")

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Session configured for GitHub's REST API base URL.
public final class Session: @unchecked Sendable {
    /// Wrapped JSON session used for transport and polling.
    public let jsonSession: JSONSession.Session

    /// Base URL for all polled resources.
    public var base: URL { jsonSession.base }

    /// Bearer token sent with each request.
    public var token: String { jsonSession.token }

    /// Default repeat interval in seconds.
    public var defaultInterval: TimeInterval { jsonSession.defaultInterval }

    /// Creates a GitHub API session using the supplied token and polling defaults.
    public init(
        token: String,
        defaultInterval: TimeInterval = 60.0,
        fetcher: any HTTPDataFetcher = URLSession.shared
    ) {
        let base = URL(string: "https://api.github.com/")!
        jsonSession = JSONSession.Session(
            base: base,
            token: token,
            defaultInterval: defaultInterval,
            fetcher: fetcher
        )
    }

    /// Polls a GitHub API resource using the supplied processing context.
    public func poll<Context: Sendable>(
        target: ResourceResolver,
        context: Context,
        processors: some ProcessorGroup<Context>,
        for deadline: DispatchTime = DispatchTime.now(),
        tag: String? = nil,
        repeatingEvery: TimeInterval? = nil
    ) {
        jsonSession.poll(
            target: target,
            context: context,
            processors: processors,
            for: deadline,
            tag: tag,
            repeatingEvery: repeatingEvery
        )
    }

    /// Cancels all in-flight and scheduled polling tasks.
    public func cancel() {
        jsonSession.cancel()
    }
}
