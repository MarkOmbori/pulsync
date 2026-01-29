import SwiftUI

struct InboxView: View {
    @State private var conversations: [Conversation] = []
    @State private var selectedConversation: Conversation?
    @State private var isLoading = false
    @State private var error: String?
    @State private var showNewConversation = false

    var body: some View {
        NavigationSplitView {
            ConversationListView(
                conversations: conversations,
                selectedConversation: $selectedConversation,
                onRefresh: loadConversations,
                onNewConversation: { showNewConversation = true }
            )
            .navigationTitle("Inbox")
        } detail: {
            if let conversation = selectedConversation {
                ChatView(
                    conversation: conversation,
                    onMessageSent: {
                        // Refresh conversations to update last message
                        Task { await loadConversations() }
                    }
                )
            } else {
                EmptyInboxView()
            }
        }
        .sheet(isPresented: $showNewConversation) {
            NewConversationSheet(
                isPresented: $showNewConversation,
                onConversationCreated: { conversation in
                    conversations.insert(conversation, at: 0)
                    selectedConversation = conversation
                }
            )
        }
        .task {
            await loadConversations()
        }
    }

    private func loadConversations() async {
        isLoading = true
        error = nil

        do {
            conversations = try await APIClient.shared.getConversations()
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

struct EmptyInboxView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 48))
                .foregroundStyle(.gray)

            Text("Select a conversation")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text("Or start a new one")
                .font(.body)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PulsyncTheme.background)
    }
}

#Preview {
    InboxView()
}
