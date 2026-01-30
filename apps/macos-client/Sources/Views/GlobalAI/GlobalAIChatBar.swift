import SwiftUI

/// Persistent AI chat input bar displayed at the bottom of the app.
/// Includes text input, dictation button, and send button.
struct GlobalAIChatBar: View {
    @Environment(\.globalAIChat) private var chatState
    @State private var inputText = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        if let state = chatState {
            VStack(spacing: 0) {
                // Expandable response area
                if state.isExpanded && (!state.streamingContent.isEmpty || state.isStreaming) {
                    GlobalAIResponseView(
                        content: state.streamingContent,
                        isStreaming: state.isStreaming,
                        onCollapse: { state.collapse() }
                    )
                    .padding(.horizontal, PulsyncSpacing.md)
                    .padding(.top, PulsyncSpacing.sm)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Error message
                if let error = state.error {
                    HStack(spacing: PulsyncSpacing.xs) {
                        Image(systemName: PulsyncIcons.error)
                            .foregroundStyle(PulsyncTheme.error)
                        Text(error)
                            .font(.pulsyncCaption)
                            .foregroundStyle(PulsyncTheme.error)
                        Spacer()
                        Button {
                            state.error = nil
                        } label: {
                            Image(systemName: PulsyncIcons.close)
                                .font(.system(size: 12))
                                .foregroundStyle(PulsyncTheme.textMuted)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, PulsyncSpacing.md)
                    .padding(.vertical, PulsyncSpacing.xs)
                }

                // Input row
                inputRow(state: state)
            }
            .background(PulsyncTheme.background)
            .animation(.easeInOut(duration: 0.2), value: state.isExpanded)
        }
    }

    @ViewBuilder
    private func inputRow(state: GlobalAIChatState) -> some View {
        HStack(alignment: .bottom, spacing: PulsyncSpacing.sm) {
            // Dictation button
            DictationButton { transcribedText in
                inputText = transcribedText
            }

            // Text input
            TextField("Ask AI anything...", text: $inputText, axis: .vertical)
                .font(.pulsyncBody)
                .foregroundStyle(.white)
                .focused($isFocused)
                .lineLimit(1...6)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(PulsyncTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: PulsyncRadius.xl))
                .overlay(
                    RoundedRectangle(cornerRadius: PulsyncRadius.xl)
                        .strokeBorder(
                            isFocused ? PulsyncTheme.primary.opacity(0.5) : PulsyncTheme.border,
                            lineWidth: 1
                        )
                )

            // Send/Stop button
            if state.isStreaming {
                Button(action: { state.stopStreaming() }) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 14))
                        .frame(width: 36, height: 36)
                        .background(PulsyncTheme.error)
                        .foregroundStyle(.white)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Stop generating")
            } else {
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(width: 36, height: 36)
                        .background(inputText.isEmpty ? PulsyncTheme.textMuted : PulsyncTheme.primary)
                        .foregroundStyle(.white)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(inputText.isEmpty)
                .keyboardShortcut(.return, modifiers: .command)
                .help("Send message (Cmd+Return)")
            }
        }
        .padding(.horizontal, PulsyncSpacing.md)
        .padding(.vertical, PulsyncSpacing.sm)
    }

    private func sendMessage() {
        guard let state = chatState else { return }
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let message = inputText
        inputText = ""

        Task {
            await state.sendMessage(message)
        }
    }
}
