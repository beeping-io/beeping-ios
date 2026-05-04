import Foundation
import Beeping

/// Picks which `BeepingClient` flavor the sample app talks to.
public enum AppEnvironment: String, CaseIterable, Sendable, Identifiable {
    case local
    case dev
    case prod

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .local: return "Local"
        case .dev: return "Dev"
        case .prod: return "Prod"
        }
    }

    /// `true` if the env has the credentials it needs.
    /// Local always works; cloud envs require key + endpoint.
    public var isAvailable: Bool {
        #if DEBUG
        switch self {
        case .local:
            return true
        case .dev:
            return !BeepboxSecrets.devApiKey.isEmpty && !BeepboxSecrets.devEndpoint.isEmpty
        case .prod:
            return !BeepboxSecrets.prodApiKey.isEmpty && !BeepboxSecrets.prodEndpoint.isEmpty
        }
        #else
        return self == .local
        #endif
    }

    /// Builds a `BeepingClient` for this environment.
    /// Returns `nil` if the env is unavailable (missing credentials).
    @MainActor
    public func makeClient() -> BeepingClient? {
        guard isAvailable else { return nil }
        switch self {
        case .local:
            return BeepingClient.local().build()
        case .dev:
            #if DEBUG
            guard let url = URL(string: BeepboxSecrets.devEndpoint) else { return nil }
            return BeepingClient.cloud(apiKey: BeepboxSecrets.devApiKey, endpoint: url).build()
            #else
            return nil
            #endif
        case .prod:
            #if DEBUG
            guard let url = URL(string: BeepboxSecrets.prodEndpoint) else { return nil }
            return BeepingClient.cloud(apiKey: BeepboxSecrets.prodApiKey, endpoint: url).build()
            #else
            return nil
            #endif
        }
    }
}
