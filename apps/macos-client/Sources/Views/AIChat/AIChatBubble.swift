import SwiftUI

struct AIChatBubble: View {
    let role: String
    let content: String
    let isStreaming: Bool

    init(message: AIChatMessage) {
        self.role = message.role
        self.content = message.content
        self.isStreaming = false
    }

    init(role: String, content: String, isStreaming: Bool = false) {
        self.role = role
        self.content = content
        self.isStreaming = isStreaming
    }

    private var isUser: Bool { role == "user" }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if isUser {
                Spacer(minLength: 40)
            } else {
                // AI avatar
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color.electricViolet, Color.electricViolet.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))

                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .frame(width: 32, height: 32)
            }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                Text(isUser ? "You" : "Assistant")
                    .font(.caption2)
                    .foregroundStyle(.gray)

                if isUser {
                    Text(content)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.electricViolet)
                        .foregroundStyle(.white)
                        .cornerRadius(16, corners: [.topLeft, .topRight, .bottomLeft])
                } else {
                    MarkdownView(content: content, isStreaming: isStreaming)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(PulsyncTheme.surface)
                        .foregroundStyle(.white)
                        .cornerRadius(16, corners: [.topLeft, .topRight, .bottomRight])
                }
            }

            if !isUser {
                Spacer(minLength: 40)
            } else {
                // User avatar
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.3))

                    if let user = AuthState.shared.currentUser {
                        Text(String(user.displayName.prefix(1)).uppercased())
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                    } else {
                        Image(systemName: "person.fill")
                            .font(.caption)
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: 32, height: 32)
            }
        }
    }
}
