import SwiftUI

/// Chat view for a Slack channel with real-time message updates.
struct SlackChannelChatView: View {
    let channel: SlackChannel

    @State private var slackAPI = SlackAPIClient.shared
    @State private var socketClient = SlackSocketModeClient.shared

    @State private var messages: [SlackMessage] = []
    @State private var isLoading = false
    @State private var hasMoreMessages = false
    @State private var nextCursor: String?
    @State private var error: String?
    @State private var scrollProxy: ScrollViewProxy?

    var body: some View {
        VStack(spacing: 0) {
            // Channel header
            channelHeader

            Divider()
                .background(PulsyncTheme.border)

            // Messages list
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: PulsyncSpacing.md) {
                        // Load more button
                        if hasMoreMessages {
                            loadMoreButton
                        }

                        // Channel intro
                        if !hasMoreMessages {
                            channelIntro
                        }

                        // Messages (reversed for natural chat order)
                        ForEach(messages.reversed()) { message in
                            SlackMessageBubble(
                                message: message,
                                userCache: slackAPI.userCache
                            )
                            .id(message.id)
                        }

                        // Loading indicator
                        if isLoading && messages.isEmpty {
                            loadingView
                        }
                    }
                    .padding(PulsyncSpacing.md)
                }
                .onAppear {
                    scrollProxy = proxy
                }
            }

            // AI Chat bar for Slack queries
            AISlackChatBar(currentChannel: channel)

            // Message input
            SlackChannelInputView(
                channelName: channel.name,
                onSend: sendMessage
            )
        }
        .background(PulsyncTheme.background)
        .task {
            await loadMessages()
            setupRealTimeUpdates()
        }
        .onChange(of: channel.id) { _, _ in
            messages = []
            Task { await loadMessages() }
        }
        .alert("Error", isPresented: .constant(error != nil)) {
            Button("OK") { error = nil }
        } message: {
            Text(error ?? "")
        }
    }

    // MARK: - Channel Header

    private var channelHeader: some View {
        HStack(spacing: PulsyncSpacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: PulsyncSpacing.xs) {
                    if channel.isPrivate {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(PulsyncTheme.textMuted)
                    } else {
                        Text("#")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(PulsyncTheme.textMuted)
                    }

                    Text(channel.name)
                        .font(.pulsyncTitle2)
                        .foregroundStyle(PulsyncTheme.textPrimary)
                }

                if let topic = channel.topic?.value, !topic.isEmpty {
                    Text(topic)
                        .font(.pulsyncCaption)
                        .foregroundStyle(PulsyncTheme.textMuted)
                        .lineLimit(1)
                } else if let purpose = channel.purpose?.value, !purpose.isEmpty {
                    Text(purpose)
                        .font(.pulsyncCaption)
                        .foregroundStyle(PulsyncTheme.textMuted)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Member count
            if let memberCount = channel.numMembers {
                HStack(spacing: 4) {
                    Image(systemName: "person.2")
                        .font(.system(size: 12))
                    Text("\(memberCount)")
                        .font(.pulsyncCaption)
                }
                .foregroundStyle(PulsyncTheme.textMuted)
                .padding(.horizontal, PulsyncSpacing.sm)
                .padding(.vertical, PulsyncSpacing.xs)
                .background(PulsyncTheme.surface)
                .clipShape(Capsule())
            }

            // Search button
            Button(action: {}) {
                Image(systemName: PulsyncIcons.search)
                    .font(.system(size: 14))
                    .foregroundStyle(PulsyncTheme.textMuted)
                    .frame(width: 32, height: 32)
                    .background(PulsyncTheme.surface)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, PulsyncSpacing.md)
        .padding(.vertical, PulsyncSpacing.sm)
        .background(PulsyncTheme.surface.opacity(0.5))
    }

    // MARK: - Channel Intro

    private var channelIntro: some View {
        VStack(alignment: .leading, spacing: PulsyncSpacing.sm) {
            HStack(spacing: PulsyncSpacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: PulsyncRadius.md)
                        .fill(PulsyncTheme.primary.opacity(0.2))

                    Text(channel.isPrivate ? "🔒" : "#")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(PulsyncTheme.primary)
                }
                .frame(width: 56, height: 56)

                VStack(alignment: .leading, spacing: 4) {
                    Text(channel.displayName)
                        .font(.pulsyncTitle2)
                        .foregroundStyle(PulsyncTheme.textPrimary)

                    Text("This is the start of \(channel.displayName)")
                        .font(.pulsyncBody)
                        .foregroundStyle(PulsyncTheme.textMuted)
                }
            }

            if let purpose = channel.purpose?.value, !purpose.isEmpty {
                Text(purpose)
                    .font(.pulsyncBody)
                    .foregroundStyle(PulsyncTheme.textSecondary)
            }
        }
        .padding(PulsyncSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PulsyncTheme.surface.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: PulsyncRadius.lg))
    }

    // MARK: - Load More Button

    private var loadMoreButton: some View {
        Button(action: { Task { await loadMoreMessages() } }) {
            HStack {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                        .tint(PulsyncTheme.primary)
                }
                Text("Load older messages")
                    .font(.pulsyncCaption)
                    .foregroundStyle(PulsyncTheme.primary)
            }
            .padding(.vertical, PulsyncSpacing.sm)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        HStack {
            Spacer()
            VStack(spacing: PulsyncSpacing.sm) {
                ProgressView()
                    .tint(PulsyncTheme.primary)
                Text("Loading messages...")
                    .font(.pulsyncCaption)
                    .foregroundStyle(PulsyncTheme.textMuted)
            }
            Spacer()
        }
        .padding(PulsyncSpacing.xl)
    }

    // MARK: - Data Loading

    private func loadMessages() async {
        isLoading = true

        do {
            let result = try await slackAPI.getChannelHistory(channelId: channel.id, limit: 50)
            messages = result.messages
            hasMoreMessages = result.hasMore
            nextCursor = result.nextCursor

            // Prefetch user info
            let userIds = Set(messages.compactMap { $0.user })
            await slackAPI.prefetchUsers(userIds: Array(userIds))

            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }

    private func loadMoreMessages() async {
        guard let cursor = nextCursor, !isLoading else { return }

        isLoading = true

        do {
            let result = try await slackAPI.getChannelHistory(
                channelId: channel.id,
                limit: 50,
                cursor: cursor
            )

            messages.append(contentsOf: result.messages)
            hasMoreMessages = result.hasMore
            nextCursor = result.nextCursor

            // Prefetch user info
            let userIds = Set(result.messages.compactMap { $0.user })
            await slackAPI.prefetchUsers(userIds: Array(userIds))

            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }

    // MARK: - Real-time Updates

    private func setupRealTimeUpdates() {
        // Subscribe to message stream for this channel
        Task {
            for await message in socketClient.messageStream(for: channel.id) {
                // Insert new message at the beginning (newest first from API)
                messages.insert(message, at: 0)

                // Prefetch user info if needed
                if let userId = message.user {
                    _ = try? await slackAPI.getUserInfo(userId: userId)
                }
            }
        }
    }

    // MARK: - Send Message

    private func sendMessage(_ text: String) {
        Task {
            do {
                let message = try await slackAPI.postMessage(channel: channel.id, text: text)
                // Message will be added via real-time updates, but add immediately for responsiveness
                messages.insert(message, at: 0)
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
}

// MARK: - Slack Message Bubble

struct SlackMessageBubble: View {
    let message: SlackMessage
    let userCache: [String: SlackUser]

    @State private var isHovered = false

    private var user: SlackUser? {
        message.user.flatMap { userCache[$0] }
    }

    private var displayName: String {
        user?.displayName ?? message.username ?? message.user ?? "Unknown"
    }

    private var avatarUrl: String? {
        user?.profile.image48 ?? user?.profile.image72
    }

    var body: some View {
        HStack(alignment: .top, spacing: PulsyncSpacing.sm) {
            // Avatar
            SlackAvatarView(user: user, size: 36)

            VStack(alignment: .leading, spacing: 4) {
                // Header: Name + timestamp
                HStack(spacing: PulsyncSpacing.sm) {
                    Text(displayName)
                        .font(.pulsyncLabel)
                        .foregroundStyle(PulsyncTheme.textPrimary)

                    Text(formatTimestamp(message.timestamp))
                        .font(.pulsyncMicro)
                        .foregroundStyle(PulsyncTheme.textMuted)

                    if message.edited != nil {
                        Text("(edited)")
                            .font(.pulsyncMicro)
                            .foregroundStyle(PulsyncTheme.textMuted)
                    }
                }

                // Message body
                Text(message.text)
                    .font(.pulsyncBody)
                    .foregroundStyle(PulsyncTheme.textSecondary)
                    .textSelection(.enabled)

                // Reactions
                if let reactions = message.reactions, !reactions.isEmpty {
                    HStack(spacing: PulsyncSpacing.xs) {
                        ForEach(reactions, id: \.name) { reaction in
                            HStack(spacing: 4) {
                                Text(":\(reaction.name):")
                                    .font(.system(size: 12))
                                Text("\(reaction.count)")
                                    .font(.pulsyncMicro)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(PulsyncTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: PulsyncRadius.sm))
                        }
                    }
                    .padding(.top, 4)
                }

                // Thread indicator
                if message.isThreadParent, let replyCount = message.replyCount {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 12))
                        Text("\(replyCount) \(replyCount == 1 ? "reply" : "replies")")
                            .font(.pulsyncCaption)
                    }
                    .foregroundStyle(PulsyncTheme.primary)
                    .padding(.top, 4)
                }
            }

            Spacer()

            // Hover actions
            if isHovered {
                HStack(spacing: 4) {
                    ForEach(["face.smiling", "bubble.left", "bookmark"], id: \.self) { icon in
                        Button(action: {}) {
                            Image(systemName: icon)
                                .font(.system(size: 12))
                                .foregroundStyle(PulsyncTheme.textMuted)
                                .frame(width: 28, height: 28)
                                .background(PulsyncTheme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: PulsyncRadius.sm))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(PulsyncSpacing.sm)
        .background(isHovered ? PulsyncTheme.surface.opacity(0.3) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: PulsyncRadius.md))
        .onHover { isHovered = $0 }
    }

    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            formatter.dateFormat = "h:mm a"
            return "Yesterday " + formatter.string(from: date)
        } else {
            formatter.dateFormat = "MMM d, h:mm a"
            return formatter.string(from: date)
        }
    }
}

// MARK: - Slack Avatar View

struct SlackAvatarView: View {
    let user: SlackUser?
    let size: CGFloat

    var body: some View {
        Group {
            if let imageUrl = user?.profile.image48 ?? user?.profile.image72,
               let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    avatarPlaceholder
                }
            } else {
                avatarPlaceholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.2))
    }

    private var avatarPlaceholder: some View {
        ZStack {
            Circle()
                .fill(PulsyncTheme.primary.opacity(0.3))
            Text(user?.initials ?? "?")
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundStyle(PulsyncTheme.primary)
        }
    }
}

// MARK: - Slack Channel Input View

struct SlackChannelInputView: View {
    let channelName: String
    let onSend: (String) -> Void

    @State private var inputText = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(alignment: .bottom, spacing: PulsyncSpacing.sm) {
            // Attachment button
            Button(action: {}) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(PulsyncTheme.textMuted)
                    .frame(width: 32, height: 32)
                    .background(PulsyncTheme.surface)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            // Text input
            TextField("Message #\(channelName)", text: $inputText, axis: .vertical)
                .font(.pulsyncBody)
                .foregroundStyle(PulsyncTheme.textPrimary)
                .focused($isFocused)
                .lineLimit(1...5)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(PulsyncTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: PulsyncRadius.lg))
                .overlay(
                    RoundedRectangle(cornerRadius: PulsyncRadius.lg)
                        .strokeBorder(
                            isFocused ? PulsyncTheme.primary.opacity(0.5) : PulsyncTheme.border,
                            lineWidth: 1
                        )
                )
                .onSubmit {
                    sendMessage()
                }

            // Emoji button
            Button(action: {}) {
                Image(systemName: "face.smiling")
                    .font(.system(size: 14))
                    .foregroundStyle(PulsyncTheme.textMuted)
                    .frame(width: 32, height: 32)
                    .background(PulsyncTheme.surface)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            // Send button
            Button(action: sendMessage) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 32, height: 32)
                    .background(inputText.isEmpty ? PulsyncTheme.textMuted : PulsyncTheme.primary)
                    .foregroundStyle(.white)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(inputText.isEmpty)
        }
        .padding(.horizontal, PulsyncSpacing.md)
        .padding(.vertical, PulsyncSpacing.sm)
        .background(PulsyncTheme.background)
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        onSend(text)
        inputText = ""
    }
}

// MARK: - Slack DM Chat View

struct SlackDMChatView: View {
    let conversation: SlackConversation

    @State private var slackAPI = SlackAPIClient.shared
    @State private var messages: [SlackMessage] = []
    @State private var user: SlackUser?
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            dmHeader

            Divider()
                .background(PulsyncTheme.border)

            // Messages
            ScrollView {
                LazyVStack(spacing: PulsyncSpacing.md) {
                    if isLoading {
                        loadingView
                    } else {
                        ForEach(messages.reversed()) { message in
                            SlackMessageBubble(
                                message: message,
                                userCache: slackAPI.userCache
                            )
                        }
                    }
                }
                .padding(PulsyncSpacing.md)
            }

            // Input
            SlackChannelInputView(
                channelName: user?.displayName ?? "Message",
                onSend: sendMessage
            )
        }
        .background(PulsyncTheme.background)
        .task {
            await loadConversation()
        }
    }

    private var dmHeader: some View {
        HStack(spacing: PulsyncSpacing.sm) {
            SlackAvatarView(user: user, size: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(user?.displayName ?? conversation.name ?? "Direct Message")
                    .font(.pulsyncLabel)
                    .foregroundStyle(PulsyncTheme.textPrimary)

                if let title = user?.profile.title, !title.isEmpty {
                    Text(title)
                        .font(.pulsyncCaption)
                        .foregroundStyle(PulsyncTheme.textMuted)
                }
            }

            Spacer()
        }
        .padding(PulsyncSpacing.md)
        .background(PulsyncTheme.surface)
    }

    private var loadingView: some View {
        HStack {
            Spacer()
            ProgressView()
                .tint(PulsyncTheme.primary)
            Spacer()
        }
        .padding(PulsyncSpacing.xl)
    }

    private func loadConversation() async {
        isLoading = true

        do {
            // Load user info
            if let userId = conversation.user {
                user = try await slackAPI.getUserInfo(userId: userId)
            }

            // Load messages
            let result = try await slackAPI.getChannelHistory(channelId: conversation.id, limit: 50)
            messages = result.messages

            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }

    private func sendMessage(_ text: String) {
        Task {
            do {
                let message = try await slackAPI.postMessage(channel: conversation.id, text: text)
                messages.insert(message, at: 0)
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SlackChannelChatView(channel: SlackChannel(
        id: "C123",
        name: "general",
        isPrivate: false,
        isMember: true,
        isArchived: false,
        topic: SlackTopic(value: "General discussion", creator: nil, lastSet: nil),
        purpose: SlackPurpose(value: "Company-wide announcements", creator: nil, lastSet: nil),
        numMembers: 42,
        created: nil,
        creator: nil
    ))
    .frame(width: 600, height: 500)
}
