import Foundation

// MARK: - Mock Chat Data

enum MockChatData {
    // MARK: - Mock Users (10 employees)

    static let users: [ChatUser] = [
        ChatUser(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            displayName: "Jennifer Walsh",
            title: "CEO",
            avatarColor: "6366F1",
            isOnline: true
        ),
        ChatUser(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            displayName: "Michael Torres",
            title: "CTO",
            avatarColor: "14B8A6",
            isOnline: true
        ),
        ChatUser(
            id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
            displayName: "Sarah Chen",
            title: "Engineering Manager",
            avatarColor: "F59E0B",
            isOnline: true
        ),
        ChatUser(
            id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
            displayName: "Marcus Johnson",
            title: "Senior Developer",
            avatarColor: "EF4444",
            isOnline: true
        ),
        ChatUser(
            id: UUID(uuidString: "55555555-5555-5555-5555-555555555555")!,
            displayName: "Priya Patel",
            title: "Frontend Engineer",
            avatarColor: "8B5CF6",
            isOnline: false
        ),
        ChatUser(
            id: UUID(uuidString: "66666666-6666-6666-6666-666666666666")!,
            displayName: "Alex Kim",
            title: "DevOps Engineer",
            avatarColor: "EC4899",
            isOnline: true
        ),
        ChatUser(
            id: UUID(uuidString: "77777777-7777-7777-7777-777777777777")!,
            displayName: "David Miller",
            title: "Product Manager",
            avatarColor: "3B82F6",
            isOnline: false
        ),
        ChatUser(
            id: UUID(uuidString: "88888888-8888-8888-8888-888888888888")!,
            displayName: "Emily Rodriguez",
            title: "Senior Designer",
            avatarColor: "22C55E",
            isOnline: true
        ),
        ChatUser(
            id: UUID(uuidString: "99999999-9999-9999-9999-999999999999")!,
            displayName: "Lisa Thompson",
            title: "HR Director",
            avatarColor: "F97316",
            isOnline: false
        ),
        ChatUser(
            id: UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!,
            displayName: "James Wilson",
            title: "Operations Manager",
            avatarColor: "06B6D4",
            isOnline: true
        ),
    ]

    // Convenience accessors
    static var jennifer: ChatUser { users[0] }
    static var michael: ChatUser { users[1] }
    static var sarah: ChatUser { users[2] }
    static var marcus: ChatUser { users[3] }
    static var priya: ChatUser { users[4] }
    static var alex: ChatUser { users[5] }
    static var david: ChatUser { users[6] }
    static var emily: ChatUser { users[7] }
    static var lisa: ChatUser { users[8] }
    static var james: ChatUser { users[9] }

    // Current user (for demo purposes)
    static var currentUser: ChatUser { marcus }

    // MARK: - Channels (6 total)

    static let channels: [Channel] = [
        Channel(
            id: UUID(uuidString: "C1111111-1111-1111-1111-111111111111")!,
            name: "general",
            description: "Company-wide announcements and discussions",
            isPrivate: false,
            memberCount: 47,
            unreadCount: 3,
            createdAt: Date().addingTimeInterval(-86400 * 365)
        ),
        Channel(
            id: UUID(uuidString: "C2222222-2222-2222-2222-222222222222")!,
            name: "engineering",
            description: "Technical discussions, code reviews, and architecture",
            isPrivate: false,
            memberCount: 15,
            unreadCount: 0,
            createdAt: Date().addingTimeInterval(-86400 * 300)
        ),
        Channel(
            id: UUID(uuidString: "C3333333-3333-3333-3333-333333333333")!,
            name: "random",
            description: "Non-work banter and watercooler conversation",
            isPrivate: false,
            memberCount: 42,
            unreadCount: 7,
            createdAt: Date().addingTimeInterval(-86400 * 350)
        ),
        Channel(
            id: UUID(uuidString: "C4444444-4444-4444-4444-444444444444")!,
            name: "announcements",
            description: "Official company news and updates",
            isPrivate: false,
            memberCount: 52,
            unreadCount: 1,
            createdAt: Date().addingTimeInterval(-86400 * 365)
        ),
        Channel(
            id: UUID(uuidString: "C5555555-5555-5555-5555-555555555555")!,
            name: "design",
            description: "Design feedback, assets, and UI/UX discussions",
            isPrivate: false,
            memberCount: 12,
            unreadCount: 0,
            createdAt: Date().addingTimeInterval(-86400 * 200)
        ),
        Channel(
            id: UUID(uuidString: "C6666666-6666-6666-6666-666666666666")!,
            name: "product",
            description: "Product roadmap, feature requests, and priorities",
            isPrivate: false,
            memberCount: 18,
            unreadCount: 2,
            createdAt: Date().addingTimeInterval(-86400 * 250)
        ),
    ]

    // MARK: - Direct Messages

    static let directMessages: [DirectMessage] = [
        DirectMessage(
            id: UUID(),
            participant: sarah,
            lastMessage: "Can you review my PR when you get a chance?",
            lastMessageAt: Date().addingTimeInterval(-1800),
            unreadCount: 1
        ),
        DirectMessage(
            id: UUID(),
            participant: michael,
            lastMessage: "Great work on the deployment!",
            lastMessageAt: Date().addingTimeInterval(-7200),
            unreadCount: 0
        ),
        DirectMessage(
            id: UUID(),
            participant: emily,
            lastMessage: "I'll send over the updated mockups",
            lastMessageAt: Date().addingTimeInterval(-14400),
            unreadCount: 0
        ),
        DirectMessage(
            id: UUID(),
            participant: alex,
            lastMessage: "Pipeline is all green now",
            lastMessageAt: Date().addingTimeInterval(-28800),
            unreadCount: 0
        ),
        DirectMessage(
            id: UUID(),
            participant: david,
            lastMessage: "Let's sync on the roadmap tomorrow",
            lastMessageAt: Date().addingTimeInterval(-43200),
            unreadCount: 0
        ),
    ]

    // MARK: - Channel Messages

    static func messages(for channelId: UUID) -> [ChannelMessage] {
        switch channelId {
        case channels[0].id: // #general
            return generalMessages
        case channels[1].id: // #engineering
            return engineeringMessages
        case channels[2].id: // #random
            return randomMessages
        case channels[3].id: // #announcements
            return announcementsMessages
        case channels[4].id: // #design
            return designMessages
        case channels[5].id: // #product
            return productMessages
        default:
            return []
        }
    }

    // MARK: - #general Messages

    private static let generalMessages: [ChannelMessage] = [
        ChannelMessage(
            channelId: channels[0].id,
            sender: jennifer,
            body: "Great work on the Q4 launch everyone! Team dinner Friday at 7pm - details in the calendar invite",
            createdAt: Date().addingTimeInterval(-3600),
            reactions: [
                MessageReaction(emoji: "🎉", count: 12, userReacted: true),
                MessageReaction(emoji: "🙌", count: 8),
                MessageReaction(emoji: "❤️", count: 5),
            ]
        ),
        ChannelMessage(
            channelId: channels[0].id,
            sender: lisa,
            body: "Reminder: Benefits enrollment deadline is next Friday. Please complete your selections in the HR portal.",
            createdAt: Date().addingTimeInterval(-7200),
            reactions: [
                MessageReaction(emoji: "👍", count: 6),
            ]
        ),
        ChannelMessage(
            channelId: channels[0].id,
            sender: james,
            body: "The conference room booking system will be down for maintenance this Saturday 8am-12pm",
            createdAt: Date().addingTimeInterval(-14400)
        ),
        ChannelMessage(
            channelId: channels[0].id,
            sender: sarah,
            body: "Reminder: Engineering sync at 2pm today. We'll be discussing the new architecture proposal.",
            createdAt: Date().addingTimeInterval(-18000),
            reactions: [
                MessageReaction(emoji: "✅", count: 4),
            ]
        ),
        ChannelMessage(
            channelId: channels[0].id,
            sender: david,
            body: "Product roadmap for Q1 is now live in Notion. Please review and add comments by EOD Thursday.",
            createdAt: Date().addingTimeInterval(-28800),
            reactions: [
                MessageReaction(emoji: "👀", count: 8),
            ]
        ),
    ]

    // MARK: - #engineering Messages

    private static let engineeringMessages: [ChannelMessage] = [
        ChannelMessage(
            channelId: channels[1].id,
            sender: marcus,
            body: "PR #234 is ready for review - fixed the auth race condition that was causing intermittent login failures",
            createdAt: Date().addingTimeInterval(-1800),
            reactions: [
                MessageReaction(emoji: "👀", count: 2),
            ],
            threadReplyCount: 3
        ),
        ChannelMessage(
            channelId: channels[1].id,
            sender: sarah,
            body: "Just merged the new caching layer. Performance benchmarks show 40% improvement on cold starts 🚀",
            createdAt: Date().addingTimeInterval(-5400),
            reactions: [
                MessageReaction(emoji: "🔥", count: 7),
                MessageReaction(emoji: "💪", count: 4),
            ]
        ),
        ChannelMessage(
            channelId: channels[1].id,
            sender: alex,
            body: "Heads up: Deploying the new monitoring stack to staging at 3pm. There might be brief alert noise.",
            createdAt: Date().addingTimeInterval(-10800)
        ),
        ChannelMessage(
            channelId: channels[1].id,
            sender: priya,
            body: "Anyone else seeing flaky tests in the auth module? CI passed but I'm getting failures locally.",
            createdAt: Date().addingTimeInterval(-14400),
            threadReplyCount: 5
        ),
        ChannelMessage(
            channelId: channels[1].id,
            sender: michael,
            body: "Quick reminder: We're adopting the new code review guidelines starting Monday. Docs are in the wiki.",
            createdAt: Date().addingTimeInterval(-21600),
            reactions: [
                MessageReaction(emoji: "📝", count: 3),
            ]
        ),
        ChannelMessage(
            channelId: channels[1].id,
            sender: marcus,
            body: "Found a really useful article on optimizing SwiftUI performance. Sharing in thread.",
            createdAt: Date().addingTimeInterval(-28800),
            threadReplyCount: 2
        ),
    ]

    // MARK: - #random Messages

    private static let randomMessages: [ChannelMessage] = [
        ChannelMessage(
            channelId: channels[2].id,
            sender: alex,
            body: "Just found out there's a taco truck parked outside. This is not a drill. 🌮",
            createdAt: Date().addingTimeInterval(-900),
            reactions: [
                MessageReaction(emoji: "🌮", count: 15),
                MessageReaction(emoji: "🏃", count: 8),
                MessageReaction(emoji: "🤤", count: 6),
            ]
        ),
        ChannelMessage(
            channelId: channels[2].id,
            sender: emily,
            body: "Anyone want to join a board game night this weekend? Thinking Saturday around 6pm",
            createdAt: Date().addingTimeInterval(-3600),
            reactions: [
                MessageReaction(emoji: "🎲", count: 4),
                MessageReaction(emoji: "✋", count: 7),
            ],
            threadReplyCount: 8
        ),
        ChannelMessage(
            channelId: channels[2].id,
            sender: james,
            body: "TIL that octopuses have three hearts. Now I can't stop thinking about it.",
            createdAt: Date().addingTimeInterval(-7200),
            reactions: [
                MessageReaction(emoji: "🐙", count: 9),
                MessageReaction(emoji: "❤️❤️❤️", count: 3),
            ]
        ),
        ChannelMessage(
            channelId: channels[2].id,
            sender: priya,
            body: "My cat just walked across my keyboard and somehow fixed a bug. Should I put her on the payroll?",
            createdAt: Date().addingTimeInterval(-14400),
            reactions: [
                MessageReaction(emoji: "😂", count: 18),
                MessageReaction(emoji: "🐱", count: 11),
                MessageReaction(emoji: "💰", count: 5),
            ]
        ),
        ChannelMessage(
            channelId: channels[2].id,
            sender: lisa,
            body: "Happy Friday everyone! 🎉 What's everyone's weekend plans?",
            createdAt: Date().addingTimeInterval(-21600),
            threadReplyCount: 12
        ),
    ]

    // MARK: - #announcements Messages

    private static let announcementsMessages: [ChannelMessage] = [
        ChannelMessage(
            channelId: channels[3].id,
            sender: jennifer,
            body: "Excited to announce that we've closed our Series B funding! More details in the all-hands meeting tomorrow at 10am. This is a huge milestone for the team.",
            createdAt: Date().addingTimeInterval(-7200),
            reactions: [
                MessageReaction(emoji: "🚀", count: 42),
                MessageReaction(emoji: "🎉", count: 38),
                MessageReaction(emoji: "💪", count: 25),
            ]
        ),
        ChannelMessage(
            channelId: channels[3].id,
            sender: lisa,
            body: "📢 New PTO policy update: We're moving to unlimited PTO starting next quarter. Full details in the HR portal.",
            createdAt: Date().addingTimeInterval(-86400),
            reactions: [
                MessageReaction(emoji: "🙌", count: 35),
                MessageReaction(emoji: "❤️", count: 20),
            ]
        ),
        ChannelMessage(
            channelId: channels[3].id,
            sender: michael,
            body: "Welcome our newest team members joining this week: Alex Kim (DevOps), and Emily Rodriguez (Design). Please say hi! 👋",
            createdAt: Date().addingTimeInterval(-172800),
            reactions: [
                MessageReaction(emoji: "👋", count: 30),
                MessageReaction(emoji: "🎉", count: 22),
            ]
        ),
    ]

    // MARK: - #design Messages

    private static let designMessages: [ChannelMessage] = [
        ChannelMessage(
            channelId: channels[4].id,
            sender: emily,
            body: "Updated mockups for the dashboard redesign are in Figma. Looking for feedback on the new navigation pattern.",
            createdAt: Date().addingTimeInterval(-5400),
            reactions: [
                MessageReaction(emoji: "👀", count: 4),
            ],
            threadReplyCount: 6
        ),
        ChannelMessage(
            channelId: channels[4].id,
            sender: david,
            body: "Love the new direction! Quick question - can we explore a darker theme variant for the settings page?",
            createdAt: Date().addingTimeInterval(-10800)
        ),
        ChannelMessage(
            channelId: channels[4].id,
            sender: emily,
            body: "Working on the icon set updates. Here's a preview of the new style:",
            createdAt: Date().addingTimeInterval(-21600),
            reactions: [
                MessageReaction(emoji: "🔥", count: 6),
                MessageReaction(emoji: "😍", count: 4),
            ]
        ),
        ChannelMessage(
            channelId: channels[4].id,
            sender: priya,
            body: "The new button component looks great in production! Thanks Emily 🙏",
            createdAt: Date().addingTimeInterval(-43200),
            reactions: [
                MessageReaction(emoji: "💜", count: 3),
            ]
        ),
    ]

    // MARK: - #product Messages

    private static let productMessages: [ChannelMessage] = [
        ChannelMessage(
            channelId: channels[5].id,
            sender: david,
            body: "Sprint planning for next week is scheduled for Monday 10am. Please have your estimates ready.",
            createdAt: Date().addingTimeInterval(-3600),
            reactions: [
                MessageReaction(emoji: "👍", count: 5),
            ]
        ),
        ChannelMessage(
            channelId: channels[5].id,
            sender: sarah,
            body: "Can we prioritize the API rate limiting feature? We're getting more enterprise interest.",
            createdAt: Date().addingTimeInterval(-10800),
            threadReplyCount: 4
        ),
        ChannelMessage(
            channelId: channels[5].id,
            sender: michael,
            body: "Good call Sarah. Let's discuss trade-offs in the planning meeting. @david can you add it to the agenda?",
            createdAt: Date().addingTimeInterval(-14400)
        ),
        ChannelMessage(
            channelId: channels[5].id,
            sender: david,
            body: "Added! Also including the mobile push notification feature request from the customer feedback.",
            createdAt: Date().addingTimeInterval(-18000),
            reactions: [
                MessageReaction(emoji: "✅", count: 3),
            ]
        ),
        ChannelMessage(
            channelId: channels[5].id,
            sender: jennifer,
            body: "Great alignment everyone. Remember to keep user value at the center of our decisions.",
            createdAt: Date().addingTimeInterval(-28800),
            reactions: [
                MessageReaction(emoji: "💯", count: 8),
            ]
        ),
    ]
}
