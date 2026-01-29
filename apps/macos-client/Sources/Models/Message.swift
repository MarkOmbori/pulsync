import Foundation

struct Message: Codable, Identifiable {
    let id: UUID
    let conversationId: UUID
    let senderId: UUID
    let body: String
    let createdAt: Date
    let updatedAt: Date
    let sender: UserPublic

    enum CodingKeys: String, CodingKey {
        case id, body, sender
        case conversationId = "conversation_id"
        case senderId = "sender_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct MessageCreate: Encodable {
    let body: String
}

struct ConversationParticipant: Codable, Identifiable {
    let id: UUID
    let conversationId: UUID
    let userId: UUID
    let joinedAt: Date
    let lastReadAt: Date?
    let user: UserPublic

    enum CodingKeys: String, CodingKey {
        case id, user
        case conversationId = "conversation_id"
        case userId = "user_id"
        case joinedAt = "joined_at"
        case lastReadAt = "last_read_at"
    }
}

struct Conversation: Codable, Identifiable {
    let id: UUID
    let createdAt: Date
    let updatedAt: Date
    let participants: [ConversationParticipant]
    let lastMessage: Message?
    let unreadCount: Int

    enum CodingKeys: String, CodingKey {
        case id, participants
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case lastMessage = "last_message"
        case unreadCount = "unread_count"
    }

    /// Get the display name for this conversation (other participants' names)
    func displayName(currentUserId: UUID) -> String {
        let others = participants.filter { $0.userId != currentUserId }
        if others.isEmpty {
            return "Conversation"
        } else if others.count == 1 {
            return others.first?.user.displayName ?? "Unknown"
        } else {
            let names = others.prefix(3).map { $0.user.displayName }
            if others.count > 3 {
                return names.joined(separator: ", ") + " +\(others.count - 3)"
            }
            return names.joined(separator: ", ")
        }
    }

    /// Get avatar URL for 1:1 conversations
    func avatarUrl(currentUserId: UUID) -> String? {
        let others = participants.filter { $0.userId != currentUserId }
        if others.count == 1 {
            return others.first?.user.avatarUrl
        }
        return nil
    }
}

struct ConversationWithMessages: Codable, Identifiable {
    let id: UUID
    let createdAt: Date
    let updatedAt: Date
    let participants: [ConversationParticipant]
    let messages: [Message]

    enum CodingKeys: String, CodingKey {
        case id, participants, messages
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct ConversationCreate: Encodable {
    let participantIds: [UUID]
    let initialMessage: String?

    enum CodingKeys: String, CodingKey {
        case participantIds = "participant_ids"
        case initialMessage = "initial_message"
    }
}
