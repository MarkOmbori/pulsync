import Foundation
import AppKit
import Security

/// Manages Slack OAuth 2.0 authentication for the Pulsync desktop app
@MainActor
@Observable
class SlackAuthService {
    static let shared = SlackAuthService()

    // MARK: - Published State

    var isAuthenticated: Bool { accessToken != nil }
    var isAuthenticating = false
    var currentUser: SlackUser?
    var teamName: String?
    var error: String?

    // MARK: - Private Properties

    private var accessToken: String?
    private var userAccessToken: String?  // User token for user-scoped operations
    private var appToken: String?  // For Socket Mode

    // Configuration - Replace with your Slack app credentials
    private let clientId: String
    private let clientSecret: String
    private let redirectPort = 8374
    private let redirectPath = "/callback"

    // Keychain keys
    private let keychainServiceName = "com.pulsync.slack"
    private let accessTokenKey = "slack_access_token"
    private let userAccessTokenKey = "slack_user_access_token"
    private let appTokenKey = "slack_app_token"
    private let userIdKey = "slack_user_id"

    // Local server for OAuth callback
    private var callbackServer: SlackOAuthCallbackServer?
    private var authContinuation: CheckedContinuation<String, Error>?

    // MARK: - Required OAuth Scopes

    /// Bot scopes (installed as bot)
    private let botScopes = [
        "channels:read",
        "channels:history",
        "chat:write",
        "users:read",
        "im:read",
        "im:history",
        "im:write",
        "groups:read",
        "groups:history",
        "mpim:read",
        "mpim:history",
        "reactions:read",
        "reactions:write",
        "team:read"
    ]

    /// User scopes (for user-specific actions)
    private let userScopes = [
        "channels:read",
        "channels:history",
        "chat:write",
        "users:read",
        "im:read",
        "im:history",
        "groups:read",
        "groups:history"
    ]

    // MARK: - Initialization

    private init() {
        // Load credentials from environment or configuration
        // In production, these should be securely stored
        self.clientId = ProcessInfo.processInfo.environment["SLACK_CLIENT_ID"] ?? ""
        self.clientSecret = ProcessInfo.processInfo.environment["SLACK_CLIENT_SECRET"] ?? ""
        self.appToken = ProcessInfo.processInfo.environment["SLACK_APP_TOKEN"]

        // Try to restore tokens from Keychain
        Task {
            await restoreSession()
        }
    }

    // MARK: - Public Methods

    /// Start the OAuth 2.0 authentication flow
    func startOAuth() async throws {
        guard !clientId.isEmpty else {
            throw SlackAuthError.missingCredentials("SLACK_CLIENT_ID not configured")
        }

        isAuthenticating = true
        error = nil

        do {
            // Build OAuth URL
            let scopeString = botScopes.joined(separator: ",")
            let userScopeString = userScopes.joined(separator: ",")
            let redirectUri = "http://localhost:\(redirectPort)\(redirectPath)"

            var components = URLComponents(string: "https://slack.com/oauth/v2/authorize")!
            components.queryItems = [
                URLQueryItem(name: "client_id", value: clientId),
                URLQueryItem(name: "scope", value: scopeString),
                URLQueryItem(name: "user_scope", value: userScopeString),
                URLQueryItem(name: "redirect_uri", value: redirectUri)
            ]

            guard let authUrl = components.url else {
                throw SlackAuthError.invalidURL
            }

            // Start local callback server
            let code = try await withCheckedThrowingContinuation { continuation in
                self.authContinuation = continuation
                self.callbackServer = SlackOAuthCallbackServer(port: redirectPort, path: redirectPath) { [weak self] result in
                    Task { @MainActor in
                        self?.handleCallbackResult(result)
                    }
                }
                self.callbackServer?.start()

                // Open browser for authentication
                NSWorkspace.shared.open(authUrl)
            }

            // Exchange code for token
            try await exchangeCodeForToken(code)

            isAuthenticating = false
        } catch {
            isAuthenticating = false
            self.error = error.localizedDescription
            throw error
        }
    }

    /// Set credentials programmatically (for testing or configuration UI)
    func setCredentials(clientId: String, clientSecret: String, appToken: String? = nil) {
        // Note: In a real app, you'd want to handle this differently
        // as ProcessInfo.processInfo.environment is read-only
        // This is a placeholder for a more robust configuration system
    }

    /// Set a pre-existing access token (for testing)
    func setAccessToken(_ token: String) async throws {
        self.accessToken = token
        try await validateAndStoreToken(token)
    }

    /// Logout and clear all stored credentials
    func logout() {
        accessToken = nil
        userAccessToken = nil
        currentUser = nil
        teamName = nil
        error = nil

        // Clear Keychain
        deleteFromKeychain(key: accessTokenKey)
        deleteFromKeychain(key: userAccessTokenKey)
        deleteFromKeychain(key: userIdKey)
    }

    /// Restore session from stored credentials
    func restoreSession() async {
        guard let token = loadFromKeychain(key: accessTokenKey) else { return }

        do {
            try await validateAndStoreToken(token)
            userAccessToken = loadFromKeychain(key: userAccessTokenKey)
        } catch {
            // Token invalid, clear everything
            logout()
        }
    }

    /// Get the current access token
    func getAccessToken() -> String? {
        return accessToken
    }

    /// Get the user access token for user-scoped operations
    func getUserAccessToken() -> String? {
        return userAccessToken
    }

    /// Get the app token for Socket Mode
    func getAppToken() -> String? {
        return appToken
    }

    // MARK: - Private Methods

    private func handleCallbackResult(_ result: Result<String, Error>) {
        callbackServer?.stop()
        callbackServer = nil

        switch result {
        case .success(let code):
            authContinuation?.resume(returning: code)
        case .failure(let error):
            authContinuation?.resume(throwing: error)
        }
        authContinuation = nil
    }

    private func exchangeCodeForToken(_ code: String) async throws {
        guard !clientSecret.isEmpty else {
            throw SlackAuthError.missingCredentials("SLACK_CLIENT_SECRET not configured")
        }

        let redirectUri = "http://localhost:\(redirectPort)\(redirectPath)"

        var components = URLComponents(string: "https://slack.com/api/oauth.v2.access")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "client_secret", value: clientSecret),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "redirect_uri", value: redirectUri)
        ]

        guard let url = components.url else {
            throw SlackAuthError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw SlackAuthError.tokenExchangeFailed
        }

        let tokenResponse = try JSONDecoder().decode(SlackOAuthAccessResponse.self, from: data)

        guard tokenResponse.ok, let botToken = tokenResponse.accessToken else {
            throw SlackAuthError.authFailed(tokenResponse.error ?? "Unknown error")
        }

        // Store bot token
        accessToken = botToken
        saveToKeychain(key: accessTokenKey, value: botToken)

        // Store user token if available
        if let userToken = tokenResponse.authedUser?.accessToken {
            userAccessToken = userToken
            saveToKeychain(key: userAccessTokenKey, value: userToken)
        }

        // Store team info
        teamName = tokenResponse.team?.name

        // Validate token and get user info
        try await validateAndStoreToken(botToken)
    }

    private func validateAndStoreToken(_ token: String) async throws {
        // Test the token by calling auth.test
        let url = URL(string: "https://slack.com/api/auth.test")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let (data, _) = try await URLSession.shared.data(for: request)
        let authResponse = try JSONDecoder().decode(SlackAuthTestResponse.self, from: data)

        guard authResponse.ok else {
            throw SlackAuthError.authFailed(authResponse.error ?? "Token validation failed")
        }

        teamName = authResponse.team
        accessToken = token
        saveToKeychain(key: accessTokenKey, value: token)

        // Get user info if we have a user ID
        if let userId = authResponse.userId {
            saveToKeychain(key: userIdKey, value: userId)
            try await fetchUserInfo(userId: userId)
        }
    }

    private func fetchUserInfo(userId: String) async throws {
        guard let token = accessToken else { return }

        var components = URLComponents(string: "https://slack.com/api/users.info")!
        components.queryItems = [URLQueryItem(name: "user", value: userId)]

        guard let url = components.url else { return }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request)
        let userResponse = try JSONDecoder().decode(SlackUserInfoResponse.self, from: data)

        if userResponse.ok, let user = userResponse.user {
            currentUser = user
        }
    }

    // MARK: - Keychain Helpers

    private func saveToKeychain(key: String, value: String) {
        let data = value.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainServiceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        // Delete existing item first
        SecItemDelete(query as CFDictionary)

        // Add new item
        SecItemAdd(query as CFDictionary, nil)
    }

    private func loadFromKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainServiceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess, let data = item as? Data else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    private func deleteFromKeychain(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainServiceName,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Error Types

enum SlackAuthError: LocalizedError {
    case missingCredentials(String)
    case invalidURL
    case tokenExchangeFailed
    case authFailed(String)
    case callbackError(String)

    var errorDescription: String? {
        switch self {
        case .missingCredentials(let detail):
            return "Missing credentials: \(detail)"
        case .invalidURL:
            return "Invalid OAuth URL"
        case .tokenExchangeFailed:
            return "Failed to exchange authorization code for token"
        case .authFailed(let error):
            return "Authentication failed: \(error)"
        case .callbackError(let error):
            return "OAuth callback error: \(error)"
        }
    }
}

// MARK: - OAuth Callback Server

/// Simple HTTP server to handle OAuth callback
class SlackOAuthCallbackServer {
    private let port: Int
    private let path: String
    private let callback: (Result<String, Error>) -> Void

    private var serverSocket: Int32 = -1
    private var isRunning = false
    private var serverQueue = DispatchQueue(label: "com.pulsync.slack.oauth.server")

    init(port: Int, path: String, callback: @escaping (Result<String, Error>) -> Void) {
        self.port = port
        self.path = path
        self.callback = callback
    }

    func start() {
        serverQueue.async { [weak self] in
            self?.runServer()
        }
    }

    func stop() {
        isRunning = false
        if serverSocket >= 0 {
            close(serverSocket)
            serverSocket = -1
        }
    }

    private func runServer() {
        // Create socket
        serverSocket = socket(AF_INET, SOCK_STREAM, 0)
        guard serverSocket >= 0 else {
            callback(.failure(SlackAuthError.callbackError("Failed to create socket")))
            return
        }

        // Allow address reuse
        var optval: Int32 = 1
        setsockopt(serverSocket, SOL_SOCKET, SO_REUSEADDR, &optval, socklen_t(MemoryLayout<Int32>.size))

        // Bind to port
        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = in_port_t(port).bigEndian
        addr.sin_addr.s_addr = INADDR_ANY

        let bindResult = withUnsafePointer(to: &addr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPtr in
                bind(serverSocket, sockaddrPtr, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }

        guard bindResult >= 0 else {
            callback(.failure(SlackAuthError.callbackError("Failed to bind to port \(port)")))
            close(serverSocket)
            return
        }

        // Listen
        guard listen(serverSocket, 1) >= 0 else {
            callback(.failure(SlackAuthError.callbackError("Failed to listen on socket")))
            close(serverSocket)
            return
        }

        isRunning = true

        // Accept connection
        var clientAddr = sockaddr_in()
        var clientAddrLen = socklen_t(MemoryLayout<sockaddr_in>.size)

        let clientSocket = withUnsafeMutablePointer(to: &clientAddr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPtr in
                accept(serverSocket, sockaddrPtr, &clientAddrLen)
            }
        }

        guard clientSocket >= 0, isRunning else {
            if isRunning {
                callback(.failure(SlackAuthError.callbackError("Failed to accept connection")))
            }
            return
        }

        // Read request
        var buffer = [UInt8](repeating: 0, count: 4096)
        let bytesRead = read(clientSocket, &buffer, buffer.count)

        guard bytesRead > 0 else {
            close(clientSocket)
            callback(.failure(SlackAuthError.callbackError("Failed to read request")))
            return
        }

        let request = String(bytes: buffer.prefix(bytesRead), encoding: .utf8) ?? ""

        // Parse OAuth code from request
        let result = parseOAuthCallback(request)

        // Send response
        let responseBody: String
        let statusLine: String

        switch result {
        case .success:
            statusLine = "HTTP/1.1 200 OK"
            responseBody = """
            <!DOCTYPE html>
            <html>
            <head>
                <title>Pulsync - Slack Connected</title>
                <style>
                    body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; background: #0A0A0B; color: white; }
                    .container { text-align: center; }
                    h1 { color: #6366F1; }
                    p { color: #9CA3AF; }
                </style>
            </head>
            <body>
                <div class="container">
                    <h1>✓ Connected to Slack</h1>
                    <p>You can close this window and return to Pulsync.</p>
                </div>
            </body>
            </html>
            """
        case .failure(let error):
            statusLine = "HTTP/1.1 400 Bad Request"
            responseBody = """
            <!DOCTYPE html>
            <html>
            <head>
                <title>Pulsync - Error</title>
                <style>
                    body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; background: #0A0A0B; color: white; }
                    .container { text-align: center; }
                    h1 { color: #EF4444; }
                    p { color: #9CA3AF; }
                </style>
            </head>
            <body>
                <div class="container">
                    <h1>✗ Connection Failed</h1>
                    <p>\(error.localizedDescription)</p>
                </div>
            </body>
            </html>
            """
        }

        let response = """
        \(statusLine)\r
        Content-Type: text/html; charset=utf-8\r
        Content-Length: \(responseBody.utf8.count)\r
        Connection: close\r
        \r
        \(responseBody)
        """

        _ = response.withCString { ptr in
            write(clientSocket, ptr, strlen(ptr))
        }

        close(clientSocket)
        stop()

        // Call completion handler
        callback(result)
    }

    private func parseOAuthCallback(_ request: String) -> Result<String, Error> {
        // Extract the path from the HTTP request
        guard let firstLine = request.split(separator: "\r\n").first else {
            return .failure(SlackAuthError.callbackError("Invalid request"))
        }

        let parts = firstLine.split(separator: " ")
        guard parts.count >= 2 else {
            return .failure(SlackAuthError.callbackError("Invalid request format"))
        }

        let requestPath = String(parts[1])

        // Parse query parameters
        guard let components = URLComponents(string: requestPath) else {
            return .failure(SlackAuthError.callbackError("Failed to parse callback URL"))
        }

        // Check for error parameter
        if let error = components.queryItems?.first(where: { $0.name == "error" })?.value {
            return .failure(SlackAuthError.authFailed(error))
        }

        // Extract authorization code
        guard let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            return .failure(SlackAuthError.callbackError("No authorization code received"))
        }

        return .success(code)
    }
}
