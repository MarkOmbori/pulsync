import SwiftUI

struct AIChatInputView: View {
    let isStreaming: Bool
    let onSend: (String) -> Void
    let onStop: () -> Void

    @State private var inputText = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            // Text input
            ZStack(alignment: .topLeading) {
                if inputText.isEmpty {
                    Text("Ask anything...")
                        .foregroundStyle(.gray)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                }

                TextEditor(text: $inputText)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .focused($isFocused)
                    .frame(minHeight: 20, maxHeight: 100)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
            }
            .background(PulsyncTheme.surface)
            .cornerRadius(20)

            // Send/Stop button
            if isStreaming {
                Button(action: onStop) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 14))
                        .frame(width: 40, height: 40)
                        .background(Color.red)
                        .foregroundStyle(.white)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Stop generating")
            } else {
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 40, height: 40)
                        .background(inputText.isEmpty ? Color.gray : Color.electricViolet)
                        .foregroundStyle(.white)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(inputText.isEmpty)
                .keyboardShortcut(.return, modifiers: .command)
                .help("Send message (⌘Return)")
            }
        }
        .padding()
        .background(PulsyncTheme.background)
    }

    private func sendMessage() {
        guard !inputText.isEmpty else { return }
        let text = inputText
        inputText = ""
        onSend(text)
    }
}
