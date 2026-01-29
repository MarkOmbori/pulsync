import SwiftUI

struct ChatView: View {
    let conversation: Conversation
    let onMessageSent: () -> Void

    @State private var messages: [Message] = []
    @State private var isLoading = false
    @State private var error: String?

    private var currentUserId: UUID? {
        AuthState.shared.currentUser?.id
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            ChatHeaderView(conversation: conversation, currentUserId: currentUserId ?? UUID())

            Divider()

            // Messages
            if isLoading && messages.isEmpty {
                Spacer()
                ProgressView()
                Spacer()
            } else if let error = error, messages.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title)
                        .foregroundStyle(.orange)
                    Text(error)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(messages) { message in
                                MessageBubble(
                                    message: message,
                                    isFromCurrentUser: message.senderId == currentUserId
                                )
                                .id(message.id)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: messages.count) { _, _ in
                        if let lastMessage = messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }

            Divider()

            // Input
            MessageInputView(
                conversationId: conversation.id,
                onMessageSent: { message in
                    messages.append(message)
                    onMessageSent()
                }
            )
        }
        .background(PulsyncTheme.background)
        .task {
            await loadMessages()
        }
        .onChange(of: conversation.id) { _, _ in
            Task { await loadMessages() }
        }
    }

    private func loadMessages() async {
        isLoading = true
        error = nil

        do {
            let conversationDetail = try await APIClient.shared.getConversation(id: conversation.id)
            messages = conversationDetail.messages
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

struct ChatHeaderView: View {
    let conversation: Conversation
    let currentUserId: UUID

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.electricViolet.opacity(0.3))

                Text(String(conversation.displayName(currentUserId: currentUserId).prefix(1)).uppercased())
                    .font(.headline.bold())
                    .foregroundStyle(Color.electricViolet)
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(conversation.displayName(currentUserId: currentUserId))
                    .font(.headline)
                    .foregroundStyle(.white)

                let others = conversation.participants.filter { $0.userId != currentUserId }
                if others.count == 1 {
                    Text(others.first?.user.department ?? "")
                        .font(.caption)
                        .foregroundStyle(.gray)
                } else {
                    Text("\(others.count) participants")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
            }

            Spacer()
        }
        .padding()
        .background(PulsyncTheme.surface)
    }
}
