import Foundation

/// AI message for the Slack assistant conversation
struct AISlackMessage: Identifiable, Equatable {
    let id: UUID
    let role: AISlackMessageRole
    let content: String
    let timestamp: Date
    var slackContext: SlackContextSummary?

    init(role: AISlackMessageRole, content: String, slackContext: SlackContextSummary? = nil) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.timestamp = Date()
        self.slackContext = slackContext
    }
}

enum AISlackMessageRole: String, Equatable {
    case user
    case assistant
    case system
}

/// Summary of Slack context used for a query
struct SlackContextSummary: Equatable {
    let channelNames: [String]
    let userNames: [String]
    let messageCount: Int
    let dateRange: String?
}

/// Context gathered from Slack for AI queries
struct SlackContext {
    var currentChannel: SlackChannel?
    var recentMessages: [SlackMessage]
    var mentionedUsers: [SlackUser]
    var threadContext: [SlackMessage]?
    var searchResults: [SlackMessage]?

    init() {
        self.recentMessages = []
        self.mentionedUsers = []
    }

    var summary: SlackContextSummary {
        let channelNames = currentChannel.map { [$0.name] } ?? []
        let userNames = mentionedUsers.map { $0.displayName }
        let messageCount = recentMessages.count + (threadContext?.count ?? 0) + (searchResults?.count ?? 0)

        var dateRange: String? = nil
        let allMessages = recentMessages + (threadContext ?? []) + (searchResults ?? [])
        if let oldest = allMessages.map({ $0.timestamp }).min(),
           let newest = allMessages.map({ $0.timestamp }).max() {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            dateRange = "\(formatter.string(from: oldest)) - \(formatter.string(from: newest))"
        }

        return SlackContextSummary(
            channelNames: channelNames,
            userNames: userNames,
            messageCount: messageCount,
            dateRange: dateRange
        )
    }
}

/// Claude-powered AI assistant with Slack context awareness
@MainActor
@Observable
class ClaudeSlackAssistant {
    // MARK: - Published State

    /// Conversation history with the assistant
    var messages: [AISlackMessage] = []

    /// Whether the assistant is processing a query
    var isProcessing = false

    /// Current streaming content
    var streamingContent = ""

    /// Error message if something went wrong
    var error: String?

    /// Whether to show the response area
    var isExpanded = false

    // MARK: - Dependencies

    private let slackClient: SlackAPIClient
    private let anthropicAPIKey: String?

    // Storage for Claude API
    private let baseURL = "https://api.anthropic.com/v1/messages"
    private let model = "claude-sonnet-4-20250514"

    // MARK: - Initialization

    init(slackClient: SlackAPIClient = .shared) {
        self.slackClient = slackClient
        self.anthropicAPIKey = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"]
    }

    // MARK: - Public Methods

    /// Ask a question about Slack with context-aware responses
    func ask(_ question: String, currentChannel: SlackChannel? = nil) async throws -> String {
        guard !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return ""
        }

        isProcessing = true
        streamingContent = ""
        error = nil
        isExpanded = true

        // Add user message to history
        messages.append(AISlackMessage(role: .user, content: question))

        do {
            // Gather relevant Slack context
            let context = try await gatherContext(for: question, currentChannel: currentChannel)

            // Build the prompt with Slack data
            let systemPrompt = buildSystemPrompt()
            let userPrompt = buildUserPrompt(question: question, slackContext: context)

            // Call Claude API (non-streaming for now)
            let response = try await callClaude(systemPrompt: systemPrompt, userPrompt: userPrompt)

            // Add assistant message with context summary
            let assistantMessage = AISlackMessage(
                role: .assistant,
                content: response,
                slackContext: context.summary
            )
            messages.append(assistantMessage)

            streamingContent = response
            isProcessing = false

            return response
        } catch {
            self.error = error.localizedDescription
            isProcessing = false
            throw error
        }
    }

    /// Ask a question with streaming response
    func askStreaming(_ question: String, currentChannel: SlackChannel? = nil) async throws {
        guard !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        isProcessing = true
        streamingContent = ""
        error = nil
        isExpanded = true

        // Add user message to history
        messages.append(AISlackMessage(role: .user, content: question))

        do {
            // Gather relevant Slack context
            let context = try await gatherContext(for: question, currentChannel: currentChannel)

            // Build prompts
            let systemPrompt = buildSystemPrompt()
            let userPrompt = buildUserPrompt(question: question, slackContext: context)

            // Stream response from Claude
            try await streamFromClaude(systemPrompt: systemPrompt, userPrompt: userPrompt)

            // Add final assistant message
            let assistantMessage = AISlackMessage(
                role: .assistant,
                content: streamingContent,
                slackContext: context.summary
            )
            messages.append(assistantMessage)

            isProcessing = false
        } catch {
            self.error = error.localizedDescription
            isProcessing = false
            throw error
        }
    }

    /// Clear the conversation history
    func clearHistory() {
        messages.removeAll()
        streamingContent = ""
        error = nil
        isExpanded = false
    }

    /// Collapse the response area
    func collapse() {
        isExpanded = false
    }

    /// Toggle expanded state
    func toggleExpanded() {
        isExpanded.toggle()
    }

    // MARK: - Context Gathering

    private func gatherContext(for question: String, currentChannel: SlackChannel?) async throws -> SlackContext {
        var context = SlackContext()
        context.currentChannel = currentChannel

        // Analyze the question to determine what context to fetch
        let lowercased = question.lowercased()

        // If asking about a specific channel
        if let channelMatch = extractChannelMention(from: question) {
            // Try to find the channel
            let channels = try await slackClient.listChannels()
            if let channel = channels.channels.first(where: {
                $0.name.lowercased() == channelMatch.lowercased()
            }) {
                context.currentChannel = channel
            }
        }

        // Fetch recent messages from the relevant channel
        if let channel = context.currentChannel {
            let (messages, _, _) = try await slackClient.getChannelHistory(
                channelId: channel.id,
                limit: determineMessageLimit(for: question)
            )
            context.recentMessages = messages

            // Prefetch user info for message authors
            let userIds = Set(messages.compactMap { $0.user })
            await slackClient.prefetchUsers(userIds: Array(userIds))

            // Add user info to context
            context.mentionedUsers = userIds.compactMap { slackClient.userCache[$0] }
        }

        // If asking about a specific person, search for their messages
        if let personName = extractPersonMention(from: question) {
            // Search for the user
            let (users, _) = try await slackClient.listUsers(limit: 100)
            if let user = users.first(where: {
                $0.displayName.lowercased().contains(personName.lowercased()) ||
                $0.name.lowercased().contains(personName.lowercased()) ||
                ($0.realName?.lowercased().contains(personName.lowercased()) ?? false)
            }) {
                context.mentionedUsers.append(user)

                // If we have a channel, filter messages from this user
                context.recentMessages = context.recentMessages.filter { $0.user == user.id }
            }
        }

        // If asking about "today" or time-related queries
        if lowercased.contains("today") || lowercased.contains("yesterday") || lowercased.contains("this week") {
            // Messages are already sorted by timestamp from Slack API (newest first)
            // Filter based on time if needed
            let calendar = Calendar.current

            if lowercased.contains("today") {
                context.recentMessages = context.recentMessages.filter {
                    calendar.isDateInToday($0.timestamp)
                }
            } else if lowercased.contains("yesterday") {
                context.recentMessages = context.recentMessages.filter {
                    calendar.isDateInYesterday($0.timestamp)
                }
            }
        }

        // If asking to search, use Slack search API
        if lowercased.contains("search") || lowercased.contains("find") {
            let searchQuery = extractSearchQuery(from: question)
            if !searchQuery.isEmpty {
                let results = try await slackClient.searchMessages(query: searchQuery, count: 10)
                context.searchResults = results
            }
        }

        return context
    }

    private func determineMessageLimit(for question: String) -> Int {
        let lowercased = question.lowercased()

        if lowercased.contains("summary") || lowercased.contains("summarize") {
            return 50 // More messages for summaries
        } else if lowercased.contains("recent") || lowercased.contains("latest") {
            return 10
        } else if lowercased.contains("all") || lowercased.contains("everything") {
            return 100
        }

        return 25 // Default
    }

    private func extractChannelMention(from question: String) -> String? {
        // Look for #channel-name pattern
        let pattern = #"#([a-zA-Z0-9_-]+)"#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: question, range: NSRange(question.startIndex..., in: question)),
           let range = Range(match.range(at: 1), in: question) {
            return String(question[range])
        }
        return nil
    }

    private func extractPersonMention(from question: String) -> String? {
        // Look for @username or common patterns like "what did [name] say"
        let patterns = [
            #"@([a-zA-Z0-9_.-]+)"#,
            #"what did (\w+) say"#,
            #"(\w+)'s messages"#,
            #"messages from (\w+)"#
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: question, range: NSRange(question.startIndex..., in: question)),
               let range = Range(match.range(at: 1), in: question) {
                return String(question[range])
            }
        }

        return nil
    }

    private func extractSearchQuery(from question: String) -> String {
        // Remove common command words and extract the search term
        let stripped = question
            .replacingOccurrences(of: "search for", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "find", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "look for", with: "", options: .caseInsensitive)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return stripped
    }

    // MARK: - Prompt Building

    private func buildSystemPrompt() -> String {
        return """
        You are a helpful AI assistant integrated with Slack. You have access to the user's Slack workspace \
        and can help them understand conversations, find information, summarize discussions, and draft responses.

        Guidelines:
        - Be concise and helpful
        - When summarizing, focus on key points and action items
        - When answering questions about conversations, cite specific messages when relevant
        - Format responses clearly with bullet points or numbered lists when appropriate
        - If you don't have enough context to answer, say so and suggest what additional information would help
        - Respect privacy - don't share sensitive information unnecessarily
        - Use timestamps and usernames to provide context when referencing messages
        """
    }

    private func buildUserPrompt(question: String, slackContext: SlackContext) -> String {
        var prompt = "Question: \(question)\n\n"

        // Add channel context
        if let channel = slackContext.currentChannel {
            prompt += "Channel: #\(channel.name)\n"
            if let purpose = channel.purpose?.value, !purpose.isEmpty {
                prompt += "Channel purpose: \(purpose)\n"
            }
            prompt += "\n"
        }

        // Add message context
        if !slackContext.recentMessages.isEmpty {
            prompt += "Recent messages:\n"
            for message in slackContext.recentMessages.prefix(30).reversed() {
                let userName = slackContext.mentionedUsers.first { $0.id == message.user }?.displayName ?? message.user ?? "Unknown"
                let timestamp = formatTimestamp(message.timestamp)
                prompt += "[\(timestamp)] \(userName): \(message.text)\n"
            }
            prompt += "\n"
        }

        // Add search results if available
        if let searchResults = slackContext.searchResults, !searchResults.isEmpty {
            prompt += "Search results:\n"
            for message in searchResults.prefix(10) {
                let userName = message.user ?? "Unknown"
                let timestamp = formatTimestamp(message.timestamp)
                prompt += "[\(timestamp)] \(userName): \(message.text)\n"
            }
            prompt += "\n"
        }

        // Add thread context if available
        if let thread = slackContext.threadContext, !thread.isEmpty {
            prompt += "Thread context:\n"
            for message in thread {
                let userName = slackContext.mentionedUsers.first { $0.id == message.user }?.displayName ?? message.user ?? "Unknown"
                prompt += "- \(userName): \(message.text)\n"
            }
            prompt += "\n"
        }

        return prompt
    }

    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            formatter.dateFormat = "h:mm a"
            return "Today " + formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            formatter.dateFormat = "h:mm a"
            return "Yesterday " + formatter.string(from: date)
        } else {
            formatter.dateFormat = "MMM d, h:mm a"
            return formatter.string(from: date)
        }
    }

    // MARK: - Claude API Integration

    private func callClaude(systemPrompt: String, userPrompt: String) async throws -> String {
        guard let apiKey = anthropicAPIKey else {
            throw ClaudeAssistantError.missingAPIKey
        }

        struct MessageRequest: Encodable {
            let model: String
            let maxTokens: Int
            let system: String
            let messages: [[String: String]]

            enum CodingKeys: String, CodingKey {
                case model
                case maxTokens = "max_tokens"
                case system
                case messages
            }
        }

        struct MessageResponse: Decodable {
            let content: [ContentBlock]

            struct ContentBlock: Decodable {
                let type: String
                let text: String?
            }
        }

        let requestBody = MessageRequest(
            model: model,
            maxTokens: 1024,
            system: systemPrompt,
            messages: [["role": "user", "content": userPrompt]]
        )

        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw ClaudeAssistantError.apiError(errorMessage)
        }

        let messageResponse = try JSONDecoder().decode(MessageResponse.self, from: data)

        return messageResponse.content.compactMap { $0.text }.joined()
    }

    private func streamFromClaude(systemPrompt: String, userPrompt: String) async throws {
        guard let apiKey = anthropicAPIKey else {
            throw ClaudeAssistantError.missingAPIKey
        }

        struct StreamRequest: Encodable {
            let model: String
            let maxTokens: Int
            let system: String
            let messages: [[String: String]]
            let stream: Bool

            enum CodingKeys: String, CodingKey {
                case model
                case maxTokens = "max_tokens"
                case system
                case messages
                case stream
            }
        }

        let requestBody = StreamRequest(
            model: model,
            maxTokens: 1024,
            system: systemPrompt,
            messages: [["role": "user", "content": userPrompt]],
            stream: true
        )

        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (bytes, response) = try await URLSession.shared.bytes(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw ClaudeAssistantError.apiError("Stream request failed")
        }

        // Process SSE stream
        for try await line in bytes.lines {
            if line.hasPrefix("data: ") {
                let jsonString = String(line.dropFirst(6))
                if jsonString == "[DONE]" {
                    break
                }

                if let data = jsonString.data(using: .utf8) {
                    // Parse the streaming event
                    if let event = try? JSONDecoder().decode(StreamEvent.self, from: data) {
                        if event.type == "content_block_delta",
                           let delta = event.delta,
                           let text = delta.text {
                            streamingContent += text
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Streaming Event Types

private struct StreamEvent: Decodable {
    let type: String
    let delta: Delta?

    struct Delta: Decodable {
        let type: String?
        let text: String?
    }
}

// MARK: - Error Types

enum ClaudeAssistantError: LocalizedError {
    case missingAPIKey
    case apiError(String)
    case contextError(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "ANTHROPIC_API_KEY not configured"
        case .apiError(let message):
            return "Claude API error: \(message)"
        case .contextError(let message):
            return "Failed to gather Slack context: \(message)"
        }
    }
}

// MARK: - Convenience Extensions

extension ClaudeSlackAssistant {
    /// Quick summary of a channel
    func summarizeChannel(_ channel: SlackChannel) async throws -> String {
        try await ask("Please summarize the recent conversations in this channel, highlighting key discussions and any action items.", currentChannel: channel)
    }

    /// Find messages about a topic
    func findMessages(about topic: String, in channel: SlackChannel? = nil) async throws -> String {
        try await ask("Search for and summarize messages about: \(topic)", currentChannel: channel)
    }

    /// Generate a draft reply
    func draftReply(to message: SlackMessage, in channel: SlackChannel) async throws -> String {
        let context = "I need to reply to this message: \"\(message.text)\". Can you suggest a professional response?"
        return try await ask(context, currentChannel: channel)
    }

    /// Get a daily summary
    func getDailySummary(for channel: SlackChannel) async throws -> String {
        try await ask("Give me a summary of today's conversations, including key decisions and action items.", currentChannel: channel)
    }
}
