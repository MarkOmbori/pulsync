import Foundation

struct Comment: Codable, Identifiable {
    let id: UUID
    let contentId: UUID
    let authorId: UUID
    let parentId: UUID?
    let body: String
    let createdAt: Date
    let updatedAt: Date
    let author: UserPublic
    let replyCount: Int

    enum CodingKeys: String, CodingKey {
        case id, body, author
        case contentId = "content_id"
        case authorId = "author_id"
        case parentId = "parent_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case replyCount = "reply_count"
    }
}

struct CommentCreate: Encodable {
    let body: String
    let parentId: UUID?

    enum CodingKeys: String, CodingKey {
        case body
        case parentId = "parent_id"
    }
}
