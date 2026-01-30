import Foundation

// MARK: - Slack API Response Wrapper

struct SlackResponse<T: Decodable>: Decodable {
    let ok: Bool
    let error: String?

    // The actual data varies by endpoint, so we'll handle it in specific response types
}

// MARK: - Slack Channel

struct SlackChannel: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let isPrivate: Bool
    let isMember: Bool
    let isArchived: Bool
    let topic: SlackTopic?
    let purpose: SlackPurpose?
    let numMembers: Int?
    let created: TimeInterval?
    let creator: String?

    enum CodingKeys: String, CodingKey {
        case id, name, topic, purpose, created, creator
        case isPrivate = "is_private"
        case isMember = "is_member"
        case isArchived = "is_archived"
        case numMembers = "num_members"
    }

    var displayName: String {
        "#\(name)"
    }
}

struct SlackTopic: Codable, Hashable {
    let value: String
    let creator: String?
    let lastSet: TimeInterval?

    enum CodingKeys: String, CodingKey {
        case value, creator
        case lastSet = "last_set"
    }
}

struct SlackPurpose: Codable, Hashable {
    let value: String
    let creator: String?
    let lastSet: TimeInterval?

    enum CodingKeys: String, CodingKey {
        case value, creator
        case lastSet = "last_set"
    }
}

// MARK: - Slack Channel List Response

struct SlackChannelListResponse: Decodable {
    let ok: Bool
    let channels: [SlackChannel]?
    let responseMetadata: SlackResponseMetadata?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case ok, channels, error
        case responseMetadata = "response_metadata"
    }
}

struct SlackResponseMetadata: Decodable {
    let nextCursor: String?

    enum CodingKeys: String, CodingKey {
        case nextCursor = "next_cursor"
    }
}

// MARK: - Slack Message

struct SlackMessage: Identifiable, Codable, Hashable {
    let type: String?
    let user: String?
    let text: String
    let ts: String  // Timestamp = unique ID
    let threadTs: String?
    let replyCount: Int?
    let replyUsersCount: Int?
    let latestReply: String?
    let reactions: [SlackReaction]?
    let edited: SlackEdited?
    let subtype: String?
    let botId: String?
    let username: String?
    let files: [SlackFile]?
    let attachments: [SlackAttachment]?

    var id: String { ts }

    enum CodingKeys: String, CodingKey {
        case type, user, text, ts, reactions, edited, subtype, username, files, attachments
        case threadTs = "thread_ts"
        case replyCount = "reply_count"
        case replyUsersCount = "reply_users_count"
        case latestReply = "latest_reply"
        case botId = "bot_id"
    }

    var isThreadParent: Bool {
        replyCount != nil && replyCount! > 0
    }

    var isThreadReply: Bool {
        threadTs != nil && threadTs != ts
    }

    var timestamp: Date {
        let seconds = Double(ts.split(separator: ".").first ?? "") ?? 0
        return Date(timeIntervalSince1970: seconds)
    }
}

struct SlackEdited: Codable, Hashable {
    let user: String
    let ts: String
}

struct SlackReaction: Codable, Hashable {
    let name: String
    let count: Int
    let users: [String]?
}

struct SlackFile: Codable, Hashable {
    let id: String
    let name: String?
    let title: String?
    let mimetype: String?
    let filetype: String?
    let urlPrivate: String?
    let urlPrivateDownload: String?
    let permalink: String?
    let thumb64: String?
    let thumb80: String?
    let thumb360: String?

    enum CodingKeys: String, CodingKey {
        case id, name, title, mimetype, filetype, permalink
        case urlPrivate = "url_private"
        case urlPrivateDownload = "url_private_download"
        case thumb64 = "thumb_64"
        case thumb80 = "thumb_80"
        case thumb360 = "thumb_360"
    }
}

struct SlackAttachment: Codable, Hashable {
    let fallback: String?
    let color: String?
    let pretext: String?
    let authorName: String?
    let authorLink: String?
    let authorIcon: String?
    let title: String?
    let titleLink: String?
    let text: String?
    let imageUrl: String?
    let thumbUrl: String?
    let footer: String?
    let footerIcon: String?
    let ts: String?

    enum CodingKeys: String, CodingKey {
        case fallback, color, pretext, title, text, footer, ts
        case authorName = "author_name"
        case authorLink = "author_link"
        case authorIcon = "author_icon"
        case titleLink = "title_link"
        case imageUrl = "image_url"
        case thumbUrl = "thumb_url"
        case footerIcon = "footer_icon"
    }
}

// MARK: - Slack Message History Response

struct SlackMessageHistoryResponse: Decodable {
    let ok: Bool
    let messages: [SlackMessage]?
    let hasMore: Bool?
    let responseMetadata: SlackResponseMetadata?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case ok, messages, error
        case hasMore = "has_more"
        case responseMetadata = "response_metadata"
    }
}

// MARK: - Slack Thread Replies Response

struct SlackThreadRepliesResponse: Decodable {
    let ok: Bool
    let messages: [SlackMessage]?
    let hasMore: Bool?
    let responseMetadata: SlackResponseMetadata?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case ok, messages, error
        case hasMore = "has_more"
        case responseMetadata = "response_metadata"
    }
}

// MARK: - Slack User

struct SlackUser: Identifiable, Codable, Hashable {
    let id: String
    let teamId: String?
    let name: String
    let deleted: Bool?
    let realName: String?
    let tz: String?
    let tzLabel: String?
    let tzOffset: Int?
    let profile: SlackProfile
    let isAdmin: Bool?
    let isOwner: Bool?
    let isBot: Bool?
    let isAppUser: Bool?
    let updated: TimeInterval?

    enum CodingKeys: String, CodingKey {
        case id, name, deleted, tz, profile, updated
        case teamId = "team_id"
        case realName = "real_name"
        case tzLabel = "tz_label"
        case tzOffset = "tz_offset"
        case isAdmin = "is_admin"
        case isOwner = "is_owner"
        case isBot = "is_bot"
        case isAppUser = "is_app_user"
    }

    var displayName: String {
        profile.displayName?.isEmpty == false ? profile.displayName! :
        profile.realName?.isEmpty == false ? profile.realName! :
        realName ?? name
    }

    var initials: String {
        let names = displayName.split(separator: " ")
        if names.count >= 2 {
            return String(names[0].prefix(1) + names[1].prefix(1)).uppercased()
        }
        return String(displayName.prefix(2)).uppercased()
    }
}

struct SlackProfile: Codable, Hashable {
    let title: String?
    let phone: String?
    let skype: String?
    let realName: String?
    let realNameNormalized: String?
    let displayName: String?
    let displayNameNormalized: String?
    let statusText: String?
    let statusEmoji: String?
    let statusExpiration: Int?
    let avatarHash: String?
    let email: String?
    let image24: String?
    let image32: String?
    let image48: String?
    let image72: String?
    let image192: String?
    let image512: String?
    let imageOriginal: String?
    let firstName: String?
    let lastName: String?
    let team: String?

    enum CodingKeys: String, CodingKey {
        case title, phone, skype, email, team
        case realName = "real_name"
        case realNameNormalized = "real_name_normalized"
        case displayName = "display_name"
        case displayNameNormalized = "display_name_normalized"
        case statusText = "status_text"
        case statusEmoji = "status_emoji"
        case statusExpiration = "status_expiration"
        case avatarHash = "avatar_hash"
        case image24 = "image_24"
        case image32 = "image_32"
        case image48 = "image_48"
        case image72 = "image_72"
        case image192 = "image_192"
        case image512 = "image_512"
        case imageOriginal = "image_original"
        case firstName = "first_name"
        case lastName = "last_name"
    }
}

// MARK: - Slack User List Response

struct SlackUserListResponse: Decodable {
    let ok: Bool
    let members: [SlackUser]?
    let cacheTs: TimeInterval?
    let responseMetadata: SlackResponseMetadata?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case ok, members, error
        case cacheTs = "cache_ts"
        case responseMetadata = "response_metadata"
    }
}

// MARK: - Slack User Info Response

struct SlackUserInfoResponse: Decodable {
    let ok: Bool
    let user: SlackUser?
    let error: String?
}

// MARK: - Slack Conversation (DMs and Group DMs)

struct SlackConversation: Identifiable, Codable, Hashable {
    let id: String
    let isIm: Bool?
    let isMpim: Bool?
    let isPrivate: Bool?
    let user: String?  // For 1:1 DMs, the other user's ID
    let name: String?  // For MPIMs
    let created: TimeInterval?
    let isOpen: Bool?
    let lastRead: String?
    let latest: SlackMessage?
    let unreadCount: Int?
    let unreadCountDisplay: Int?

    enum CodingKeys: String, CodingKey {
        case id, user, name, created, latest
        case isIm = "is_im"
        case isMpim = "is_mpim"
        case isPrivate = "is_private"
        case isOpen = "is_open"
        case lastRead = "last_read"
        case unreadCount = "unread_count"
        case unreadCountDisplay = "unread_count_display"
    }
}

// MARK: - Slack Conversations List Response

struct SlackConversationsListResponse: Decodable {
    let ok: Bool
    let channels: [SlackConversation]?
    let responseMetadata: SlackResponseMetadata?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case ok, channels, error
        case responseMetadata = "response_metadata"
    }
}

// MARK: - Slack Conversation Open Response

struct SlackConversationOpenResponse: Decodable {
    let ok: Bool
    let channel: SlackConversationInfo?
    let error: String?
}

struct SlackConversationInfo: Codable, Hashable {
    let id: String
}

// MARK: - Slack Post Message Response

struct SlackPostMessageResponse: Decodable {
    let ok: Bool
    let channel: String?
    let ts: String?
    let message: SlackMessage?
    let error: String?
}

// MARK: - Slack Auth Test Response

struct SlackAuthTestResponse: Decodable {
    let ok: Bool
    let url: String?
    let team: String?
    let user: String?
    let teamId: String?
    let userId: String?
    let botId: String?
    let isEnterpriseInstall: Bool?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case ok, url, team, user, error
        case teamId = "team_id"
        case userId = "user_id"
        case botId = "bot_id"
        case isEnterpriseInstall = "is_enterprise_install"
    }
}

// MARK: - Slack OAuth Access Response

struct SlackOAuthAccessResponse: Decodable {
    let ok: Bool
    let accessToken: String?
    let tokenType: String?
    let scope: String?
    let botUserId: String?
    let appId: String?
    let team: SlackTeam?
    let authedUser: SlackAuthedUser?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case ok, scope, team, error
        case accessToken = "access_token"
        case tokenType = "token_type"
        case botUserId = "bot_user_id"
        case appId = "app_id"
        case authedUser = "authed_user"
    }
}

struct SlackTeam: Codable {
    let id: String
    let name: String?
}

struct SlackAuthedUser: Codable {
    let id: String
    let scope: String?
    let accessToken: String?
    let tokenType: String?

    enum CodingKeys: String, CodingKey {
        case id, scope
        case accessToken = "access_token"
        case tokenType = "token_type"
    }
}

// MARK: - Socket Mode Events

enum SlackEventType: String, Codable {
    case message
    case messageChanged = "message_changed"
    case messageDeleted = "message_deleted"
    case reactionAdded = "reaction_added"
    case reactionRemoved = "reaction_removed"
    case memberJoinedChannel = "member_joined_channel"
    case memberLeftChannel = "member_left_channel"
    case channelCreated = "channel_created"
    case channelDeleted = "channel_deleted"
    case channelArchive = "channel_archive"
    case channelUnarchive = "channel_unarchive"
    case userTyping = "user_typing"
    case presenceChange = "presence_change"
    case hello
    case unknown

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        self = SlackEventType(rawValue: value) ?? .unknown
    }
}

struct SlackSocketModeMessage: Decodable {
    let type: String
    let envelopeId: String?
    let payload: SlackEventPayload?
    let acceptsResponsePayload: Bool?

    enum CodingKeys: String, CodingKey {
        case type, payload
        case envelopeId = "envelope_id"
        case acceptsResponsePayload = "accepts_response_payload"
    }
}

struct SlackEventPayload: Decodable {
    let type: String?
    let event: SlackEvent?
    let eventId: String?
    let eventTime: TimeInterval?

    enum CodingKeys: String, CodingKey {
        case type, event
        case eventId = "event_id"
        case eventTime = "event_time"
    }
}

struct SlackEvent: Decodable {
    let type: String
    let subtype: String?
    let channel: String?
    let user: String?
    let text: String?
    let ts: String?
    let eventTs: String?
    let channelType: String?
    let threadTs: String?
    let message: SlackMessage?
    let previousMessage: SlackMessage?
    let reaction: String?
    let itemUser: String?
    let item: SlackReactionItem?

    enum CodingKeys: String, CodingKey {
        case type, subtype, channel, user, text, ts, message, reaction, item
        case eventTs = "event_ts"
        case channelType = "channel_type"
        case threadTs = "thread_ts"
        case previousMessage = "previous_message"
        case itemUser = "item_user"
    }
}

struct SlackReactionItem: Decodable {
    let type: String
    let channel: String?
    let ts: String?
}

// MARK: - Socket Mode Acknowledgment

struct SlackSocketModeAck: Encodable {
    let envelopeId: String
    let payload: [String: String]?

    enum CodingKeys: String, CodingKey {
        case envelopeId = "envelope_id"
        case payload
    }

    init(envelopeId: String) {
        self.envelopeId = envelopeId
        self.payload = nil
    }
}

// MARK: - Apps Connections Open Response

struct SlackAppsConnectionsOpenResponse: Decodable {
    let ok: Bool
    let url: String?
    let error: String?
}

// MARK: - Helper Extensions

extension SlackMessage {
    /// Convert to app's ChannelMessage format for UI compatibility
    func toChannelMessage(channelId: UUID, userCache: [String: SlackUser]) -> ChannelMessage {
        let slackUser = user.flatMap { userCache[$0] }
        let chatUser = ChatUser(
            id: UUID(),
            displayName: slackUser?.displayName ?? username ?? "Unknown",
            title: slackUser?.profile.title ?? "",
            avatarColor: "6366F1",  // Default to primary color
            isOnline: true
        )

        return ChannelMessage(
            id: UUID(),
            channelId: channelId,
            sender: chatUser,
            body: text,
            createdAt: timestamp,
            reactions: reactions?.map { reaction in
                MessageReaction(
                    emoji: reaction.name,
                    count: reaction.count,
                    userReacted: false
                )
            } ?? [],
            isEdited: edited != nil,
            threadReplyCount: replyCount ?? 0
        )
    }
}

extension SlackChannel {
    /// Convert to app's Channel format for UI compatibility
    func toAppChannel() -> Channel {
        Channel(
            id: UUID(),
            name: name,
            description: purpose?.value ?? topic?.value ?? "",
            isPrivate: isPrivate,
            memberCount: numMembers ?? 0,
            unreadCount: 0,
            createdAt: created.map { Date(timeIntervalSince1970: $0) } ?? Date()
        )
    }
}

extension SlackUser {
    /// Convert to app's ChatUser format for UI compatibility
    func toChatUser() -> ChatUser {
        ChatUser(
            id: UUID(),
            displayName: displayName,
            title: profile.title ?? "",
            avatarColor: "6366F1",  // Default to primary color
            isOnline: true
        )
    }
}

// MARK: - Slack ID Mapping

/// Stores mapping between Slack IDs and app UUIDs for cross-referencing
@MainActor
final class SlackIdMapper {
    static let shared = SlackIdMapper()

    private var channelMap: [String: UUID] = [:]
    private var userMap: [String: UUID] = [:]
    private var messageMap: [String: UUID] = [:]

    private init() {}

    func mapChannel(_ slackId: String) -> UUID {
        if let existing = channelMap[slackId] {
            return existing
        }
        let uuid = UUID()
        channelMap[slackId] = uuid
        return uuid
    }

    func mapUser(_ slackId: String) -> UUID {
        if let existing = userMap[slackId] {
            return existing
        }
        let uuid = UUID()
        userMap[slackId] = uuid
        return uuid
    }

    func mapMessage(_ slackTs: String) -> UUID {
        if let existing = messageMap[slackTs] {
            return existing
        }
        let uuid = UUID()
        messageMap[slackTs] = uuid
        return uuid
    }

    func getSlackChannelId(for uuid: UUID) -> String? {
        channelMap.first { $0.value == uuid }?.key
    }

    func getSlackUserId(for uuid: UUID) -> String? {
        userMap.first { $0.value == uuid }?.key
    }

    func getSlackMessageTs(for uuid: UUID) -> String? {
        messageMap.first { $0.value == uuid }?.key
    }
}
