import Foundation

enum UserRole: String, Codable, CaseIterable {
    case engineering
    case hr
    case marketing
    case comms
    case executive
}

struct User: Codable, Identifiable {
    let id: UUID
    let email: String
    let displayName: String
    let avatarUrl: String?
    let role: UserRole
    let department: String
    let isCommsTeam: Bool

    enum CodingKeys: String, CodingKey {
        case id, email, role, department
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case isCommsTeam = "is_comms_team"
    }
}

struct UserPublic: Codable, Identifiable {
    let id: UUID
    let displayName: String
    let avatarUrl: String?
    let role: UserRole
    let department: String

    enum CodingKeys: String, CodingKey {
        case id, role, department
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
    }
}
