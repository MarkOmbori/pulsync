import SwiftUI

struct ChannelInputView: View {
    let channelName: String
    let onSend: (String) -> Void

    @State private var messageText = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .background(PulsyncTheme.border)

            HStack(alignment: .bottom, spacing: PulsyncSpacing.sm) {
                // Attachment button
                Button(action: {}) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(PulsyncTheme.textMuted)
                }
                .buttonStyle(.plain)

                // Text input
                ZStack(alignment: .leading) {
                    if messageText.isEmpty {
                        Text("Message #\(channelName)")
                            .font(.pulsyncBody)
                            .foregroundStyle(PulsyncTheme.textMuted)
                            .padding(.leading, PulsyncSpacing.ms)
                    }

                    TextField("", text: $messageText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(.pulsyncBody)
                        .foregroundStyle(PulsyncTheme.textPrimary)
                        .padding(.horizontal, PulsyncSpacing.ms)
                        .padding(.vertical, PulsyncSpacing.sm)
                        .focused($isFocused)
                        .lineLimit(1...5)
                        .onSubmit {
                            sendMessage()
                        }
                }
                .background(PulsyncTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: PulsyncRadius.lg))

                // Emoji button
                Button(action: {}) {
                    Image(systemName: "face.smiling")
                        .font(.system(size: 20))
                        .foregroundStyle(PulsyncTheme.textMuted)
                }
                .buttonStyle(.plain)

                // Send button
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(messageText.isEmpty ? PulsyncTheme.textMuted : PulsyncTheme.primary)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(messageText.isEmpty ? Color.clear : PulsyncTheme.primary.opacity(0.15))
                        )
                }
                .buttonStyle(.plain)
                .disabled(messageText.isEmpty)
            }
            .padding(.horizontal, PulsyncSpacing.md)
            .padding(.vertical, PulsyncSpacing.sm)
        }
        .background(PulsyncTheme.background)
    }

    private func sendMessage() {
        let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        onSend(trimmed)
        messageText = ""
    }
}

#Preview {
    VStack {
        Spacer()
        ChannelInputView(channelName: "general") { text in
            print("Sent: \(text)")
        }
    }
    .frame(width: 600, height: 200)
    .background(PulsyncTheme.background)
}
