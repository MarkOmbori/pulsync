import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case httpError(Int, String?)
    case unauthorized
    case notFound

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        case .httpError(let code, let message):
            return "HTTP \(code): \(message ?? "Unknown error")"
        case .unauthorized:
            return "Unauthorized - please login"
        case .notFound:
            return "Resource not found"
        }
    }
}

@MainActor
class APIClient: ObservableObject {
    static let shared = APIClient()

    let baseURL = "http://localhost:8000"
    @Published var authToken: String?

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private init() {}

    // MARK: - Generic Request Methods

    func get<T: Decodable>(_ path: String) async throws -> T {
        let request = try makeRequest(path: path, method: "GET")
        return try await performRequest(request)
    }

    func post<T: Decodable, B: Encodable>(_ path: String, body: B) async throws -> T {
        var request = try makeRequest(path: path, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)
        return try await performRequest(request)
    }

    func post<B: Encodable>(_ path: String, body: B) async throws {
        var request = try makeRequest(path: path, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)
        let _: EmptyResponse = try await performRequest(request)
    }

    func patch<T: Decodable, B: Encodable>(_ path: String, body: B) async throws -> T {
        var request = try makeRequest(path: path, method: "PATCH")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)
        return try await performRequest(request)
    }

    func delete(_ path: String) async throws {
        let request = try makeRequest(path: path, method: "DELETE")
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { return }
        if httpResponse.statusCode >= 400 {
            throw APIError.httpError(httpResponse.statusCode, nil)
        }
    }

    // MARK: - Private Helpers

    private func makeRequest(path: String, method: String) throws -> URLRequest {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    private func performRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(NSError(domain: "Invalid response", code: 0))
        }

        switch httpResponse.statusCode {
        case 200...299:
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decodingError(error)
            }
        case 401:
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        default:
            let message = String(data: data, encoding: .utf8)
            throw APIError.httpError(httpResponse.statusCode, message)
        }
    }

    // MARK: - Auth Endpoints

    func login(token: String) async throws -> LoginResponse {
        let response: LoginResponse = try await post("/auth/login", body: LoginRequest(token: token))
        authToken = response.accessToken
        return response
    }

    func logout() {
        authToken = nil
    }

    func getCurrentUser() async throws -> User {
        try await get("/auth/me")
    }

    // MARK: - Feed Endpoints

    func getFeed(cursor: String? = nil) async throws -> FeedResponse {
        var path = "/feed"
        if let cursor = cursor {
            path += "?cursor=\(cursor)"
        }
        return try await get(path)
    }

    func getForYouFeed(cursor: String? = nil) async throws -> FeedResponse {
        var path = "/feed/for-you"
        if let cursor = cursor {
            path += "?cursor=\(cursor)"
        }
        return try await get(path)
    }

    func getFollowingFeed(cursor: String? = nil) async throws -> FeedResponse {
        var path = "/feed/following"
        if let cursor = cursor {
            path += "?cursor=\(cursor)"
        }
        return try await get(path)
    }

    func getDiscoverFeed(cursor: String? = nil) async throws -> FeedResponse {
        var path = "/feed/discover"
        if let cursor = cursor {
            path += "?cursor=\(cursor)"
        }
        return try await get(path)
    }

    func recordView(contentId: UUID, duration: Int, completion: Double) async throws {
        struct ViewData: Encodable {
            let contentId: UUID
            let viewDurationSeconds: Int
            let completionPercent: Double

            enum CodingKeys: String, CodingKey {
                case contentId = "content_id"
                case viewDurationSeconds = "view_duration_seconds"
                case completionPercent = "completion_percent"
            }
        }
        try await post("/feed/view", body: ViewData(
            contentId: contentId,
            viewDurationSeconds: duration,
            completionPercent: completion
        ))
    }

    // MARK: - Content Endpoints

    func getContent(id: UUID) async throws -> ContentFeedItem {
        try await get("/content/\(id)")
    }

    func createContent(_ content: ContentCreate) async throws -> Content {
        try await post("/content", body: content)
    }

    // MARK: - Interaction Endpoints

    func toggleLike(contentId: UUID) async throws -> LikeResponse {
        try await post("/content/\(contentId)/like", body: EmptyBody())
    }

    func toggleBookmark(contentId: UUID) async throws -> BookmarkResponse {
        try await post("/content/\(contentId)/bookmark", body: EmptyBody())
    }

    func getBookmarks() async throws -> [ContentFeedItem] {
        try await get("/bookmarks")
    }

    // MARK: - Comment Endpoints

    func getComments(contentId: UUID) async throws -> [Comment] {
        try await get("/content/\(contentId)/comments")
    }

    func createComment(contentId: UUID, body: String, parentId: UUID? = nil) async throws -> Comment {
        try await post("/content/\(contentId)/comments", body: CommentCreate(body: body, parentId: parentId))
    }

    func deleteComment(id: UUID) async throws {
        try await delete("/comments/\(id)")
    }

    // MARK: - Tag Endpoints

    func getTags() async throws -> [Tag] {
        try await get("/tags")
    }

    func followTag(tagId: UUID, follow: Bool) async throws {
        struct FollowRequest: Encodable {
            let follow: Bool
        }
        try await post("/feed/interests/\(tagId)/follow", body: FollowRequest(follow: follow))
    }

    // MARK: - Health Check

    func checkHealth() async -> Bool {
        do {
            let _: HealthResponse = try await get("/health")
            return true
        } catch {
            return false
        }
    }

    // MARK: - Messages/DM Endpoints

    func getConversations() async throws -> [Conversation] {
        try await get("/messages/conversations")
    }

    func createConversation(participantIds: [UUID], initialMessage: String? = nil) async throws -> Conversation {
        try await post("/messages/conversations", body: ConversationCreate(
            participantIds: participantIds,
            initialMessage: initialMessage
        ))
    }

    func getConversation(id: UUID) async throws -> ConversationWithMessages {
        try await get("/messages/conversations/\(id)")
    }

    func leaveConversation(id: UUID) async throws {
        try await delete("/messages/conversations/\(id)")
    }

    func getMessages(conversationId: UUID, skip: Int = 0, limit: Int = 50) async throws -> [Message] {
        try await get("/messages/conversations/\(conversationId)/messages?skip=\(skip)&limit=\(limit)")
    }

    func sendMessage(conversationId: UUID, body: String) async throws -> Message {
        try await post("/messages/conversations/\(conversationId)/messages", body: MessageCreate(body: body))
    }

    func searchUsers(query: String) async throws -> [UserPublic] {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        return try await get("/messages/users/search?q=\(encoded)")
    }

    // MARK: - AI Chat Endpoints

    func getAIChatSessions() async throws -> [AIChatSession] {
        try await get("/ai-chat/sessions")
    }

    func createAIChatSession(title: String? = nil) async throws -> AIChatSession {
        try await post("/ai-chat/sessions", body: AIChatSessionCreate(title: title))
    }

    func getAIChatSession(id: UUID) async throws -> AIChatSessionWithMessages {
        try await get("/ai-chat/sessions/\(id)")
    }

    func deleteAIChatSession(id: UUID) async throws {
        try await delete("/ai-chat/sessions/\(id)")
    }

    /// Creates a request for streaming AI chat messages via SSE
    func makeAIChatMessageRequest(sessionId: UUID, content: String) throws -> URLRequest {
        var request = try makeRequest(path: "/ai-chat/sessions/\(sessionId)/messages", method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.httpBody = try encoder.encode(AIChatMessageCreate(content: content))
        return request
    }
}

// MARK: - Helper Types

struct EmptyBody: Encodable {}

struct EmptyResponse: Decodable {}

struct LikeResponse: Decodable {
    let status: String
    let isLiked: Bool

    enum CodingKeys: String, CodingKey {
        case status
        case isLiked = "is_liked"
    }
}

struct BookmarkResponse: Decodable {
    let status: String
    let isBookmarked: Bool

    enum CodingKeys: String, CodingKey {
        case status
        case isBookmarked = "is_bookmarked"
    }
}

struct HealthResponse: Codable {
    let status: String
}
