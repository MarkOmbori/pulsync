import SwiftUI

struct AIChatView: View {
    @State private var sessions: [AIChatSession] = []
    @State private var selectedSession: AIChatSession?
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        NavigationSplitView {
            AIChatSessionList(
                sessions: sessions,
                selectedSession: $selectedSession,
                onNewSession: createNewSession,
                onDeleteSession: deleteSession,
                onRefresh: loadSessions
            )
            .navigationTitle("AI Assistant")
        } detail: {
            if let session = selectedSession {
                AIChatConversationView(
                    session: session,
                    onSessionUpdated: { updatedSession in
                        // Update the session in our list
                        if let index = sessions.firstIndex(where: { $0.id == updatedSession.id }) {
                            sessions[index] = updatedSession
                        }
                        selectedSession = updatedSession
                    }
                )
            } else {
                AIChatWelcomeView(onNewChat: createNewSession)
            }
        }
        .task {
            await loadSessions()
        }
    }

    private func loadSessions() async {
        isLoading = true
        error = nil

        do {
            sessions = try await APIClient.shared.getAIChatSessions()
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    private func createNewSession() {
        Task {
            do {
                let session = try await APIClient.shared.createAIChatSession()
                sessions.insert(session, at: 0)
                selectedSession = session
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    private func deleteSession(_ session: AIChatSession) {
        Task {
            do {
                try await APIClient.shared.deleteAIChatSession(id: session.id)
                sessions.removeAll { $0.id == session.id }
                if selectedSession?.id == session.id {
                    selectedSession = nil
                }
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
}

#Preview {
    AIChatView()
}
