import Foundation

extension DeliverDashboard {
    static var mockData: DeliverDashboard {
        DeliverDashboard(
            ranking: DeliveryRanking(
                id: UUID(),
                userId: UUID(),
                rank: 1,
                totalUsers: 1826,
                weekOf: Date(),
                score: 94.5,
                trend: .up
            ),
            behaviors: MiroBehaviors(
                id: UUID(),
                userId: UUID(),
                weekOf: Date(),
                playAsTeam: 5,
                learnFirst: 4,
                deliverImpact: 5,
                launchFastIterate: 4
            ),
            aiAgents: AIAgentsStats(
                id: UUID(),
                userId: UUID(),
                definedAgents: 7,
                runningAgents: 3,
                tokenConsumption: TokenConsumption(
                    used: 2_450_000,
                    limit: 5_000_000,
                    periodStart: Calendar.current.date(byAdding: .day, value: -15, to: Date())!,
                    periodEnd: Calendar.current.date(byAdding: .day, value: 15, to: Date())!
                ),
                updatedAt: Date()
            ),
            projects: [
                EnhancedProject(
                    id: UUID(),
                    name: "Pulsync Mobile App",
                    description: "Cross-platform mobile application for iOS and Android with real-time sync and offline capabilities",
                    healthStatus: .green,
                    phase: .braindump,
                    releaseSubState: .privateBeta,
                    progressPercent: 78,
                    miroUrl: URL(string: "https://miro.com/app/board/uXjVPDx123="),
                    jiraUrl: URL(string: "https://jira.atlassian.com/browse/PULSYNC"),
                    myRole: .responsible,
                    startDate: Calendar.current.date(byAdding: .month, value: -3, to: Date()),
                    targetDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()),
                    teamSize: 8,
                    weeklyAccomplishments: [
                        Accomplishment(
                            id: UUID(),
                            projectId: UUID(),
                            userId: UUID(),
                            title: "Implemented offline sync with SQLite",
                            description: "Added local storage with conflict resolution",
                            weekOf: Date(),
                            createdAt: Date()
                        ),
                        Accomplishment(
                            id: UUID(),
                            projectId: UUID(),
                            userId: UUID(),
                            title: "Fixed push notification issues on iOS",
                            description: nil,
                            weekOf: Date(),
                            createdAt: Date()
                        )
                    ],
                    updatedAt: Date()
                ),
                EnhancedProject(
                    id: UUID(),
                    name: "AI Assistant Integration",
                    description: "Integrate Claude AI for intelligent workspace assistance, automation, and smart suggestions",
                    healthStatus: .yellow,
                    phase: .solutionsReview,
                    releaseSubState: nil,
                    progressPercent: 45,
                    miroUrl: URL(string: "https://miro.com/app/board/uXjVPDx456="),
                    jiraUrl: nil,
                    myRole: .accountable,
                    startDate: Calendar.current.date(byAdding: .month, value: -1, to: Date()),
                    targetDate: Calendar.current.date(byAdding: .month, value: 2, to: Date()),
                    teamSize: 4,
                    weeklyAccomplishments: [
                        Accomplishment(
                            id: UUID(),
                            projectId: UUID(),
                            userId: UUID(),
                            title: "Defined prompt engineering guidelines",
                            description: nil,
                            weekOf: Date(),
                            createdAt: Date()
                        )
                    ],
                    updatedAt: Date()
                ),
                EnhancedProject(
                    id: UUID(),
                    name: "Design System v2.0",
                    description: "Complete overhaul of component library with Miro-inspired playful aesthetics and dark mode support",
                    healthStatus: .red,
                    phase: .earlyConceptReview,
                    releaseSubState: nil,
                    progressPercent: 25,
                    miroUrl: URL(string: "https://miro.com/app/board/uXjVPDx789="),
                    jiraUrl: URL(string: "https://jira.atlassian.com/browse/DS2"),
                    myRole: .consulted,
                    startDate: Calendar.current.date(byAdding: .day, value: -14, to: Date()),
                    targetDate: nil,
                    teamSize: 3,
                    weeklyAccomplishments: nil,
                    updatedAt: Date()
                ),
                EnhancedProject(
                    id: UUID(),
                    name: "Infrastructure Migration",
                    description: "Migrate from AWS to multi-cloud setup with Kubernetes orchestration",
                    healthStatus: .onHold,
                    phase: .kickoff,
                    releaseSubState: nil,
                    progressPercent: 10,
                    miroUrl: nil,
                    jiraUrl: URL(string: "https://jira.atlassian.com/browse/INFRA"),
                    myRole: .informed,
                    startDate: Calendar.current.date(byAdding: .month, value: -2, to: Date()),
                    targetDate: nil,
                    teamSize: 6,
                    weeklyAccomplishments: nil,
                    updatedAt: Date()
                ),
                EnhancedProject(
                    id: UUID(),
                    name: "Analytics Dashboard",
                    description: "Real-time analytics and reporting dashboard for business intelligence",
                    healthStatus: .green,
                    phase: .releaseLoop,
                    releaseSubState: .generalAvailability,
                    progressPercent: 95,
                    miroUrl: URL(string: "https://miro.com/app/board/uXjVPDxABC="),
                    jiraUrl: URL(string: "https://jira.atlassian.com/browse/ANALYTICS"),
                    myRole: .follower,
                    startDate: Calendar.current.date(byAdding: .month, value: -6, to: Date()),
                    targetDate: Calendar.current.date(byAdding: .day, value: -7, to: Date()),
                    teamSize: 5,
                    weeklyAccomplishments: [
                        Accomplishment(
                            id: UUID(),
                            projectId: UUID(),
                            userId: UUID(),
                            title: "Launched to all enterprise customers",
                            description: nil,
                            weekOf: Date(),
                            createdAt: Date()
                        )
                    ],
                    updatedAt: Date()
                ),
                EnhancedProject(
                    id: UUID(),
                    name: "Security Audit Q1",
                    description: "Comprehensive security audit and penetration testing for SOC2 compliance",
                    healthStatus: .yellow,
                    phase: .braindump,
                    releaseSubState: nil,
                    progressPercent: 5,
                    miroUrl: URL(string: "https://miro.com/app/board/uXjVPDxDEF="),
                    jiraUrl: nil,
                    myRole: .consulted,
                    startDate: Date(),
                    targetDate: Calendar.current.date(byAdding: .month, value: 3, to: Date()),
                    teamSize: 2,
                    weeklyAccomplishments: nil,
                    updatedAt: Date()
                )
            ]
        )
    }
}
