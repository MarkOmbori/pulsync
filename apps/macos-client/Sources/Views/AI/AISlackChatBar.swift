import SwiftUI

/// Persistent AI chat bar for Slack-related queries.
/// Displays at the bottom of the chat views and allows users to ask questions about their Slack workspace.
struct AISlackChatBar: View {
    @State private var assistant = ClaudeSlackAssistant()
    @State private var inputText = ""
    @FocusState private var isFocused: Bool

    /// Optional current channel for context
    var currentChannel: SlackChannel?

    var body: some View {
        VStack(spacing: 0) {
            // Expandable response area
            if assistant.isExpanded && (!assistant.streamingContent.isEmpty || assistant.isProcessing) {
                AISlackResponseView(
                    content: assistant.streamingContent,
                    isProcessing: assistant.isProcessing,
                    contextSummary: assistant.messages.last?.slackContext,
                    onCollapse: { assistant.collapse() },
                    onClear: { assistant.clearHistory() }
                )
                .padding(.horizontal, PulsyncSpacing.md)
                .padding(.top, PulsyncSpacing.sm)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Error message
            if let error = assistant.error {
                errorRow(error: error)
            }

            // Input row
            inputRow
        }
        .background(PulsyncTheme.background)
        .animation(.easeInOut(duration: 0.2), value: assistant.isExpanded)
    }

    // MARK: - Error Row

    @ViewBuilder
    private func errorRow(error: String) -> some View {
        HStack(spacing: PulsyncSpacing.xs) {
            Image(systemName: PulsyncIcons.error)
                .foregroundStyle(PulsyncTheme.error)
            Text(error)
                .font(.pulsyncCaption)
                .foregroundStyle(PulsyncTheme.error)
            Spacer()
            Button {
                assistant.error = nil
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

    // MARK: - Input Row

    @ViewBuilder
    private var inputRow: some View {
        HStack(alignment: .bottom, spacing: PulsyncSpacing.sm) {
            // Slack context indicator
            if let channel = currentChannel {
                HStack(spacing: 4) {
                    Image(systemName: "number")
                        .font(.system(size: 10))
                    Text(channel.name)
                        .font(.pulsyncCaption)
                }
                .foregroundStyle(PulsyncTheme.primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(PulsyncTheme.primary.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: PulsyncRadius.sm))
            }

            // Dictation button
            DictationButton { transcribedText in
                inputText = transcribedText
            }

            // Text input
            TextField("Ask about Slack...", text: $inputText, axis: .vertical)
                .font(.pulsyncBody)
                .foregroundStyle(.white)
                .focused($isFocused)
                .lineLimit(1...6)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.black)
                .clipShape(RoundedRectangle(cornerRadius: PulsyncRadius.xl))
                .overlay(
                    RoundedRectangle(cornerRadius: PulsyncRadius.xl)
                        .strokeBorder(
                            isFocused ? PulsyncTheme.primary.opacity(0.5) : PulsyncTheme.border,
                            lineWidth: 1
                        )
                )

            // Send/Stop button
            if assistant.isProcessing {
                Button(action: { /* Stop not implemented for non-streaming */ }) {
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

    // MARK: - Actions

    private func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let message = inputText
        inputText = ""

        Task {
            do {
                _ = try await assistant.ask(message, currentChannel: currentChannel)
            } catch {
                // Error is already handled by the assistant
            }
        }
    }
}

// MARK: - Slack Response View

/// Expandable response area for Slack AI queries with context display.
struct AISlackResponseView: View {
    let content: String
    let isProcessing: Bool
    let contextSummary: SlackContextSummary?
    let onCollapse: () -> Void
    let onClear: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with context info and actions
            HStack {
                HStack(spacing: PulsyncSpacing.xs) {
                    Image(systemName: PulsyncIcons.ai)
                        .foregroundStyle(PulsyncTheme.primary)
                    Text("Slack AI")
                        .font(.pulsyncCaption)
                        .foregroundStyle(PulsyncTheme.textSecondary)

                    // Context info
                    if let context = contextSummary {
                        Text("•")
                            .foregroundStyle(PulsyncTheme.textMuted)
                        if !context.channelNames.isEmpty {
                            Text("#\(context.channelNames.joined(separator: ", "))")
                                .font(.pulsyncMicro)
                                .foregroundStyle(PulsyncTheme.primary.opacity(0.8))
                        }
                        if context.messageCount > 0 {
                            Text("(\(context.messageCount) messages)")
                                .font(.pulsyncMicro)
                                .foregroundStyle(PulsyncTheme.textMuted)
                        }
                    }
                }

                Spacer()

                // Clear button
                Button(action: onClear) {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundStyle(PulsyncTheme.textMuted)
                        .frame(width: 24, height: 24)
                        .background(PulsyncTheme.surface)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Clear conversation")

                // Collapse button
                Button(action: onCollapse) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(PulsyncTheme.textMuted)
                        .frame(width: 24, height: 24)
                        .background(PulsyncTheme.surface)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Collapse response")
            }
            .padding(.horizontal, PulsyncSpacing.md)
            .padding(.vertical, PulsyncSpacing.sm)

            Divider()
                .background(PulsyncTheme.border)

            // Content area
            ScrollView {
                VStack(alignment: .leading, spacing: PulsyncSpacing.sm) {
                    if content.isEmpty && isProcessing {
                        processingIndicator
                    } else {
                        MarkdownView(content: content, isStreaming: isProcessing)
                    }
                }
                .padding(PulsyncSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 250)
        }
        .background(PulsyncTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: PulsyncRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: PulsyncRadius.lg)
                .strokeBorder(PulsyncTheme.border, lineWidth: 1)
        )
    }

    @ViewBuilder
    private var processingIndicator: some View {
        HStack(spacing: PulsyncSpacing.sm) {
            ProgressView()
                .scaleEffect(0.8)
                .tint(PulsyncTheme.primary)
            VStack(alignment: .leading, spacing: 2) {
                Text("Analyzing Slack messages...")
                    .font(.pulsyncBody)
                    .foregroundStyle(PulsyncTheme.textMuted)
                if let context = contextSummary, context.messageCount > 0 {
                    Text("Reading \(context.messageCount) messages")
                        .font(.pulsyncMicro)
                        .foregroundStyle(PulsyncTheme.textMuted.opacity(0.7))
                }
            }
        }
    }
}

// MARK: - Quick Actions

/// Quick action buttons for common Slack AI queries
struct SlackAIQuickActions: View {
    let channel: SlackChannel?
    let onAction: (String) -> Void

    private let actions = [
        ("Summarize", "doc.text", "Summarize this channel"),
        ("Action items", "checkmark.circle", "What action items are mentioned?"),
        ("Key decisions", "arrow.triangle.branch", "What decisions were made?"),
        ("Questions", "questionmark.circle", "What questions were asked?")
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: PulsyncSpacing.sm) {
                ForEach(actions, id: \.0) { action in
                    Button {
                        onAction(action.2)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: action.1)
                                .font(.system(size: 12))
                            Text(action.0)
                                .font(.pulsyncCaption)
                        }
                        .foregroundStyle(PulsyncTheme.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(PulsyncTheme.surface)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .strokeBorder(PulsyncTheme.border, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, PulsyncSpacing.md)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        Spacer()
        AISlackChatBar(currentChannel: nil)
    }
    .frame(width: 600, height: 400)
    .background(PulsyncTheme.background)
}
