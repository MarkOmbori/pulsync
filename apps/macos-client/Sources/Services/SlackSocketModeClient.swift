import Foundation

/// Connection state for Socket Mode
enum SlackSocketConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
    case reconnecting(attempt: Int)
    case error(String)

    var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }
}

/// Delegate protocol for Socket Mode events
protocol SlackSocketModeDelegate: AnyObject {
    func socketModeDidConnect()
    func socketModeDidDisconnect()
    func socketModeDidReceiveMessage(_ message: SlackMessage, channel: String)
    func socketModeDidReceiveMessageUpdate(_ message: SlackMessage, channel: String)
    func socketModeDidReceiveMessageDelete(ts: String, channel: String)
    func socketModeDidReceiveReactionAdd(reaction: String, userId: String, itemTs: String, channel: String)
    func socketModeDidReceiveReactionRemove(reaction: String, userId: String, itemTs: String, channel: String)
    func socketModeDidReceiveTyping(userId: String, channel: String)
    func socketModeDidReceivePresenceChange(userId: String, presence: String)
    func socketModeDidReceiveError(_ error: Error)
}

/// Optional default implementations
extension SlackSocketModeDelegate {
    func socketModeDidConnect() {}
    func socketModeDidDisconnect() {}
    func socketModeDidReceiveMessageUpdate(_ message: SlackMessage, channel: String) {}
    func socketModeDidReceiveMessageDelete(ts: String, channel: String) {}
    func socketModeDidReceiveReactionAdd(reaction: String, userId: String, itemTs: String, channel: String) {}
    func socketModeDidReceiveReactionRemove(reaction: String, userId: String, itemTs: String, channel: String) {}
    func socketModeDidReceiveTyping(userId: String, channel: String) {}
    func socketModeDidReceivePresenceChange(userId: String, presence: String) {}
    func socketModeDidReceiveError(_ error: Error) {}
}

/// Slack Socket Mode client for real-time events
/// Uses WebSocket connection to receive events without a public-facing URL
@MainActor
@Observable
class SlackSocketModeClient {
    static let shared = SlackSocketModeClient()

    // MARK: - Published State

    var connectionState: SlackSocketConnectionState = .disconnected

    // MARK: - Delegates

    private var delegates: [WeakDelegate] = []

    // MARK: - Private Properties

    private var webSocket: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    private var pingTimer: Timer?
    private var reconnectAttempt = 0
    private let maxReconnectAttempts = 10
    private let baseReconnectDelay: TimeInterval = 1.0

    private let authService: SlackAuthService

    // Track the last debug ID for acknowledgments
    private var lastDebugId: String?

    private init() {
        self.authService = SlackAuthService.shared
    }

    // MARK: - Delegate Management

    func addDelegate(_ delegate: SlackSocketModeDelegate) {
        // Clean up nil references
        delegates.removeAll { $0.delegate == nil }

        // Don't add duplicates
        guard !delegates.contains(where: { $0.delegate === delegate }) else { return }

        delegates.append(WeakDelegate(delegate))
    }

    func removeDelegate(_ delegate: SlackSocketModeDelegate) {
        delegates.removeAll { $0.delegate === delegate || $0.delegate == nil }
    }

    // MARK: - Connection Management

    /// Connect to Slack Socket Mode
    func connect() async throws {
        guard let appToken = authService.getAppToken() else {
            throw SlackSocketModeError.missingAppToken
        }

        connectionState = .connecting
        reconnectAttempt = 0

        // Get WebSocket URL from apps.connections.open
        let wsUrl = try await getWebSocketURL(appToken: appToken)

        // Connect to WebSocket
        try await connectWebSocket(url: wsUrl)
    }

    /// Disconnect from Socket Mode
    func disconnect() {
        stopPingTimer()
        webSocket?.cancel(with: .goingAway, reason: nil)
        webSocket = nil
        urlSession?.invalidateAndCancel()
        urlSession = nil
        connectionState = .disconnected
        notifyDelegates { $0.socketModeDidDisconnect() }
    }

    /// Reconnect with exponential backoff
    func reconnect() async {
        guard reconnectAttempt < maxReconnectAttempts else {
            connectionState = .error("Max reconnect attempts reached")
            return
        }

        reconnectAttempt += 1
        connectionState = .reconnecting(attempt: reconnectAttempt)

        // Exponential backoff with jitter
        let delay = baseReconnectDelay * pow(2.0, Double(reconnectAttempt - 1))
        let jitter = Double.random(in: 0...0.5) * delay
        let totalDelay = min(delay + jitter, 30.0) // Cap at 30 seconds

        try? await Task.sleep(nanoseconds: UInt64(totalDelay * 1_000_000_000))

        do {
            try await connect()
        } catch {
            // Will try again if under max attempts
            await reconnect()
        }
    }

    // MARK: - Private Methods

    private func getWebSocketURL(appToken: String) async throws -> URL {
        let url = URL(string: "https://slack.com/api/apps.connections.open")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(appToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw SlackSocketModeError.connectionFailed("Failed to get WebSocket URL")
        }

        let connectionResponse = try JSONDecoder().decode(SlackAppsConnectionsOpenResponse.self, from: data)

        guard connectionResponse.ok, let urlString = connectionResponse.url, let wsUrl = URL(string: urlString) else {
            throw SlackSocketModeError.connectionFailed(connectionResponse.error ?? "Invalid WebSocket URL")
        }

        return wsUrl
    }

    private func connectWebSocket(url: URL) async throws {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 300

        urlSession = URLSession(configuration: configuration)
        webSocket = urlSession?.webSocketTask(with: url)

        webSocket?.resume()

        // Start receiving messages
        Task {
            await receiveMessages()
        }

        // Wait for hello message
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Task {
                // Give it 10 seconds to receive hello
                try await Task.sleep(nanoseconds: 10_000_000_000)
                if case .connected = connectionState {
                    // Already connected via hello message
                } else {
                    continuation.resume(throwing: SlackSocketModeError.connectionFailed("Timeout waiting for hello"))
                }
            }

            // The hello message handler will resume the continuation
            // For now, we'll just wait and check state
            Task {
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                if case .connected = connectionState {
                    continuation.resume()
                }
            }
        }
    }

    private func receiveMessages() async {
        guard let webSocket = webSocket else { return }

        do {
            while webSocket.state == .running {
                let message = try await webSocket.receive()

                switch message {
                case .string(let text):
                    handleMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        handleMessage(text)
                    }
                @unknown default:
                    break
                }
            }
        } catch {
            // Connection lost
            if connectionState.isConnected {
                connectionState = .disconnected
                notifyDelegates { $0.socketModeDidDisconnect() }
                notifyDelegates { $0.socketModeDidReceiveError(error) }

                // Try to reconnect
                await reconnect()
            }
        }
    }

    private func handleMessage(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }

        do {
            let socketMessage = try JSONDecoder().decode(SlackSocketModeMessage.self, from: data)

            switch socketMessage.type {
            case "hello":
                handleHello()

            case "disconnect":
                handleDisconnect()

            case "events_api":
                if let envelopeId = socketMessage.envelopeId {
                    // Acknowledge the event
                    sendAcknowledgment(envelopeId: envelopeId)
                }

                if let payload = socketMessage.payload, let event = payload.event {
                    handleEvent(event)
                }

            default:
                // Unknown message type
                break
            }
        } catch {
            // Failed to decode message - might be a different format
            print("Failed to decode Socket Mode message: \(error)")
        }
    }

    private func handleHello() {
        connectionState = .connected
        reconnectAttempt = 0
        startPingTimer()
        notifyDelegates { $0.socketModeDidConnect() }
    }

    private func handleDisconnect() {
        disconnect()
        Task {
            await reconnect()
        }
    }

    private func handleEvent(_ event: SlackEvent) {
        switch event.type {
        case "message":
            handleMessageEvent(event)

        case "reaction_added":
            if let reaction = event.reaction,
               let userId = event.user,
               let item = event.item,
               let itemTs = item.ts,
               let channel = item.channel {
                notifyDelegates { $0.socketModeDidReceiveReactionAdd(
                    reaction: reaction,
                    userId: userId,
                    itemTs: itemTs,
                    channel: channel
                )}
            }

        case "reaction_removed":
            if let reaction = event.reaction,
               let userId = event.user,
               let item = event.item,
               let itemTs = item.ts,
               let channel = item.channel {
                notifyDelegates { $0.socketModeDidReceiveReactionRemove(
                    reaction: reaction,
                    userId: userId,
                    itemTs: itemTs,
                    channel: channel
                )}
            }

        case "user_typing":
            if let userId = event.user, let channel = event.channel {
                notifyDelegates { $0.socketModeDidReceiveTyping(userId: userId, channel: channel) }
            }

        case "presence_change":
            // Note: presence_change might have a different structure
            break

        default:
            break
        }
    }

    private func handleMessageEvent(_ event: SlackEvent) {
        guard let channel = event.channel else { return }

        switch event.subtype {
        case nil, "me_message":
            // New message
            if let ts = event.ts, let text = event.text, let user = event.user {
                let message = SlackMessage(
                    type: "message",
                    user: user,
                    text: text,
                    ts: ts,
                    threadTs: event.threadTs,
                    replyCount: nil,
                    replyUsersCount: nil,
                    latestReply: nil,
                    reactions: nil,
                    edited: nil,
                    subtype: event.subtype,
                    botId: nil,
                    username: nil,
                    files: nil,
                    attachments: nil
                )
                notifyDelegates { $0.socketModeDidReceiveMessage(message, channel: channel) }
            }

        case "message_changed":
            if let message = event.message {
                notifyDelegates { $0.socketModeDidReceiveMessageUpdate(message, channel: channel) }
            }

        case "message_deleted":
            if let previousMessage = event.previousMessage {
                notifyDelegates { $0.socketModeDidReceiveMessageDelete(ts: previousMessage.ts, channel: channel) }
            } else if let ts = event.ts {
                notifyDelegates { $0.socketModeDidReceiveMessageDelete(ts: ts, channel: channel) }
            }

        default:
            // Handle other subtypes as new messages if they have required fields
            if let ts = event.ts, let text = event.text {
                let message = SlackMessage(
                    type: "message",
                    user: event.user,
                    text: text,
                    ts: ts,
                    threadTs: event.threadTs,
                    replyCount: nil,
                    replyUsersCount: nil,
                    latestReply: nil,
                    reactions: nil,
                    edited: nil,
                    subtype: event.subtype,
                    botId: nil,
                    username: nil,
                    files: nil,
                    attachments: nil
                )
                notifyDelegates { $0.socketModeDidReceiveMessage(message, channel: channel) }
            }
        }
    }

    private func sendAcknowledgment(envelopeId: String) {
        let ack = SlackSocketModeAck(envelopeId: envelopeId)

        guard let data = try? JSONEncoder().encode(ack),
              let text = String(data: data, encoding: .utf8) else { return }

        webSocket?.send(.string(text)) { error in
            if let error = error {
                print("Failed to send acknowledgment: \(error)")
            }
        }
    }

    // MARK: - Ping Timer

    private func startPingTimer() {
        stopPingTimer()

        pingTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.sendPing()
            }
        }
    }

    private func stopPingTimer() {
        pingTimer?.invalidate()
        pingTimer = nil
    }

    private func sendPing() {
        webSocket?.sendPing { [weak self] error in
            if let error = error {
                print("Ping failed: \(error)")
                Task { @MainActor [weak self] in
                    self?.disconnect()
                    await self?.reconnect()
                }
            }
        }
    }

    // MARK: - Delegate Notification

    private func notifyDelegates(_ action: (SlackSocketModeDelegate) -> Void) {
        delegates.compactMap { $0.delegate }.forEach(action)
    }
}

// MARK: - Helper Types

private class WeakDelegate {
    weak var delegate: SlackSocketModeDelegate?

    init(_ delegate: SlackSocketModeDelegate) {
        self.delegate = delegate
    }
}

// MARK: - Error Types

enum SlackSocketModeError: LocalizedError {
    case missingAppToken
    case connectionFailed(String)
    case notConnected

    var errorDescription: String? {
        switch self {
        case .missingAppToken:
            return "SLACK_APP_TOKEN not configured"
        case .connectionFailed(let reason):
            return "Socket Mode connection failed: \(reason)"
        case .notConnected:
            return "Not connected to Socket Mode"
        }
    }
}

// MARK: - Observable Extensions

extension SlackSocketModeClient {
    /// Subscribe to new messages in a specific channel
    /// Returns an AsyncStream that emits messages for the given channel
    func messageStream(for channelId: String) -> AsyncStream<SlackMessage> {
        AsyncStream { continuation in
            let observer = MessageStreamObserver(channelId: channelId, continuation: continuation)
            addDelegate(observer)

            continuation.onTermination = { @Sendable [weak self, weak observer] _ in
                guard let observer = observer else { return }
                Task { @MainActor in
                    self?.removeDelegate(observer)
                }
            }
        }
    }
}

/// Helper class to bridge delegate to AsyncStream
private final class MessageStreamObserver: SlackSocketModeDelegate, @unchecked Sendable {
    private let channelId: String
    private let continuation: AsyncStream<SlackMessage>.Continuation

    init(channelId: String, continuation: AsyncStream<SlackMessage>.Continuation) {
        self.channelId = channelId
        self.continuation = continuation
    }

    func socketModeDidReceiveMessage(_ message: SlackMessage, channel: String) {
        if channel == channelId {
            continuation.yield(message)
        }
    }

    func socketModeDidDisconnect() {
        continuation.finish()
    }
}
