import SwiftUI

struct AIChatConversationView: View {
    let session: AIChatSession
    let onSessionUpdated: (AIChatSession) -> Void

    @State private var messages: [AIChatMessage] = []
    @State private var isLoading = false
    @State private var error: String?
    @State private var isStreaming = false
    @State private var streamingContent = ""
    @State private var sseClient: SSEClient?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            AIChatHeaderView(session: session)

            Divider()

            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(messages) { message in
                            AIChatBubble(message: message)
                                .id(message.id)
                        }

                        // Streaming message
                        if isStreaming && !streamingContent.isEmpty {
                            AIChatBubble(
                                role: "assistant",
                                content: streamingContent,
                                isStreaming: true
                            )
                            .id("streaming")
                        }

                        // Typing indicator
                        if isStreaming && streamingContent.isEmpty {
                            TypingIndicator()
                                .id("typing")
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) { _, _ in
                    scrollToBottom(proxy)
                }
                .onChange(of: streamingContent) { _, _ in
                    scrollToBottom(proxy)
                }
            }

            Divider()

            // Input
            AIChatInputView(
                isStreaming: isStreaming,
                onSend: sendMessage,
                onStop: stopStreaming
            )
        }
        .background(PulsyncTheme.background)
        .task {
            await loadSession()
        }
        .onChange(of: session.id) { _, _ in
            stopStreaming()
            Task { await loadSession() }
        }
        .onDisappear {
            stopStreaming()
        }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        withAnimation {
            if isStreaming {
                proxy.scrollTo("streaming", anchor: .bottom)
            } else if let lastMessage = messages.last {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }

    private func loadSession() async {
        isLoading = true
        error = nil
        streamingContent = ""

        do {
            let fullSession = try await APIClient.shared.getAIChatSession(id: session.id)
            messages = fullSession.messages
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    private func sendMessage(_ content: String) {
        guard !content.isEmpty else { return }

        // Add user message optimistically
        let tempUserMessage = AIChatMessage(
            id: UUID(),
            sessionId: session.id,
            role: "user",
            content: content,
            createdAt: Date()
        )
        messages.append(tempUserMessage)

        // Start streaming
        isStreaming = true
        streamingContent = ""

        Task { @MainActor in
            do {
                let request = try APIClient.shared.makeAIChatMessageRequest(sessionId: session.id, content: content)

                sseClient = SSEClient()
                sseClient?.stream(
                    request: request,
                    onEvent: { [self] _, data in
                        handleSSEEvent(data)
                    },
                    onComplete: { [self] in
                        finishStreaming()
                    },
                    onError: { [self] error in
                        handleStreamingError(error)
                    }
                )
            } catch {
                handleStreamingError(error)
            }
        }
    }

    private func handleSSEEvent(_ data: String) {
        guard let event = AIChatSSEEvent.parse(from: data) else { return }

        switch event {
        case .userMessage(let id):
            // Update the user message with the real ID
            if let index = messages.lastIndex(where: { $0.role == "user" }) {
                let oldMessage = messages[index]
                messages[index] = AIChatMessage(
                    id: id,
                    sessionId: oldMessage.sessionId,
                    role: oldMessage.role,
                    content: oldMessage.content,
                    createdAt: oldMessage.createdAt
                )
            }

        case .text(let content):
            streamingContent += content

        case .done(let assistantMessageId):
            finishStreaming(assistantMessageId: assistantMessageId)

        case .error(let message):
            handleStreamingError(NSError(domain: "AI", code: 0, userInfo: [NSLocalizedDescriptionKey: message]))
        }
    }

    private func finishStreaming(assistantMessageId: UUID? = nil) {
        if !streamingContent.isEmpty {
            let assistantMessage = AIChatMessage(
                id: assistantMessageId ?? UUID(),
                sessionId: session.id,
                role: "assistant",
                content: streamingContent,
                createdAt: Date()
            )
            messages.append(assistantMessage)
        }

        isStreaming = false
        streamingContent = ""
        sseClient = nil

        // Update session title if it changed
        Task {
            if let updatedSession = try? await APIClient.shared.getAIChatSession(id: session.id) {
                let newSession = AIChatSession(
                    id: updatedSession.id,
                    title: updatedSession.title,
                    createdAt: updatedSession.createdAt,
                    updatedAt: updatedSession.updatedAt
                )
                onSessionUpdated(newSession)
            }
        }
    }

    private func handleStreamingError(_ error: Error) {
        self.error = error.localizedDescription
        isStreaming = false
        streamingContent = ""
        sseClient = nil
    }

    private func stopStreaming() {
        sseClient?.cancel()
        sseClient = nil

        if !streamingContent.isEmpty {
            // Keep partial response
            let partialMessage = AIChatMessage(
                id: UUID(),
                sessionId: session.id,
                role: "assistant",
                content: streamingContent + "\n\n*[Response stopped]*",
                createdAt: Date()
            )
            messages.append(partialMessage)
        }

        isStreaming = false
        streamingContent = ""
    }
}

struct AIChatHeaderView: View {
    let session: AIChatSession

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
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(session.displayTitle)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text("Pulsync AI Assistant")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }

            Spacer()
        }
        .padding()
        .background(PulsyncTheme.surface)
    }
}
