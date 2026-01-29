import Foundation

struct AIChatMessage: Codable, Identifiable {
    let id: UUID
    let sessionId: UUID
    let role: String // "user" or "assistant"
    let content: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, role, content
        case sessionId = "session_id"
        case createdAt = "created_at"
    }

    var isUser: Bool {
        role == "user"
    }

    var isAssistant: Bool {
        role == "assistant"
    }
}

struct AIChatSession: Codable, Identifiable {
    let id: UUID
    let title: String?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, title
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var displayTitle: String {
        title ?? "New Chat"
    }
}

struct AIChatSessionWithMessages: Codable, Identifiable {
    let id: UUID
    let title: String?
    let createdAt: Date
    let updatedAt: Date
    let messages: [AIChatMessage]

    enum CodingKeys: String, CodingKey {
        case id, title, messages
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var displayTitle: String {
        title ?? "New Chat"
    }
}

struct AIChatSessionCreate: Encodable {
    let title: String?
}

struct AIChatMessageCreate: Encodable {
    let content: String
}

// SSE Event types for streaming responses
enum AIChatSSEEvent {
    case userMessage(id: UUID)
    case text(content: String)
    case done(assistantMessageId: UUID?)
    case error(message: String)

    static func parse(from data: String) -> AIChatSSEEvent? {
        guard let jsonData = data.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let event = json["event"] as? String else {
            return nil
        }

        switch event {
        case "user_message":
            if let idString = json["id"] as? String, let id = UUID(uuidString: idString) {
                return .userMessage(id: id)
            }
        case "text":
            if let content = json["content"] as? String {
                return .text(content: content)
            }
        case "done":
            let assistantId: UUID?
            if let idString = json["assistant_message_id"] as? String {
                assistantId = UUID(uuidString: idString)
            } else {
                assistantId = nil
            }
            return .done(assistantMessageId: assistantId)
        default:
            break
        }

        return nil
    }
}
