import SwiftUI

struct ChannelChatView: View {
    let channel: Channel
    @State private var messages: [ChannelMessage] = []
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
                        // Channel intro
                        channelIntro

                        // Messages
                        ForEach(messages) { message in
                            ChannelMessageBubble(message: message)
                                .id(message.id)
                        }
                    }
                    .padding(PulsyncSpacing.md)
                }
                .onAppear {
                    scrollProxy = proxy
                    messages = MockChatData.messages(for: channel.id)
                }
                .onChange(of: channel.id) { _, newValue in
                    messages = MockChatData.messages(for: newValue)
                }
            }

            // Message input
            ChannelInputView(
                channelName: channel.name,
                onSend: sendMessage
            )
        }
        .background(PulsyncTheme.background)
    }

    // MARK: - Channel Header

    private var channelHeader: some View {
        HStack(spacing: PulsyncSpacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: PulsyncSpacing.xs) {
                    Text("#")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(PulsyncTheme.textMuted)

                    Text(channel.name)
                        .font(.pulsyncTitle2)
                        .foregroundStyle(PulsyncTheme.textPrimary)
                }

                Text(channel.description)
                    .font(.pulsyncCaption)
                    .foregroundStyle(PulsyncTheme.textMuted)
                    .lineLimit(1)
            }

            Spacer()

            // Member count
            HStack(spacing: 4) {
                Image(systemName: "person.2")
                    .font(.system(size: 12))
                Text("\(channel.memberCount)")
                    .font(.pulsyncCaption)
            }
            .foregroundStyle(PulsyncTheme.textMuted)
            .padding(.horizontal, PulsyncSpacing.sm)
            .padding(.vertical, PulsyncSpacing.xs)
            .background(PulsyncTheme.surface)
            .clipShape(Capsule())

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

                    Text("#")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(PulsyncTheme.primary)
                }
                .frame(width: 56, height: 56)

                VStack(alignment: .leading, spacing: 4) {
                    Text(channel.displayName)
                        .font(.pulsyncTitle2)
                        .foregroundStyle(PulsyncTheme.textPrimary)

                    Text("This is the very beginning of \(channel.displayName)")
                        .font(.pulsyncBody)
                        .foregroundStyle(PulsyncTheme.textMuted)
                }
            }

            Text(channel.description)
                .font(.pulsyncBody)
                .foregroundStyle(PulsyncTheme.textSecondary)
        }
        .padding(PulsyncSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PulsyncTheme.surface.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: PulsyncRadius.lg))
    }

    // MARK: - Send Message

    private func sendMessage(_ text: String) {
        let newMessage = ChannelMessage(
            channelId: channel.id,
            sender: MockChatData.currentUser,
            body: text,
            createdAt: Date()
        )
        messages.append(newMessage)

        // Scroll to bottom
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation {
                scrollProxy?.scrollTo(newMessage.id, anchor: .bottom)
            }
        }
    }
}

#Preview {
    ChannelChatView(channel: MockChatData.channels[0])
        .frame(width: 600, height: 500)
}
