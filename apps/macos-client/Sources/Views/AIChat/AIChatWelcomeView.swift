import SwiftUI

struct AIChatWelcomeView: View {
    let onNewChat: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Logo/Icon
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.electricViolet.opacity(0.2), Color.electricViolet.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 120, height: 120)

                Circle()
                    .fill(LinearGradient(
                        colors: [Color.electricViolet, Color.electricViolet.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 80, height: 80)

                Image(systemName: "sparkles")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(.white)
            }

            // Title
            VStack(spacing: 8) {
                Text("Pulsync AI Assistant")
                    .font(.title.bold())
                    .foregroundStyle(.white)

                Text("Your intelligent workplace companion")
                    .font(.body)
                    .foregroundStyle(.gray)
            }

            // Suggestions
            VStack(alignment: .leading, spacing: 12) {
                Text("Try asking about:")
                    .font(.caption)
                    .foregroundStyle(.gray)

                SuggestionButton(
                    icon: "doc.text",
                    title: "Company Policies",
                    description: "\"What's our remote work policy?\""
                )

                SuggestionButton(
                    icon: "pencil",
                    title: "Draft Communications",
                    description: "\"Help me write a team update\""
                )

                SuggestionButton(
                    icon: "questionmark.circle",
                    title: "Platform Help",
                    description: "\"How do I create a new post?\""
                )

                SuggestionButton(
                    icon: "lightbulb",
                    title: "General Questions",
                    description: "\"Best practices for remote meetings\""
                )
            }
            .padding()
            .background(PulsyncTheme.surface.opacity(0.5))
            .cornerRadius(12)

            // Start button
            Button(action: onNewChat) {
                HStack {
                    Image(systemName: "plus.bubble")
                    Text("Start New Chat")
                }
                .font(.headline)
                .frame(maxWidth: 200)
                .padding(.vertical, 14)
                .background(Color.electricViolet)
                .foregroundStyle(.white)
                .cornerRadius(25)
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PulsyncTheme.background)
    }
}

struct SuggestionButton: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Color.electricViolet)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
        }
    }
}

#Preview {
    AIChatWelcomeView(onNewChat: {})
}
