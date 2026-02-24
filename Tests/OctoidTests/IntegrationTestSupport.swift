import Foundation
import Testing

#if canImport(Security)
import Security
#endif

struct IntegrationConfiguration {
    let apiBaseURL: URL
    let token: String
    let owner: String
    let repository: String
    let workflow: String
}

enum IntegrationTestSupport {
    static let defaultServer = "api.github.com"
    static let actionStatusUserKey = "GithubUser"
    static let actionStatusServerKey = "GithubServer"
    static let actionStatusDefaultsDomains = [
        "com.elegantchaos.actionstatus",
        "com.elegantchaos.ActionStatus",
    ]

    static func configuration() -> IntegrationConfiguration? {
        let server = resolvedServer()
        guard let user = resolvedGithubUser() else {
            return nil
        }

        guard let token = keychainPassword(account: user, service: server) else {
            return nil
        }

        let owner = ProcessInfo.processInfo.environment["OCTOID_TEST_OWNER"] ?? "elegantchaos"
        let repository = ProcessInfo.processInfo.environment["OCTOID_TEST_REPO"] ?? "Octoid"
        let workflow = ProcessInfo.processInfo.environment["OCTOID_TEST_WORKFLOW"] ?? "Tests"

        guard let apiBaseURL = normalizedAPIBaseURL(from: server) else {
            return nil
        }

        return IntegrationConfiguration(
            apiBaseURL: apiBaseURL,
            token: token,
            owner: owner,
            repository: repository,
            workflow: workflow
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
        if let value = ProcessInfo.processInfo.environment["OCTOID_GITHUB_SERVER"]?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty {
            return value
        }

        for domain in actionStatusDefaultsDomains {
            if let value = UserDefaults(suiteName: domain)?.string(forKey: actionStatusServerKey)?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty {
                return value
            }
        }

        return defaultServer
    }

    private static func resolvedGithubUser() -> String? {
        if let value = ProcessInfo.processInfo.environment["OCTOID_GITHUB_USER"]?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty {
            return value
        }

        for domain in actionStatusDefaultsDomains {
            if let value = UserDefaults(suiteName: domain)?.string(forKey: actionStatusUserKey)?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty {
                return value
            }
        }

        return nil
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
}
