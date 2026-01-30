import Foundation

/// Slack Web API client for Pulsync
/// Handles all REST API calls to Slack's Web API
@MainActor
class SlackAPIClient: ObservableObject {
    static let shared = SlackAPIClient()

    private let baseURL = "https://slack.com/api"
    private let authService: SlackAuthService

    // Cache for users to avoid repeated lookups
    @Published var userCache: [String: SlackUser] = [:]
    @Published var channelCache: [String: SlackChannel] = [:]

    private init() {
        self.authService = SlackAuthService.shared
    }

    // MARK: - Token Access

    private func getToken() throws -> String {
        guard let token = authService.getAccessToken() else {
            throw SlackAPIError.notAuthenticated
        }
        return token
    }

    // MARK: - Channels

    /// List all channels the user is a member of
    func listChannels(
        excludeArchived: Bool = true,
        types: [String] = ["public_channel", "private_channel"],
        limit: Int = 200,
        cursor: String? = nil
    ) async throws -> (channels: [SlackChannel], nextCursor: String?) {
        let token = try getToken()

        var queryItems = [
            URLQueryItem(name: "exclude_archived", value: String(excludeArchived)),
            URLQueryItem(name: "types", value: types.joined(separator: ",")),
            URLQueryItem(name: "limit", value: String(limit))
        ]

        if let cursor = cursor {
            queryItems.append(URLQueryItem(name: "cursor", value: cursor))
        }

        let response: SlackChannelListResponse = try await makeRequest(
            endpoint: "conversations.list",
            token: token,
            queryItems: queryItems
        )

        guard response.ok else {
            throw SlackAPIError.apiError(response.error ?? "Unknown error")
        }

        let channels = response.channels ?? []

        // Update cache
        for channel in channels {
            channelCache[channel.id] = channel
        }

        let nextCursor = response.responseMetadata?.nextCursor
        return (channels, nextCursor?.isEmpty == true ? nil : nextCursor)
    }

    /// Get all channels (handles pagination automatically)
    func listAllChannels(
        excludeArchived: Bool = true,
        types: [String] = ["public_channel", "private_channel"]
    ) async throws -> [SlackChannel] {
        var allChannels: [SlackChannel] = []
        var cursor: String? = nil

        repeat {
            let (channels, nextCursor) = try await listChannels(
                excludeArchived: excludeArchived,
                types: types,
                cursor: cursor
            )
            allChannels.append(contentsOf: channels)
            cursor = nextCursor
        } while cursor != nil

        return allChannels
    }

    /// Get channel info
    func getChannelInfo(channelId: String) async throws -> SlackChannel {
        let token = try getToken()

        struct Response: Decodable {
            let ok: Bool
            let channel: SlackChannel?
            let error: String?
        }

        let response: Response = try await makeRequest(
            endpoint: "conversations.info",
            token: token,
            queryItems: [URLQueryItem(name: "channel", value: channelId)]
        )

        guard response.ok, let channel = response.channel else {
            throw SlackAPIError.apiError(response.error ?? "Channel not found")
        }

        channelCache[channel.id] = channel
        return channel
    }

    // MARK: - Messages

    /// Get message history for a channel
    func getChannelHistory(
        channelId: String,
        limit: Int = 50,
        cursor: String? = nil,
        oldest: String? = nil,
        latest: String? = nil,
        inclusive: Bool = true
    ) async throws -> (messages: [SlackMessage], hasMore: Bool, nextCursor: String?) {
        let token = try getToken()

        var queryItems = [
            URLQueryItem(name: "channel", value: channelId),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "inclusive", value: String(inclusive))
        ]

        if let cursor = cursor {
            queryItems.append(URLQueryItem(name: "cursor", value: cursor))
        }
        if let oldest = oldest {
            queryItems.append(URLQueryItem(name: "oldest", value: oldest))
        }
        if let latest = latest {
            queryItems.append(URLQueryItem(name: "latest", value: latest))
        }

        let response: SlackMessageHistoryResponse = try await makeRequest(
            endpoint: "conversations.history",
            token: token,
            queryItems: queryItems
        )

        guard response.ok else {
            throw SlackAPIError.apiError(response.error ?? "Failed to get channel history")
        }

        let messages = response.messages ?? []
        let hasMore = response.hasMore ?? false
        let nextCursor = response.responseMetadata?.nextCursor

        return (messages, hasMore, nextCursor?.isEmpty == true ? nil : nextCursor)
    }

    /// Get thread replies
    func getThreadReplies(
        channelId: String,
        threadTs: String,
        limit: Int = 100,
        cursor: String? = nil
    ) async throws -> (messages: [SlackMessage], hasMore: Bool, nextCursor: String?) {
        let token = try getToken()

        var queryItems = [
            URLQueryItem(name: "channel", value: channelId),
            URLQueryItem(name: "ts", value: threadTs),
            URLQueryItem(name: "limit", value: String(limit))
        ]

        if let cursor = cursor {
            queryItems.append(URLQueryItem(name: "cursor", value: cursor))
        }

        let response: SlackThreadRepliesResponse = try await makeRequest(
            endpoint: "conversations.replies",
            token: token,
            queryItems: queryItems
        )

        guard response.ok else {
            throw SlackAPIError.apiError(response.error ?? "Failed to get thread replies")
        }

        let messages = response.messages ?? []
        let hasMore = response.hasMore ?? false
        let nextCursor = response.responseMetadata?.nextCursor

        return (messages, hasMore, nextCursor?.isEmpty == true ? nil : nextCursor)
    }

    /// Post a message to a channel
    func postMessage(
        channel: String,
        text: String,
        threadTs: String? = nil,
        replyBroadcast: Bool = false
    ) async throws -> SlackMessage {
        let token = try getToken()

        struct PostMessageRequest: Encodable {
            let channel: String
            let text: String
            let threadTs: String?
            let replyBroadcast: Bool?

            enum CodingKeys: String, CodingKey {
                case channel, text
                case threadTs = "thread_ts"
                case replyBroadcast = "reply_broadcast"
            }
        }

        let requestBody = PostMessageRequest(
            channel: channel,
            text: text,
            threadTs: threadTs,
            replyBroadcast: threadTs != nil ? replyBroadcast : nil
        )

        let response: SlackPostMessageResponse = try await makePostRequest(
            endpoint: "chat.postMessage",
            token: token,
            body: requestBody
        )

        guard response.ok, let message = response.message else {
            throw SlackAPIError.apiError(response.error ?? "Failed to post message")
        }

        return message
    }

    /// Update a message
    func updateMessage(
        channel: String,
        ts: String,
        text: String
    ) async throws -> SlackMessage {
        let token = try getToken()

        struct UpdateMessageRequest: Encodable {
            let channel: String
            let ts: String
            let text: String
        }

        struct Response: Decodable {
            let ok: Bool
            let message: SlackMessage?
            let error: String?
        }

        let response: Response = try await makePostRequest(
            endpoint: "chat.update",
            token: token,
            body: UpdateMessageRequest(channel: channel, ts: ts, text: text)
        )

        guard response.ok, let message = response.message else {
            throw SlackAPIError.apiError(response.error ?? "Failed to update message")
        }

        return message
    }

    /// Delete a message
    func deleteMessage(channel: String, ts: String) async throws {
        let token = try getToken()

        struct DeleteMessageRequest: Encodable {
            let channel: String
            let ts: String
        }

        struct Response: Decodable {
            let ok: Bool
            let error: String?
        }

        let response: Response = try await makePostRequest(
            endpoint: "chat.delete",
            token: token,
            body: DeleteMessageRequest(channel: channel, ts: ts)
        )

        guard response.ok else {
            throw SlackAPIError.apiError(response.error ?? "Failed to delete message")
        }
    }

    // MARK: - Reactions

    /// Add a reaction to a message
    func addReaction(channel: String, ts: String, emoji: String) async throws {
        let token = try getToken()

        struct AddReactionRequest: Encodable {
            let channel: String
            let timestamp: String
            let name: String
        }

        struct Response: Decodable {
            let ok: Bool
            let error: String?
        }

        let response: Response = try await makePostRequest(
            endpoint: "reactions.add",
            token: token,
            body: AddReactionRequest(channel: channel, timestamp: ts, name: emoji)
        )

        // "already_reacted" is not really an error
        guard response.ok || response.error == "already_reacted" else {
            throw SlackAPIError.apiError(response.error ?? "Failed to add reaction")
        }
    }

    /// Remove a reaction from a message
    func removeReaction(channel: String, ts: String, emoji: String) async throws {
        let token = try getToken()

        struct RemoveReactionRequest: Encodable {
            let channel: String
            let timestamp: String
            let name: String
        }

        struct Response: Decodable {
            let ok: Bool
            let error: String?
        }

        let response: Response = try await makePostRequest(
            endpoint: "reactions.remove",
            token: token,
            body: RemoveReactionRequest(channel: channel, timestamp: ts, name: emoji)
        )

        // "no_reaction" is not really an error
        guard response.ok || response.error == "no_reaction" else {
            throw SlackAPIError.apiError(response.error ?? "Failed to remove reaction")
        }
    }

    // MARK: - Users

    /// Get user info
    func getUserInfo(userId: String) async throws -> SlackUser {
        // Check cache first
        if let cached = userCache[userId] {
            return cached
        }

        let token = try getToken()

        let response: SlackUserInfoResponse = try await makeRequest(
            endpoint: "users.info",
            token: token,
            queryItems: [URLQueryItem(name: "user", value: userId)]
        )

        guard response.ok, let user = response.user else {
            throw SlackAPIError.apiError(response.error ?? "User not found")
        }

        userCache[user.id] = user
        return user
    }

    /// List all users in the workspace
    func listUsers(
        limit: Int = 200,
        cursor: String? = nil
    ) async throws -> (users: [SlackUser], nextCursor: String?) {
        let token = try getToken()

        var queryItems = [
            URLQueryItem(name: "limit", value: String(limit))
        ]

        if let cursor = cursor {
            queryItems.append(URLQueryItem(name: "cursor", value: cursor))
        }

        let response: SlackUserListResponse = try await makeRequest(
            endpoint: "users.list",
            token: token,
            queryItems: queryItems
        )

        guard response.ok else {
            throw SlackAPIError.apiError(response.error ?? "Failed to list users")
        }

        let users = response.members ?? []

        // Update cache
        for user in users {
            userCache[user.id] = user
        }

        let nextCursor = response.responseMetadata?.nextCursor
        return (users, nextCursor?.isEmpty == true ? nil : nextCursor)
    }

    /// Get all users (handles pagination)
    func listAllUsers() async throws -> [SlackUser] {
        var allUsers: [SlackUser] = []
        var cursor: String? = nil

        repeat {
            let (users, nextCursor) = try await listUsers(cursor: cursor)
            allUsers.append(contentsOf: users)
            cursor = nextCursor
        } while cursor != nil

        return allUsers
    }

    /// Prefetch users for a list of message user IDs
    func prefetchUsers(userIds: [String]) async {
        let uncachedIds = userIds.filter { userCache[$0] == nil }
        guard !uncachedIds.isEmpty else { return }

        // Fetch users in parallel, but don't fail the whole operation
        await withTaskGroup(of: Void.self) { group in
            for userId in uncachedIds.prefix(10) { // Limit concurrent requests
                group.addTask {
                    _ = try? await self.getUserInfo(userId: userId)
                }
            }
        }
    }

    // MARK: - Direct Messages

    /// List DM conversations
    func listDirectMessages(
        limit: Int = 100,
        cursor: String? = nil
    ) async throws -> (conversations: [SlackConversation], nextCursor: String?) {
        let token = try getToken()

        var queryItems = [
            URLQueryItem(name: "types", value: "im,mpim"),
            URLQueryItem(name: "limit", value: String(limit))
        ]

        if let cursor = cursor {
            queryItems.append(URLQueryItem(name: "cursor", value: cursor))
        }

        let response: SlackConversationsListResponse = try await makeRequest(
            endpoint: "conversations.list",
            token: token,
            queryItems: queryItems
        )

        guard response.ok else {
            throw SlackAPIError.apiError(response.error ?? "Failed to list DMs")
        }

        let conversations = response.channels ?? []
        let nextCursor = response.responseMetadata?.nextCursor

        return (conversations, nextCursor?.isEmpty == true ? nil : nextCursor)
    }

    /// Open a DM with a user
    func openDM(userId: String) async throws -> String {
        let token = try getToken()

        struct OpenDMRequest: Encodable {
            let users: String
        }

        let response: SlackConversationOpenResponse = try await makePostRequest(
            endpoint: "conversations.open",
            token: token,
            body: OpenDMRequest(users: userId)
        )

        guard response.ok, let channel = response.channel else {
            throw SlackAPIError.apiError(response.error ?? "Failed to open DM")
        }

        return channel.id
    }

    // MARK: - Team Info

    /// Get team/workspace info
    func getTeamInfo() async throws -> SlackTeam {
        let token = try getToken()

        struct Response: Decodable {
            let ok: Bool
            let team: SlackTeam?
            let error: String?
        }

        let response: Response = try await makeRequest(
            endpoint: "team.info",
            token: token
        )

        guard response.ok, let team = response.team else {
            throw SlackAPIError.apiError(response.error ?? "Failed to get team info")
        }

        return team
    }

    // MARK: - Search

    /// Search messages
    func searchMessages(
        query: String,
        sort: String = "timestamp",
        sortDir: String = "desc",
        count: Int = 20,
        page: Int = 1
    ) async throws -> [SlackMessage] {
        // Note: Search requires a user token, not a bot token
        guard let token = authService.getUserAccessToken() ?? authService.getAccessToken() else {
            throw SlackAPIError.notAuthenticated
        }

        struct SearchResponse: Decodable {
            let ok: Bool
            let messages: SearchMessages?
            let error: String?

            struct SearchMessages: Decodable {
                let matches: [SlackMessage]?
                let total: Int?
            }
        }

        let response: SearchResponse = try await makeRequest(
            endpoint: "search.messages",
            token: token,
            queryItems: [
                URLQueryItem(name: "query", value: query),
                URLQueryItem(name: "sort", value: sort),
                URLQueryItem(name: "sort_dir", value: sortDir),
                URLQueryItem(name: "count", value: String(count)),
                URLQueryItem(name: "page", value: String(page))
            ]
        )

        guard response.ok else {
            throw SlackAPIError.apiError(response.error ?? "Search failed")
        }

        return response.messages?.matches ?? []
    }

    // MARK: - Private Helpers

    private func makeRequest<T: Decodable>(
        endpoint: String,
        token: String,
        queryItems: [URLQueryItem] = []
    ) async throws -> T {
        var components = URLComponents(string: "\(baseURL)/\(endpoint)")!
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else {
            throw SlackAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        return try await performRequest(request)
    }

    private func makePostRequest<T: Decodable, B: Encodable>(
        endpoint: String,
        token: String,
        body: B
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)/\(endpoint)") else {
            throw SlackAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(body)

        return try await performRequest(request)
    }

    private func performRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw SlackAPIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SlackAPIError.networkError(NSError(domain: "Invalid response", code: 0))
        }

        switch httpResponse.statusCode {
        case 200...299:
            do {
                let decoder = JSONDecoder()
                return try decoder.decode(T.self, from: data)
            } catch {
                throw SlackAPIError.decodingError(error)
            }
        case 401:
            throw SlackAPIError.unauthorized
        case 429:
            // Rate limited - extract retry-after header
            let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After")
            throw SlackAPIError.rateLimited(retryAfter: retryAfter.flatMap { Int($0) })
        default:
            let message = String(data: data, encoding: .utf8)
            throw SlackAPIError.httpError(httpResponse.statusCode, message)
        }
    }
}

// MARK: - Error Types

enum SlackAPIError: LocalizedError {
    case notAuthenticated
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case httpError(Int, String?)
    case apiError(String)
    case unauthorized
    case rateLimited(retryAfter: Int?)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not authenticated with Slack"
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        case .httpError(let code, let message):
            return "HTTP \(code): \(message ?? "Unknown error")"
        case .apiError(let message):
            return "Slack API error: \(message)"
        case .unauthorized:
            return "Unauthorized - token may be invalid"
        case .rateLimited(let retryAfter):
            if let seconds = retryAfter {
                return "Rate limited - retry after \(seconds) seconds"
            }
            return "Rate limited - please try again later"
        }
    }
}

// MARK: - Convenience Extensions

extension SlackAPIClient {
    /// Get messages with resolved user info
    func getChannelHistoryWithUsers(
        channelId: String,
        limit: Int = 50
    ) async throws -> [(message: SlackMessage, user: SlackUser?)] {
        let (messages, _, _) = try await getChannelHistory(channelId: channelId, limit: limit)

        // Prefetch all users
        let userIds = messages.compactMap { $0.user }
        await prefetchUsers(userIds: Array(Set(userIds)))

        return messages.map { message in
            (message, message.user.flatMap { userCache[$0] })
        }
    }

    /// Get a user's display name from cache or fetch
    func getDisplayName(userId: String) async -> String {
        if let cached = userCache[userId] {
            return cached.displayName
        }

        do {
            let user = try await getUserInfo(userId: userId)
            return user.displayName
        } catch {
            return userId
        }
    }
}
