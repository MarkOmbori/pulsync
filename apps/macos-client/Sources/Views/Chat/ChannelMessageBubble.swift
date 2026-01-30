import SwiftUI

struct ChannelMessageBubble: View {
    let message: ChannelMessage
    @State private var isHovered = false

    var body: some View {
        HStack(alignment: .top, spacing: PulsyncSpacing.sm) {
            // Avatar
            UserAvatarView(user: message.sender, size: 36)

            // Message content
            VStack(alignment: .leading, spacing: PulsyncSpacing.xs) {
                // Sender name and timestamp
                HStack(spacing: PulsyncSpacing.sm) {
                    Text(message.sender.displayName)
                        .font(.pulsyncLabel)
                        .foregroundStyle(PulsyncTheme.textPrimary)

                    Text(formatTimestamp(message.createdAt))
                        .font(.pulsyncCaption)
                        .foregroundStyle(PulsyncTheme.textMuted)

                    if message.isEdited {
                        Text("(edited)")
                            .font(.pulsyncCaption)
                            .foregroundStyle(PulsyncTheme.textMuted)
                    }
                }

                // Message body
                Text(message.body)
                    .font(.pulsyncBody)
                    .foregroundStyle(PulsyncTheme.textPrimary)
                    .textSelection(.enabled)

                // Reactions
                if !message.reactions.isEmpty {
                    HStack(spacing: PulsyncSpacing.xs) {
                        ForEach(message.reactions) { reaction in
                            ReactionPill(reaction: reaction)
                        }
                    }
                    .padding(.top, PulsyncSpacing.xs)
                }

                // Thread replies indicator
                if message.threadReplyCount > 0 {
                    HStack(spacing: PulsyncSpacing.xs) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 12))
                        Text("\(message.threadReplyCount) replies")
                            .font(.pulsyncCaption)
                    }
                    .foregroundStyle(PulsyncTheme.primary)
                    .padding(.top, PulsyncSpacing.xs)
                }
            }

            Spacer()

            // Hover actions
            if isHovered {
                HStack(spacing: 2) {
                    ChatActionButton(icon: "face.smiling")
                    ChatActionButton(icon: "bubble.left")
                    ChatActionButton(icon: "bookmark")
                    ChatActionButton(icon: "ellipsis")
                }
                .padding(4)
                .background(PulsyncTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: PulsyncRadius.sm))
                .elevation(PulsyncElevation.level1)
            }
        }
        .padding(.vertical, PulsyncSpacing.xs)
        .padding(.horizontal, PulsyncSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: PulsyncRadius.md)
                .fill(isHovered ? PulsyncTheme.surface.opacity(0.3) : Color.clear)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }

    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            formatter.dateFormat = "h:mm a"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateFormat = "MMM d"
        }

        return formatter.string(from: date)
    }
}

// MARK: - Reaction Pill

struct ReactionPill: View {
    let reaction: MessageReaction

    var body: some View {
        HStack(spacing: 4) {
            Text(reaction.emoji)
                .font(.system(size: 12))
            Text("\(reaction.count)")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(reaction.userReacted ? PulsyncTheme.primary : PulsyncTheme.textSecondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: PulsyncRadius.full)
                .fill(reaction.userReacted ? PulsyncTheme.primary.opacity(0.15) : PulsyncTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: PulsyncRadius.full)
                        .stroke(reaction.userReacted ? PulsyncTheme.primary.opacity(0.3) : PulsyncTheme.border, lineWidth: 1)
                )
        )
    }
}

// MARK: - Chat Action Button

private struct ChatActionButton: View {
    let icon: String

    var body: some View {
        Button(action: {}) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(PulsyncTheme.textMuted)
                .frame(width: 28, height: 28)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}

#Preview {
    VStack(spacing: 16) {
        ChannelMessageBubble(
            message: ChannelMessage(
                channelId: UUID(),
                sender: MockChatData.sarah,
                body: "Just merged the new caching layer. Performance benchmarks show 40% improvement on cold starts!",
                createdAt: Date().addingTimeInterval(-3600),
                reactions: [
                    MessageReaction(emoji: "🔥", count: 7),
                    MessageReaction(emoji: "💪", count: 4, userReacted: true),
                ],
                threadReplyCount: 3
            )
        )

        ChannelMessageBubble(
            message: ChannelMessage(
                channelId: UUID(),
                sender: MockChatData.marcus,
                body: "PR #234 ready for review - fixed the auth race condition",
                createdAt: Date().addingTimeInterval(-1800)
            )
        )
    }
    .padding()
    .background(PulsyncTheme.background)
    .frame(width: 600)
}
