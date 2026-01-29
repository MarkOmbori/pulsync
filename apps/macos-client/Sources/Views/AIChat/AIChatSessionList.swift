import SwiftUI

struct AIChatSessionList: View {
    let sessions: [AIChatSession]
    @Binding var selectedSession: AIChatSession?
    let onNewSession: () -> Void
    let onDeleteSession: (AIChatSession) -> Void
    let onRefresh: () async -> Void

    var body: some View {
        VStack(spacing: 0) {
            // New chat button
            Button(action: onNewSession) {
                HStack {
                    Image(systemName: "plus.bubble")
                    Text("New Chat")
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

            if sessions.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "bubble.left.and.text.bubble.right")
                        .font(.largeTitle)
                        .foregroundStyle(.gray)
                    Text("No conversations yet")
                        .foregroundStyle(.secondary)
                    Text("Start a new chat!")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
            } else {
                List(sessions, selection: $selectedSession) { session in
                    AIChatSessionRow(session: session, isSelected: selectedSession?.id == session.id)
                        .tag(session)
                        .contextMenu {
                            Button(role: .destructive) {
                                onDeleteSession(session)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .listRowBackground(
                            selectedSession?.id == session.id
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
        .frame(minWidth: 250)
    }
}

struct AIChatSessionRow: View {
    let session: AIChatSession
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            // AI icon
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.electricViolet, Color.electricViolet.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))

                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(session.displayTitle)
                    .font(.body)
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(session.updatedAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.gray)
            }

            Spacer()
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}
