import Foundation

// MARK: - Delivery Ranking

struct DeliveryRanking: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let rank: Int
    let totalUsers: Int
    let weekOf: Date
    let score: Double
    let trend: RankTrend

    enum CodingKeys: String, CodingKey {
        case id, rank, score, trend
        case userId = "user_id"
        case totalUsers = "total_users"
        case weekOf = "week_of"
    }
}

enum RankTrend: String, Codable {
    case up
    case down
    case stable
}

// MARK: - Miro Behaviors

struct MiroBehaviors: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let weekOf: Date
    let playAsTeam: Int
    let learnFirst: Int
    let deliverImpact: Int
    let launchFastIterate: Int

    var averageScore: Double {
        Double(playAsTeam + learnFirst + deliverImpact + launchFastIterate) / 4.0
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case weekOf = "week_of"
        case playAsTeam = "play_as_team"
        case learnFirst = "learn_first"
        case deliverImpact = "deliver_impact"
        case launchFastIterate = "launch_fast_iterate"
    }
}

// MARK: - AI Agents Stats

struct AIAgentsStats: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let definedAgents: Int
    let runningAgents: Int
    let tokenConsumption: TokenConsumption
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case definedAgents = "defined_agents"
        case runningAgents = "running_agents"
        case tokenConsumption = "token_consumption"
        case updatedAt = "updated_at"
    }
}

struct TokenConsumption: Codable {
    let used: Int
    let limit: Int
    let periodStart: Date
    let periodEnd: Date

    var percentUsed: Double {
        guard limit > 0 else { return 0 }
        return Double(used) / Double(limit) * 100
    }

    var formattedUsed: String {
        formatTokenCount(used)
    }

    var formattedLimit: String {
        formatTokenCount(limit)
    }

    private func formatTokenCount(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.1fK", Double(count) / 1_000)
        }
        return "\(count)"
    }

    enum CodingKeys: String, CodingKey {
        case used, limit
        case periodStart = "period_start"
        case periodEnd = "period_end"
    }
}

// MARK: - Project Phase

enum ProjectPhase: String, Codable, CaseIterable {
    case braindump
    case kickoff
    case earlyConceptReview = "early_concept_review"
    case solutionsReview = "solutions_review"
    case releaseLoop = "release_loop"

    var displayName: String {
        switch self {
        case .braindump: return "Braindump"
        case .kickoff: return "Kick-off"
        case .earlyConceptReview: return "Early Concept"
        case .solutionsReview: return "Solutions"
        case .releaseLoop: return "Release"
        }
    }

    var order: Int {
        switch self {
        case .braindump: return 0
        case .kickoff: return 1
        case .earlyConceptReview: return 2
        case .solutionsReview: return 3
        case .releaseLoop: return 4
        }
    }
}

enum ReleaseSubState: String, Codable, CaseIterable {
    case preReleaseReview = "pre_release_review"
    case postLaunchReview = "post_launch_review"
    case privateBeta = "private_beta"
    case publicBeta = "public_beta"
    case limitedAvailability = "limited_availability"
    case generalAvailability = "general_availability"
    case enterprise

    var displayName: String {
        switch self {
        case .preReleaseReview: return "Pre-release Review"
        case .postLaunchReview: return "Post Launch Review"
        case .privateBeta: return "Private Beta"
        case .publicBeta: return "Public Beta"
        case .limitedAvailability: return "Limited Availability"
        case .generalAvailability: return "GA"
        case .enterprise: return "Enterprise"
        }
    }
}

enum ProjectHealthStatus: String, Codable {
    case green
    case yellow
    case red
    case onHold = "on_hold"

    var displayName: String {
        switch self {
        case .green: return "On Track"
        case .yellow: return "At Risk"
        case .red: return "Blocked"
        case .onHold: return "On Hold"
        }
    }
}

// MARK: - Enhanced Project

struct EnhancedProject: Codable, Identifiable {
    let id: UUID
    let name: String
    let description: String?
    let healthStatus: ProjectHealthStatus
    let phase: ProjectPhase
    let releaseSubState: ReleaseSubState?
    let progressPercent: Int
    let miroUrl: URL?
    let jiraUrl: URL?
    let myRole: ProjectRole
    let startDate: Date?
    let targetDate: Date?
    let teamSize: Int
    let weeklyAccomplishments: [Accomplishment]?
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name, description, phase
        case healthStatus = "health_status"
        case releaseSubState = "release_sub_state"
        case progressPercent = "progress_percent"
        case miroUrl = "miro_url"
        case jiraUrl = "jira_url"
        case myRole = "my_role"
        case startDate = "start_date"
        case targetDate = "target_date"
        case teamSize = "team_size"
        case weeklyAccomplishments = "weekly_accomplishments"
        case updatedAt = "updated_at"
    }
}

// MARK: - Deliver Dashboard

struct DeliverDashboard: Codable {
    let ranking: DeliveryRanking
    let behaviors: MiroBehaviors
    let aiAgents: AIAgentsStats
    let projects: [EnhancedProject]

    enum CodingKeys: String, CodingKey {
        case ranking, behaviors, projects
        case aiAgents = "ai_agents"
    }
}
