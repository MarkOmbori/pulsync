import SwiftUI

struct ConversationListView: View {
    let conversations: [Conversation]
    @Binding var selectedConversation: Conversation?
    let onRefresh: () async -> Void
    let onNewConversation: () -> Void

    @State private var isRefreshing = false

    var body: some View {
        VStack(spacing: 0) {
            // New conversation button
            Button(action: onNewConversation) {
                HStack {
                    Image(systemName: "square.and.pencil")
                    Text("New Message")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.electricViolet)
                .foregroundStyle(.white)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .padding()

            Divider()

            if conversations.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.largeTitle)
                        .foregroundStyle(.gray)
                    Text("No conversations yet")
                        .foregroundStyle(.secondary)
                }
                Spacer()
            } else {
                List(conversations, selection: $selectedConversation) { conversation in
                    ConversationRow(
                        conversation: conversation,
                        isSelected: selectedConversation?.id == conversation.id
                    )
                    .tag(conversation)
                    .listRowBackground(
                        selectedConversation?.id == conversation.id
                            ? PulsyncTheme.primary.opacity(0.2)
                            : Color.clear
                    )
                }
                .listStyle(.plain)
                .refreshable {
                    await onRefresh()
                }
            }
        }
        .background(PulsyncTheme.surface)
        .frame(minWidth: 280)
    }
}

struct ConversationRow: View {
    let conversation: Conversation
    let isSelected: Bool

    private var currentUserId: UUID? {
        AuthState.shared.currentUser?.id
    }

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.electricViolet.opacity(0.3))

                if let avatarUrl = conversation.avatarUrl(currentUserId: currentUserId ?? UUID()),
                   let url = URL(string: avatarUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        initialsView
                    }
                    .clipShape(Circle())
                } else {
                    initialsView
                }
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.displayName(currentUserId: currentUserId ?? UUID()))
                        .font(.headline)
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Spacer()

                    if let lastMessage = conversation.lastMessage {
                        Text(lastMessage.createdAt, style: .relative)
                            .font(.caption2)
                            .foregroundStyle(.gray)
                    }
                }

                HStack {
                    if let lastMessage = conversation.lastMessage {
                        Text(lastMessage.body)
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                            .lineLimit(1)
                    } else {
                        Text("No messages yet")
                            .font(.subheadline)
                            .foregroundStyle(.gray.opacity(0.6))
                            .italic()
                    }

                    Spacer()

                    if conversation.unreadCount > 0 {
                        Text("\(conversation.unreadCount)")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.electricViolet)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    private var initialsView: some View {
        Text(String(conversation.displayName(currentUserId: currentUserId ?? UUID()).prefix(1)).uppercased())
            .font(.headline.bold())
            .foregroundStyle(Color.electricViolet)
    }
}
