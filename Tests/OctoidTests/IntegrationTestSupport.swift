import Foundation
import Testing

#if canImport(Security)
    import Security
#endif

struct IntegrationConfiguration {
    let apiBaseURL: URL
    let token: String
}

enum IntegrationConfigurationResult {
    case ready(IntegrationConfiguration)
    case skipped(String)
}

enum IntegrationTestSupport {
    static let defaultServer = "api.github.com"
    static let actionStatusUserKey = "GithubUser"
    static let actionStatusServerKey = "GithubServer"
    static let actionStatusDefaultsDomains = [
        "com.elegantchaos.actionstatus",
        "com.elegantchaos.ActionStatus",
    ]

    static let octoidMetadataService = "com.elegantchaos.octoid.integration-tests"
    static let octoidUserAccount = "github-user"
    static let octoidServerAccount = "github-server"

    static func configurationResult() async -> IntegrationConfigurationResult {
        let server = resolvedServer()
        var user = resolvedGithubUser()
        var token = user.flatMap { keychainPassword(account: $0, service: server) }

        if user == nil || token == nil, shouldAttemptDeviceSignIn() {
            do {
                let login = try await signInWithGitHubDeviceFlow(server: server)
                user = login.user
                token = login.token
                _ = saveKeychainPassword(account: user!, service: server, password: token!)
                _ = saveKeychainPassword(
                    account: octoidUserAccount, service: octoidMetadataService, password: user!)
                _ = saveKeychainPassword(
                    account: octoidServerAccount, service: octoidMetadataService, password: server)
            } catch {
                return .skipped("GitHub device sign-in failed: \(error)")
            }
        }

        guard let resolvedUser = user else {
            return .skipped(
                "Missing GitHub user. Sign into ActionStatus or run Extras/Scripts/octoid-integration-signin."
            )
        }

        guard let resolvedToken = token else {
            return .skipped(
                "No token in keychain for account '\(resolvedUser)' and service '\(server)'. Run Extras/Scripts/octoid-integration-signin."
            )
        }

        guard let apiBaseURL = normalizedAPIBaseURL(from: server) else {
            return .skipped("Configured server '\(server)' is not a valid API host.")
        }

        return .ready(
            IntegrationConfiguration(
                apiBaseURL: apiBaseURL,
                token: resolvedToken
            )
        )
    }

    static func makeRequest(path: String, configuration: IntegrationConfiguration) -> URLRequest {
        let url = configuration.apiBaseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.addValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.addValue("Bearer \(configuration.token)", forHTTPHeaderField: "Authorization")
        request.addValue("X-GitHub-Api-Version", forHTTPHeaderField: "2022-11-28")
        return request
    }

    private static func normalizedAPIBaseURL(from rawServer: String) -> URL? {
        let trimmed = rawServer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let prefixed = trimmed.contains("://") ? trimmed : "https://\(trimmed)"
        guard var components = URLComponents(string: prefixed), components.host != nil else {
            return nil
        }

        if components.path.isEmpty {
            components.path = "/"
        }

        return components.url
    }

    private static func resolvedServer() -> String {
        if let value = ProcessInfo.processInfo.environment["OCTOID_GITHUB_SERVER"]?
            .trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty
        {
            return value
        }

        if let value = keychainPassword(
            account: octoidServerAccount, service: octoidMetadataService)
        {
            return value
        }

        if let value = actionStatusSetting(forKey: actionStatusServerKey) {
            return value
        }

        return defaultServer
    }

    private static func resolvedGithubUser() -> String? {
        if let value = ProcessInfo.processInfo.environment["OCTOID_GITHUB_USER"]?
            .trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty
        {
            return value
        }

        if let value = keychainPassword(account: octoidUserAccount, service: octoidMetadataService)
        {
            return value
        }

        return actionStatusSetting(forKey: actionStatusUserKey)
    }

    private static func shouldAttemptDeviceSignIn() -> Bool {
        guard
            let raw = ProcessInfo.processInfo.environment["OCTOID_GITHUB_DEVICE_SIGNIN"]?
                .lowercased()
        else {
            return false
        }

        return raw == "1" || raw == "true" || raw == "yes"
    }

    private static func signInWithGitHubDeviceFlow(server: String) async throws -> (
        user: String, token: String
    ) {
        guard
            let clientID = ProcessInfo.processInfo.environment["OCTOID_GITHUB_CLIENT_ID"]?
                .trimmingCharacters(in: .whitespacesAndNewlines), !clientID.isEmpty
        else {
            throw DeviceSignInError.missingClientID
        }

        let oauthBase = try oauthBaseURL(for: server)
        let deviceCodeURL = oauthBase.appendingPathComponent("login/device/code")
        let tokenURL = oauthBase.appendingPathComponent("login/oauth/access_token")

        let deviceCodeResponse: DeviceCodeResponse = try await postForm(
            to: deviceCodeURL,
            fields: [
                URLQueryItem(name: "client_id", value: clientID),
                URLQueryItem(name: "scope", value: "repo read:user"),
            ]
        )

        print("[OctoidIntegration] GitHub sign-in required.")
        print("[OctoidIntegration] Open: \(deviceCodeResponse.verificationURI)")
        print("[OctoidIntegration] Enter code: \(deviceCodeResponse.userCode)")

        let expiry = Date().addingTimeInterval(TimeInterval(deviceCodeResponse.expiresIn))
        var interval = max(deviceCodeResponse.interval, 1)

        while Date() < expiry {
            let tokenResponse: AccessTokenResponse = try await postForm(
                to: tokenURL,
                fields: [
                    URLQueryItem(name: "client_id", value: clientID),
                    URLQueryItem(name: "device_code", value: deviceCodeResponse.deviceCode),
                    URLQueryItem(
                        name: "grant_type", value: "urn:ietf:params:oauth:grant-type:device_code"),
                ]
            )

            if let token = tokenResponse.accessToken, !token.isEmpty {
                let user = try await fetchUserLogin(token: token, server: server)
                return (user: user, token: token)
            }

            switch tokenResponse.error {
            case "authorization_pending":
                try await Task.sleep(nanoseconds: UInt64(interval) * 1_000_000_000)
            case "slow_down":
                interval += 5
                try await Task.sleep(nanoseconds: UInt64(interval) * 1_000_000_000)
            case "access_denied":
                throw DeviceSignInError.accessDenied
            case "expired_token":
                throw DeviceSignInError.expired
            case .some(let error):
                throw DeviceSignInError.oauth(error)
            case .none:
                throw DeviceSignInError.invalidResponse
            }
        }

        throw DeviceSignInError.expired
    }

    private static func fetchUserLogin(token: String, server: String) async throws -> String {
        guard let apiBaseURL = normalizedAPIBaseURL(from: server) else {
            throw DeviceSignInError.invalidServer
        }

        let endpoint = apiBaseURL.appendingPathComponent("user")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("X-GitHub-Api-Version", forHTTPHeaderField: "2022-11-28")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw DeviceSignInError.invalidResponse
        }

        let decoded = try JSONDecoder().decode(UserResponse.self, from: data)
        return decoded.login
    }

    private static func oauthBaseURL(for server: String) throws -> URL {
        guard let apiBase = normalizedAPIBaseURL(from: server), let host = apiBase.host else {
            throw DeviceSignInError.invalidServer
        }

        let oauthHost: String
        if host == "api.github.com" {
            oauthHost = "github.com"
        } else if host.hasPrefix("api.") {
            oauthHost = String(host.dropFirst(4))
        } else {
            oauthHost = host
        }

        var components = URLComponents()
        components.scheme = apiBase.scheme ?? "https"
        components.host = oauthHost

        guard let url = components.url else {
            throw DeviceSignInError.invalidServer
        }

        return url
    }

    private static func postForm<T: Decodable>(to url: URL, fields: [URLQueryItem]) async throws
        -> T
    {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = formEncodedData(fields)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw DeviceSignInError.invalidResponse
        }

        return try JSONDecoder().decode(T.self, from: data)
    }

    private static func formEncodedData(_ fields: [URLQueryItem]) -> Data? {
        var components = URLComponents()
        components.queryItems = fields
        return components.percentEncodedQuery?.data(using: .utf8)
    }

    private static func keychainPassword(account: String, service: String) -> String? {
        #if canImport(Security)
            let query: [CFString: Any] = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: service,
                kSecAttrAccount: account,
                kSecReturnData: true,
                kSecMatchLimit: kSecMatchLimitOne,
            ]

            var item: CFTypeRef?
            let status = SecItemCopyMatching(query as CFDictionary, &item)
            guard status == errSecSuccess, let data = item as? Data else {
                return nil
            }

            return String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
        #else
            return nil
        #endif
    }

    private static func saveKeychainPassword(account: String, service: String, password: String)
        -> Bool
    {
        #if canImport(Security)
            guard let data = password.data(using: .utf8) else {
                return false
            }

            let query: [CFString: Any] = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: service,
                kSecAttrAccount: account,
            ]

            let attrs: [CFString: Any] = [
                kSecValueData: data
            ]

            let updateStatus = SecItemUpdate(query as CFDictionary, attrs as CFDictionary)
            if updateStatus == errSecSuccess {
                return true
            }

            var addQuery = query
            addQuery[kSecValueData] = data
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            return addStatus == errSecSuccess
        #else
            return false
        #endif
    }

    private static func actionStatusSetting(forKey key: String) -> String? {
        for domain in actionStatusDefaultsDomains {
            if let value = UserDefaults(suiteName: domain)?
                .string(forKey: key)?
                .trimmingCharacters(in: .whitespacesAndNewlines),
                !value.isEmpty
            {
                return value
            }
        }

        let home = FileManager.default.homeDirectoryForCurrentUser
        for domain in actionStatusDefaultsDomains {
            let url =
                home
                .appendingPathComponent("Library", isDirectory: true)
                .appendingPathComponent("Preferences", isDirectory: true)
                .appendingPathComponent("\(domain).plist", isDirectory: false)

            if let dictionary = NSDictionary(contentsOf: url) as? [String: Any],
                let raw = dictionary[key] as? String
            {
                let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
                if !value.isEmpty {
                    return value
                }
            }
        }

        return nil
    }
}

private struct DeviceCodeResponse: Decodable {
    let deviceCode: String
    let userCode: String
    let verificationURI: String
    let expiresIn: Int
    let interval: Int

    enum CodingKeys: String, CodingKey {
        case deviceCode = "device_code"
        case userCode = "user_code"
        case verificationURI = "verification_uri"
        case expiresIn = "expires_in"
        case interval
    }
}

private struct AccessTokenResponse: Decodable {
    let accessToken: String?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case error
    }
}

private struct UserResponse: Decodable {
    let login: String
}

private enum DeviceSignInError: Error {
    case missingClientID
    case invalidServer
    case invalidResponse
    case accessDenied
    case expired
    case oauth(String)
}
