import Foundation

enum ContentType: String, Codable {
    case text
    case video
    case audio
}

enum SharingPolicy: String, Codable {
    case internalOnly = "internal_only"
    case externalAllowed = "external_allowed"
}

struct Content: Codable, Identifiable {
    let id: UUID
    let authorId: UUID
    let contentType: ContentType
    let title: String?
    let body: String?
    let mediaUrl: String?
    let thumbnailUrl: String?
    let durationSeconds: Int?
    let isCompanyImportant: Bool
    let sharingPolicy: SharingPolicy
    let commentsEnabled: Bool
    let targetRoles: [String]?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, title, body
        case authorId = "author_id"
        case contentType = "content_type"
        case mediaUrl = "media_url"
        case thumbnailUrl = "thumbnail_url"
        case durationSeconds = "duration_seconds"
        case isCompanyImportant = "is_company_important"
        case sharingPolicy = "sharing_policy"
        case commentsEnabled = "comments_enabled"
        case targetRoles = "target_roles"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct ContentFeedItem: Codable, Identifiable {
    let id: UUID
    let author: UserPublic
    let contentType: ContentType
    let title: String?
    let body: String?
    let mediaUrl: String?
    let thumbnailUrl: String?
    let durationSeconds: Int?
    let isCompanyImportant: Bool
    let tags: [Tag]
    let likeCount: Int
    let commentCount: Int
    let isLiked: Bool
    let isBookmarked: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, author, title, body, tags
        case contentType = "content_type"
        case mediaUrl = "media_url"
        case thumbnailUrl = "thumbnail_url"
        case durationSeconds = "duration_seconds"
        case isCompanyImportant = "is_company_important"
        case likeCount = "like_count"
        case commentCount = "comment_count"
        case isLiked = "is_liked"
        case isBookmarked = "is_bookmarked"
        case createdAt = "created_at"
    }
}

struct FeedResponse: Codable {
    let items: [ContentFeedItem]
    let nextCursor: String?
    let hasMore: Bool

    enum CodingKeys: String, CodingKey {
        case items
        case nextCursor = "next_cursor"
        case hasMore = "has_more"
    }
}

struct ContentCreate: Encodable {
    let contentType: ContentType
    let title: String?
    let body: String?
    let mediaUrl: String?
    let thumbnailUrl: String?
    let durationSeconds: Int?
    let isCompanyImportant: Bool
    let sharingPolicy: SharingPolicy
    let commentsEnabled: Bool
    let targetRoles: [String]?
    let tagIds: [UUID]?

    enum CodingKeys: String, CodingKey {
        case title, body
        case contentType = "content_type"
        case mediaUrl = "media_url"
        case thumbnailUrl = "thumbnail_url"
        case durationSeconds = "duration_seconds"
        case isCompanyImportant = "is_company_important"
        case sharingPolicy = "sharing_policy"
        case commentsEnabled = "comments_enabled"
        case targetRoles = "target_roles"
        case tagIds = "tag_ids"
    }
}
