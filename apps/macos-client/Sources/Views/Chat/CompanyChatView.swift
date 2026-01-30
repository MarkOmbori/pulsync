import SwiftUI

struct CompanyChatView: View {
    @State private var selectedChannel: Channel? = MockChatData.channels.first
    @State private var selectedDM: DirectMessage?
    @State private var searchText = ""
    @State private var sidebarWidth: CGFloat = 240

    enum Selection: Hashable {
        case channel(Channel)
        case dm(DirectMessage)
    }

    var body: some View {
        NavigationSplitView {
            ChatSidebarView(
                selectedChannel: $selectedChannel,
                selectedDM: $selectedDM,
                searchText: $searchText
            )
            .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 300)
        } detail: {
            if let channel = selectedChannel {
                ChannelChatView(channel: channel)
            } else if let dm = selectedDM {
                DMChatView(dm: dm)
            } else {
                welcomeView
            }
        }
        .background(PulsyncTheme.background)
    }

    private var welcomeView: some View {
        VStack(spacing: PulsyncSpacing.lg) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 64))
                .foregroundStyle(PulsyncTheme.textMuted)

            Text("Select a channel or message")
                .font(.pulsyncTitle2)
                .foregroundStyle(PulsyncTheme.textSecondary)

            Text("Choose a conversation from the sidebar to start chatting")
                .font(.pulsyncBody)
                .foregroundStyle(PulsyncTheme.textMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PulsyncTheme.background)
    }
}

// MARK: - DM Chat View (Placeholder for now)

struct DMChatView: View {
    let dm: DirectMessage

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: PulsyncSpacing.sm) {
                UserAvatarView(user: dm.participant, size: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(dm.participant.displayName)
                        .font(.pulsyncLabel)
                        .foregroundStyle(PulsyncTheme.textPrimary)

                    HStack(spacing: 4) {
                        Circle()
                            .fill(dm.participant.isOnline ? Color.green : Color.gray)
                            .frame(width: 8, height: 8)
                        Text(dm.participant.isOnline ? "Active" : "Away")
                            .font(.pulsyncCaption)
                            .foregroundStyle(PulsyncTheme.textMuted)
                    }
                }

                Spacer()
            }
            .padding(PulsyncSpacing.md)
            .background(PulsyncTheme.surface)

            Divider()
                .background(PulsyncTheme.border)

            // Placeholder content
            VStack(spacing: PulsyncSpacing.md) {
                Spacer()

                Text("Direct messages coming soon")
                    .font(.pulsyncBody)
                    .foregroundStyle(PulsyncTheme.textMuted)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Input placeholder
            ChannelInputView(
                channelName: dm.participant.displayName,
                onSend: { _ in }
            )
        }
        .background(PulsyncTheme.background)
    }
}

#Preview {
    CompanyChatView()
        .frame(width: 900, height: 600)
}
