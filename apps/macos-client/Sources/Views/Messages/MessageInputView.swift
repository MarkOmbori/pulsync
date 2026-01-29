import SwiftUI

struct MessageInputView: View {
    let conversationId: UUID
    let onMessageSent: (Message) -> Void

    @State private var messageText = ""
    @State private var isSending = false

    var body: some View {
        HStack(spacing: 12) {
            TextField("Type a message...", text: $messageText, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(PulsyncTheme.surface)
                .cornerRadius(20)
                .lineLimit(1...5)
                .onSubmit {
                    if !messageText.isEmpty && !isSending {
                        sendMessage()
                    }
                }

            Button(action: sendMessage) {
                if isSending {
                    ProgressView()
                        .scaleEffect(0.8)
                        .frame(width: 36, height: 36)
                } else {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 16))
                        .frame(width: 36, height: 36)
                        .background(messageText.isEmpty ? Color.gray : Color.electricViolet)
                        .foregroundStyle(.white)
                        .clipShape(Circle())
                }
            }
            .buttonStyle(.plain)
            .disabled(messageText.isEmpty || isSending)
        }
        .padding()
        .background(PulsyncTheme.background)
    }

    private func sendMessage() {
        guard !messageText.isEmpty else { return }

        let text = messageText
        messageText = ""
        isSending = true

        Task {
            do {
                let message = try await APIClient.shared.sendMessage(conversationId: conversationId, body: text)
                onMessageSent(message)
            } catch {
                // Restore text on failure
                messageText = text
            }
            isSending = false
        }
    }
}
