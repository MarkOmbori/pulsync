import SwiftUI

/// Main Slack chat view that integrates with Slack API.
/// Shows channels from the connected Slack workspace with real-time updates.
/// Falls back to demo mode with mock data when Slack credentials aren't configured.
struct SlackChatView: View {
    @State private var slackAuth = SlackAuthService.shared
    @State private var slackAPI = SlackAPIClient.shared
    @State private var socketClient = SlackSocketModeClient.shared

    @State private var channels: [SlackChannel] = []
    @State private var conversations: [SlackConversation] = []
    @State private var selectedChannel: SlackChannel?
    @State private var selectedConversation: SlackConversation?
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var error: String?

    // Demo mode state
    @State private var isDemoMode = false
    @State private var demoSelectedChannel: Channel? = MockChatData.channels.first
    @State private var demoSelectedDM: DirectMessage?

    /// Check if Slack credentials are configured
    private var hasSlackCredentials: Bool {
        ProcessInfo.processInfo.environment["SLACK_CLIENT_ID"] != nil &&
        !ProcessInfo.processInfo.environment["SLACK_CLIENT_ID"]!.isEmpty
    }

    var body: some View {
        Group {
            if isDemoMode || !hasSlackCredentials {
                // Demo mode - use existing CompanyChatView with mock data
                demoView
            } else if slackAuth.isAuthenticated {
                authenticatedView
            } else {
                SlackLoginView(onDemoMode: { isDemoMode = true })
            }
        }
        .task {
            if hasSlackCredentials && !isDemoMode {
                await loadData()
            }
        }
    }

    // MARK: - Demo View (Mock Data)

    @ViewBuilder
    private var demoView: some View {
        NavigationSplitView {
            DemoSidebarView(
                selectedChannel: $demoSelectedChannel,
                selectedDM: $demoSelectedDM,
                searchText: $searchText,
                onExitDemo: hasSlackCredentials ? { isDemoMode = false } : nil
            )
            .navigationSplitViewColumnWidth(min: 200, ideal: 260, max: 320)
        } detail: {
            if let channel = demoSelectedChannel {
                ChannelChatView(channel: channel)
            } else if let dm = demoSelectedDM {
                DMChatView(dm: dm)
            } else {
                demoWelcomeView
            }
        }
        .background(PulsyncTheme.background)
    }

    private var demoWelcomeView: some View {
        VStack(spacing: PulsyncSpacing.lg) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 64))
                .foregroundStyle(PulsyncTheme.textMuted)

            Text("Demo Mode")
                .font(.pulsyncTitle2)
                .foregroundStyle(PulsyncTheme.textSecondary)

            Text("Using mock data. Connect to Slack for real workspace access.")
                .font(.pulsyncBody)
                .foregroundStyle(PulsyncTheme.textMuted)
                .multilineTextAlignment(.center)

            if hasSlackCredentials {
                Button(action: { isDemoMode = false }) {
                    Text("Connect to Slack")
                        .font(.pulsyncLabel)
                        .foregroundStyle(.white)
                        .padding(.horizontal, PulsyncSpacing.lg)
                        .padding(.vertical, PulsyncSpacing.sm)
                        .background(PulsyncTheme.primary)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PulsyncTheme.background)
    }

    // MARK: - Authenticated View

    @ViewBuilder
    private var authenticatedView: some View {
        NavigationSplitView {
            SlackSidebarView(
                channels: channels,
                conversations: conversations,
                selectedChannel: $selectedChannel,
                selectedConversation: $selectedConversation,
                searchText: $searchText,
                teamName: slackAuth.teamName
            )
            .navigationSplitViewColumnWidth(min: 200, ideal: 260, max: 320)
        } detail: {
            if let channel = selectedChannel {
                SlackChannelChatView(channel: channel)
            } else if let conversation = selectedConversation {
                SlackDMChatView(conversation: conversation)
            } else {
                welcomeView
            }
        }
        .background(PulsyncTheme.background)
        .overlay {
            if isLoading && channels.isEmpty {
                loadingOverlay
            }
        }
        .alert("Error", isPresented: .constant(error != nil)) {
            Button("OK") { error = nil }
        } message: {
            Text(error ?? "")
        }
    }

    // MARK: - Welcome View

    private var welcomeView: some View {
        VStack(spacing: PulsyncSpacing.lg) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 64))
                .foregroundStyle(PulsyncTheme.textMuted)

            Text("Connected to Slack")
                .font(.pulsyncTitle2)
                .foregroundStyle(PulsyncTheme.textSecondary)

            if let teamName = slackAuth.teamName {
                Text(teamName)
                    .font(.pulsyncBody)
                    .foregroundStyle(PulsyncTheme.primary)
            }

            Text("Select a channel from the sidebar to start chatting")
                .font(.pulsyncBody)
                .foregroundStyle(PulsyncTheme.textMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PulsyncTheme.background)
    }

    // MARK: - Loading Overlay

    private var loadingOverlay: some View {
        VStack(spacing: PulsyncSpacing.md) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(PulsyncTheme.primary)
            Text("Loading Slack workspace...")
                .font(.pulsyncBody)
                .foregroundStyle(PulsyncTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PulsyncTheme.background.opacity(0.9))
    }

    // MARK: - Data Loading

    private func loadData() async {
        guard slackAuth.isAuthenticated else { return }

        isLoading = true

        do {
            // Load channels and DMs in parallel
            async let channelsResult = slackAPI.listChannels()
            async let dmsResult = slackAPI.listDirectMessages()

            let (channelData, dmData) = try await (channelsResult, dmsResult)

            channels = channelData.channels.filter { $0.isMember }
            conversations = dmData.conversations

            // Connect to Socket Mode for real-time updates
            try await socketClient.connect()

            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }
}

// MARK: - Slack Sidebar View

struct SlackSidebarView: View {
    let channels: [SlackChannel]
    let conversations: [SlackConversation]
    @Binding var selectedChannel: SlackChannel?
    @Binding var selectedConversation: SlackConversation?
    @Binding var searchText: String
    let teamName: String?

    @State private var channelsExpanded = true
    @State private var dmsExpanded = true

    private var filteredChannels: [SlackChannel] {
        if searchText.isEmpty { return channels }
        return channels.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Workspace header
            if let teamName = teamName {
                HStack(spacing: PulsyncSpacing.sm) {
                    Image(systemName: "slack")
                        .font(.system(size: 18))
                        .foregroundStyle(PulsyncTheme.primary)
                    Text(teamName)
                        .font(.pulsyncLabel)
                        .foregroundStyle(PulsyncTheme.textPrimary)
                    Spacer()
                }
                .padding(PulsyncSpacing.md)
                .background(PulsyncTheme.surface)
            }

            // Search bar
            HStack {
                Image(systemName: PulsyncIcons.search)
                    .foregroundStyle(PulsyncTheme.textMuted)
                TextField("Search channels", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.pulsyncBody)
                    .foregroundStyle(PulsyncTheme.textPrimary)
            }
            .padding(.horizontal, PulsyncSpacing.sm)
            .padding(.vertical, PulsyncSpacing.xs)
            .background(PulsyncTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: PulsyncRadius.md))
            .padding(PulsyncSpacing.sm)

            Divider()
                .background(PulsyncTheme.border)

            // Channel list
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    // Channels section
                    DisclosureGroup(
                        isExpanded: $channelsExpanded,
                        content: {
                            ForEach(filteredChannels) { channel in
                                SlackChannelRow(
                                    channel: channel,
                                    isSelected: selectedChannel?.id == channel.id
                                )
                                .onTapGesture {
                                    selectedChannel = channel
                                    selectedConversation = nil
                                }
                            }
                        },
                        label: {
                            HStack {
                                Text("Channels")
                                    .font(.pulsyncCaption)
                                    .foregroundStyle(PulsyncTheme.textMuted)
                                Spacer()
                                Text("\(channels.count)")
                                    .font(.pulsyncMicro)
                                    .foregroundStyle(PulsyncTheme.textMuted)
                            }
                        }
                    )
                    .padding(.horizontal, PulsyncSpacing.sm)
                    .padding(.vertical, PulsyncSpacing.xs)

                    // DMs section
                    DisclosureGroup(
                        isExpanded: $dmsExpanded,
                        content: {
                            ForEach(conversations) { conversation in
                                SlackDMRow(
                                    conversation: conversation,
                                    isSelected: selectedConversation?.id == conversation.id
                                )
                                .onTapGesture {
                                    selectedConversation = conversation
                                    selectedChannel = nil
                                }
                            }
                        },
                        label: {
                            HStack {
                                Text("Direct Messages")
                                    .font(.pulsyncCaption)
                                    .foregroundStyle(PulsyncTheme.textMuted)
                                Spacer()
                                Text("\(conversations.count)")
                                    .font(.pulsyncMicro)
                                    .foregroundStyle(PulsyncTheme.textMuted)
                            }
                        }
                    )
                    .padding(.horizontal, PulsyncSpacing.sm)
                    .padding(.vertical, PulsyncSpacing.xs)
                }
            }
        }
        .background(PulsyncTheme.surface)
    }
}

// MARK: - Slack Channel Row

struct SlackChannelRow: View {
    let channel: SlackChannel
    let isSelected: Bool

    var body: some View {
        HStack(spacing: PulsyncSpacing.sm) {
            Text("#")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(PulsyncTheme.textMuted)

            Text(channel.name)
                .font(.pulsyncBody)
                .foregroundStyle(isSelected ? PulsyncTheme.textPrimary : PulsyncTheme.textSecondary)
                .lineLimit(1)

            Spacer()

            if channel.isPrivate {
                Image(systemName: "lock.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(PulsyncTheme.textMuted)
            }
        }
        .padding(.horizontal, PulsyncSpacing.sm)
        .padding(.vertical, PulsyncSpacing.xs)
        .background(isSelected ? PulsyncTheme.primary.opacity(0.15) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: PulsyncRadius.sm))
    }
}

// MARK: - Slack DM Row

struct SlackDMRow: View {
    let conversation: SlackConversation
    let isSelected: Bool

    @State private var user: SlackUser?
    private let slackAPI = SlackAPIClient.shared

    var body: some View {
        HStack(spacing: PulsyncSpacing.sm) {
            // Avatar placeholder
            Circle()
                .fill(PulsyncTheme.primary.opacity(0.3))
                .frame(width: 24, height: 24)
                .overlay {
                    if let user = user {
                        Text(user.initials)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(PulsyncTheme.primary)
                    }
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(user?.displayName ?? conversation.name ?? "Unknown")
                    .font(.pulsyncBody)
                    .foregroundStyle(isSelected ? PulsyncTheme.textPrimary : PulsyncTheme.textSecondary)
                    .lineLimit(1)

                if let unread = conversation.unreadCountDisplay, unread > 0 {
                    Text("\(unread) unread")
                        .font(.pulsyncMicro)
                        .foregroundStyle(PulsyncTheme.primary)
                }
            }

            Spacer()
        }
        .padding(.horizontal, PulsyncSpacing.sm)
        .padding(.vertical, PulsyncSpacing.xs)
        .background(isSelected ? PulsyncTheme.primary.opacity(0.15) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: PulsyncRadius.sm))
        .task {
            if let userId = conversation.user {
                user = try? await slackAPI.getUserInfo(userId: userId)
            }
        }
    }
}

// MARK: - Demo Sidebar View

struct DemoSidebarView: View {
    @Binding var selectedChannel: Channel?
    @Binding var selectedDM: DirectMessage?
    @Binding var searchText: String
    var onExitDemo: (() -> Void)?

    @State private var channelsExpanded = true
    @State private var dmsExpanded = true

    private var filteredChannels: [Channel] {
        if searchText.isEmpty { return MockChatData.channels }
        return MockChatData.channels.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Demo mode header
            HStack(spacing: PulsyncSpacing.sm) {
                Image(systemName: "sparkles")
                    .font(.system(size: 18))
                    .foregroundStyle(PulsyncTheme.warning)
                Text("Demo Mode")
                    .font(.pulsyncLabel)
                    .foregroundStyle(PulsyncTheme.textPrimary)
                Spacer()
                if let onExitDemo = onExitDemo {
                    Button(action: onExitDemo) {
                        Text("Connect")
                            .font(.pulsyncCaption)
                            .foregroundStyle(PulsyncTheme.primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(PulsyncSpacing.md)
            .background(PulsyncTheme.surface)

            // Search bar
            HStack {
                Image(systemName: PulsyncIcons.search)
                    .foregroundStyle(PulsyncTheme.textMuted)
                TextField("Search channels", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.pulsyncBody)
                    .foregroundStyle(PulsyncTheme.textPrimary)
            }
            .padding(.horizontal, PulsyncSpacing.sm)
            .padding(.vertical, PulsyncSpacing.xs)
            .background(PulsyncTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: PulsyncRadius.md))
            .padding(PulsyncSpacing.sm)

            Divider()
                .background(PulsyncTheme.border)

            // Channel list
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    // Channels section
                    DisclosureGroup(
                        isExpanded: $channelsExpanded,
                        content: {
                            ForEach(filteredChannels) { channel in
                                DemoChannelRow(
                                    channel: channel,
                                    isSelected: selectedChannel?.id == channel.id
                                )
                                .onTapGesture {
                                    selectedChannel = channel
                                    selectedDM = nil
                                }
                            }
                        },
                        label: {
                            HStack {
                                Text("Channels")
                                    .font(.pulsyncCaption)
                                    .foregroundStyle(PulsyncTheme.textMuted)
                                Spacer()
                                Text("\(MockChatData.channels.count)")
                                    .font(.pulsyncMicro)
                                    .foregroundStyle(PulsyncTheme.textMuted)
                            }
                        }
                    )
                    .padding(.horizontal, PulsyncSpacing.sm)
                    .padding(.vertical, PulsyncSpacing.xs)

                    // DMs section
                    DisclosureGroup(
                        isExpanded: $dmsExpanded,
                        content: {
                            ForEach(MockChatData.directMessages) { dm in
                                DemoDMRow(
                                    dm: dm,
                                    isSelected: selectedDM?.id == dm.id
                                )
                                .onTapGesture {
                                    selectedDM = dm
                                    selectedChannel = nil
                                }
                            }
                        },
                        label: {
                            HStack {
                                Text("Direct Messages")
                                    .font(.pulsyncCaption)
                                    .foregroundStyle(PulsyncTheme.textMuted)
                                Spacer()
                                Text("\(MockChatData.directMessages.count)")
                                    .font(.pulsyncMicro)
                                    .foregroundStyle(PulsyncTheme.textMuted)
                            }
                        }
                    )
                    .padding(.horizontal, PulsyncSpacing.sm)
                    .padding(.vertical, PulsyncSpacing.xs)
                }
            }
        }
        .background(PulsyncTheme.surface)
    }
}

// MARK: - Demo Channel Row

struct DemoChannelRow: View {
    let channel: Channel
    let isSelected: Bool

    var body: some View {
        HStack(spacing: PulsyncSpacing.sm) {
            Text("#")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(PulsyncTheme.textMuted)

            Text(channel.name)
                .font(.pulsyncBody)
                .foregroundStyle(isSelected ? PulsyncTheme.textPrimary : PulsyncTheme.textSecondary)
                .lineLimit(1)

            Spacer()

            if channel.unreadCount > 0 {
                Text("\(channel.unreadCount)")
                    .font(.pulsyncMicro)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(PulsyncTheme.primary)
                    .clipShape(Capsule())
            }

            if channel.isPrivate {
                Image(systemName: "lock.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(PulsyncTheme.textMuted)
            }
        }
        .padding(.horizontal, PulsyncSpacing.sm)
        .padding(.vertical, PulsyncSpacing.xs)
        .background(isSelected ? PulsyncTheme.primary.opacity(0.15) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: PulsyncRadius.sm))
    }
}

// MARK: - Demo DM Row

struct DemoDMRow: View {
    let dm: DirectMessage
    let isSelected: Bool

    var body: some View {
        HStack(spacing: PulsyncSpacing.sm) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color(hex: dm.participant.avatarColor))
                    .frame(width: 24, height: 24)

                Text(dm.participant.initials)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white)
            }

            // Online indicator
            Circle()
                .fill(dm.participant.isOnline ? Color.green : Color.gray)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(dm.participant.displayName)
                    .font(.pulsyncBody)
                    .foregroundStyle(isSelected ? PulsyncTheme.textPrimary : PulsyncTheme.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            if dm.unreadCount > 0 {
                Text("\(dm.unreadCount)")
                    .font(.pulsyncMicro)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(PulsyncTheme.primary)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, PulsyncSpacing.sm)
        .padding(.vertical, PulsyncSpacing.xs)
        .background(isSelected ? PulsyncTheme.primary.opacity(0.15) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: PulsyncRadius.sm))
    }
}

// MARK: - Slack Login View

struct SlackLoginView: View {
    @State private var slackAuth = SlackAuthService.shared
    @State private var isAuthenticating = false
    var onDemoMode: (() -> Void)?

    /// Check if Slack credentials are configured
    private var hasSlackCredentials: Bool {
        ProcessInfo.processInfo.environment["SLACK_CLIENT_ID"] != nil &&
        !ProcessInfo.processInfo.environment["SLACK_CLIENT_ID"]!.isEmpty
    }

    var body: some View {
        VStack(spacing: PulsyncSpacing.xl) {
            // Slack icon
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 64))
                .foregroundStyle(PulsyncTheme.primary)

            VStack(spacing: PulsyncSpacing.sm) {
                Text("Connect to Slack")
                    .font(.pulsyncTitle1)
                    .foregroundStyle(PulsyncTheme.textPrimary)

                Text("Sign in with your Slack workspace to access channels and messages")
                    .font(.pulsyncBody)
                    .foregroundStyle(PulsyncTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }

            VStack(spacing: PulsyncSpacing.md) {
                // Connect button
                if hasSlackCredentials {
                    Button(action: connectToSlack) {
                        HStack(spacing: PulsyncSpacing.sm) {
                            if isAuthenticating {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.white)
                            }
                            Text(isAuthenticating ? "Connecting..." : "Connect to Slack")
                                .font(.pulsyncLabel)
                        }
                        .frame(minWidth: 200)
                        .padding(.horizontal, PulsyncSpacing.lg)
                        .padding(.vertical, PulsyncSpacing.md)
                        .background(PulsyncTheme.primary)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: PulsyncRadius.lg))
                    }
                    .buttonStyle(.plain)
                    .disabled(isAuthenticating)
                }

                // Demo mode button
                if let onDemoMode = onDemoMode {
                    Button(action: onDemoMode) {
                        HStack(spacing: PulsyncSpacing.sm) {
                            Image(systemName: "sparkles")
                            Text("Try Demo Mode")
                                .font(.pulsyncLabel)
                        }
                        .frame(minWidth: 200)
                        .padding(.horizontal, PulsyncSpacing.lg)
                        .padding(.vertical, PulsyncSpacing.md)
                        .background(PulsyncTheme.surface)
                        .foregroundStyle(PulsyncTheme.textSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: PulsyncRadius.lg))
                        .overlay(
                            RoundedRectangle(cornerRadius: PulsyncRadius.lg)
                                .strokeBorder(PulsyncTheme.border, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            // Error message
            if let error = slackAuth.error {
                Text(error)
                    .font(.pulsyncCaption)
                    .foregroundStyle(PulsyncTheme.error)
            }

            // Status message
            if !hasSlackCredentials {
                VStack(spacing: PulsyncSpacing.xs) {
                    Text("Slack credentials not configured")
                        .font(.pulsyncCaption)
                        .foregroundStyle(PulsyncTheme.warning)
                    Text("Set SLACK_CLIENT_ID and SLACK_CLIENT_SECRET environment variables")
                        .font(.pulsyncMicro)
                        .foregroundStyle(PulsyncTheme.textMuted)
                }
            } else {
                Text("You'll be redirected to Slack to authorize Pulsync")
                    .font(.pulsyncCaption)
                    .foregroundStyle(PulsyncTheme.textMuted)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PulsyncTheme.background)
    }

    private func connectToSlack() {
        isAuthenticating = true
        Task {
            do {
                try await slackAuth.startOAuth()
            } catch {
                // Error is already set in slackAuth
            }
            isAuthenticating = false
        }
    }
}

// MARK: - Preview

#Preview("Authenticated") {
    SlackChatView()
        .frame(width: 900, height: 600)
}

#Preview("Login") {
    SlackLoginView()
        .frame(width: 600, height: 400)
}
