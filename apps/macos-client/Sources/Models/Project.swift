import Foundation

enum ProjectStatus: String, Codable, CaseIterable {
    case planning
    case active
    case onHold = "on_hold"
    case completed
    case archived
}

enum ProjectRole: String, Codable, CaseIterable {
    case responsible
    case accountable
    case consulted
    case informed
    case follower
}

struct Project: Codable, Identifiable {
    let id: UUID
    let name: String
    let description: String?
    let status: ProjectStatus
    let startDate: Date?
    let endDate: Date?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name, description, status
        case startDate = "start_date"
        case endDate = "end_date"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct ProjectMembership: Codable, Identifiable {
    let id: UUID
    let projectId: UUID
    let userId: UUID
    let role: ProjectRole
    let joinedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, role
        case projectId = "project_id"
        case userId = "user_id"
        case joinedAt = "joined_at"
    }
}

struct Accomplishment: Codable, Identifiable {
    let id: UUID
    let projectId: UUID
    let userId: UUID
    let title: String
    let description: String?
    let weekOf: Date
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, title, description
        case projectId = "project_id"
        case userId = "user_id"
        case weekOf = "week_of"
        case createdAt = "created_at"
    }
}

struct ProjectWithRole: Codable, Identifiable {
    let id: UUID
    let name: String
    let description: String?
    let status: ProjectStatus
    let myRole: ProjectRole
    let startDate: Date?
    let endDate: Date?
    let weeklyAccomplishments: [Accomplishment]?

    enum CodingKeys: String, CodingKey {
        case id, name, description, status
        case myRole = "my_role"
        case startDate = "start_date"
        case endDate = "end_date"
        case weeklyAccomplishments = "weekly_accomplishments"
    }
}

struct WeeklyDeliverables: Codable {
    let weekOf: Date
    let projects: [ProjectWithRole]
    let totalAccomplishments: Int

    enum CodingKeys: String, CodingKey {
        case projects
        case weekOf = "week_of"
        case totalAccomplishments = "total_accomplishments"
    }
}
