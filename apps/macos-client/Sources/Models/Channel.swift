import Foundation

// MARK: - Channel Models

struct Channel: Identifiable, Hashable {
    let id: UUID
    let name: String
    let description: String
    let isPrivate: Bool
    let memberCount: Int
    var unreadCount: Int
    let createdAt: Date

    var displayName: String {
        "#\(name)"
    }
}

struct ChannelMessage: Identifiable, Hashable {
    let id: UUID
    let channelId: UUID
    let sender: ChatUser
    let body: String
    let createdAt: Date
    var reactions: [MessageReaction]
    var isEdited: Bool
    var threadReplyCount: Int

    init(
        id: UUID = UUID(),
        channelId: UUID,
        sender: ChatUser,
        body: String,
        createdAt: Date,
        reactions: [MessageReaction] = [],
        isEdited: Bool = false,
        threadReplyCount: Int = 0
    ) {
        self.id = id
        self.channelId = channelId
        self.sender = sender
        self.body = body
        self.createdAt = createdAt
        self.reactions = reactions
        self.isEdited = isEdited
        self.threadReplyCount = threadReplyCount
    }
}

struct MessageReaction: Identifiable, Hashable {
    let id: UUID
    let emoji: String
    var count: Int
    var userReacted: Bool

    init(id: UUID = UUID(), emoji: String, count: Int, userReacted: Bool = false) {
        self.id = id
        self.emoji = emoji
        self.count = count
        self.userReacted = userReacted
    }
}

// MARK: - Chat User (Simplified for Chat)

struct ChatUser: Identifiable, Hashable {
    let id: UUID
    let displayName: String
    let title: String
    let avatarColor: String
    var isOnline: Bool

    var initials: String {
        let names = displayName.split(separator: " ")
        if names.count >= 2 {
            return String(names[0].prefix(1) + names[1].prefix(1)).uppercased()
        }
        return String(displayName.prefix(2)).uppercased()
    }
}

// MARK: - Direct Message

struct DirectMessage: Identifiable, Hashable {
    let id: UUID
    let participant: ChatUser
    var lastMessage: String?
    var lastMessageAt: Date?
    var unreadCount: Int
}
