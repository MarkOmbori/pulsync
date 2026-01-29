import Foundation

enum OutcomeStatus: String, Codable, CaseIterable {
    case todo
    case inProgress = "in_progress"
    case done
}

enum OutcomeType: String, Codable {
    case task
    case meeting
}

struct Outcome: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let type: OutcomeType
    let title: String
    let description: String?
    let howToAccomplish: String?
    let status: OutcomeStatus
    let dueDate: Date?
    let meetingTime: Date?
    let meetingParticipants: [String]?
    let meetingAgenda: String?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, type, title, description, status
        case userId = "user_id"
        case howToAccomplish = "how_to_accomplish"
        case dueDate = "due_date"
        case meetingTime = "meeting_time"
        case meetingParticipants = "meeting_participants"
        case meetingAgenda = "meeting_agenda"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct OutcomeCreate: Encodable {
    let type: OutcomeType
    let title: String
    let description: String?
    let howToAccomplish: String?
    let dueDate: Date?
    let meetingTime: Date?
    let meetingParticipants: [String]?
    let meetingAgenda: String?

    enum CodingKeys: String, CodingKey {
        case type, title, description
        case howToAccomplish = "how_to_accomplish"
        case dueDate = "due_date"
        case meetingTime = "meeting_time"
        case meetingParticipants = "meeting_participants"
        case meetingAgenda = "meeting_agenda"
    }
}

struct OutcomeUpdate: Encodable {
    let title: String?
    let description: String?
    let howToAccomplish: String?
    let status: OutcomeStatus?
    let dueDate: Date?
    let meetingTime: Date?
    let meetingParticipants: [String]?
    let meetingAgenda: String?

    enum CodingKeys: String, CodingKey {
        case title, description, status
        case howToAccomplish = "how_to_accomplish"
        case dueDate = "due_date"
        case meetingTime = "meeting_time"
        case meetingParticipants = "meeting_participants"
        case meetingAgenda = "meeting_agenda"
    }
}
