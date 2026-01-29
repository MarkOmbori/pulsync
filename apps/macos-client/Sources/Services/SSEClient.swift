import Foundation

/// A client for handling Server-Sent Events (SSE) streams
class SSEClient: NSObject, URLSessionDataDelegate {
    private var task: URLSessionDataTask?
    private var session: URLSession?
    private var buffer = ""

    private var onEvent: ((String, String) -> Void)?
    private var onComplete: (() -> Void)?
    private var onError: ((Error) -> Void)?

    var isCancelled = false

    override init() {
        super.init()
    }

    /// Start streaming SSE events from the given request
    /// - Parameters:
    ///   - request: The URLRequest to stream from
    ///   - onEvent: Called for each SSE event with (event name, data)
    ///   - onComplete: Called when the stream ends normally
    ///   - onError: Called if an error occurs
    func stream(
        request: URLRequest,
        onEvent: @escaping (String, String) -> Void,
        onComplete: @escaping () -> Void,
        onError: @escaping (Error) -> Void
    ) {
        self.onEvent = onEvent
        self.onComplete = onComplete
        self.onError = onError
        self.isCancelled = false
        self.buffer = ""

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 300 // 5 minute timeout for streaming
        config.timeoutIntervalForResource = 300

        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        task = session?.dataTask(with: request)
        task?.resume()
    }

    /// Cancel the current stream
    func cancel() {
        isCancelled = true
        task?.cancel()
        task = nil
        session?.invalidateAndCancel()
        session = nil
    }

    // MARK: - URLSessionDataDelegate

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard !isCancelled else { return }

        if let string = String(data: data, encoding: .utf8) {
            buffer += string
            processBuffer()
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if isCancelled { return }

        if let error = error {
            // Don't report cancellation as an error
            if (error as NSError).code != NSURLErrorCancelled {
                DispatchQueue.main.async { [weak self] in
                    self?.onError?(error)
                }
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.onComplete?()
            }
        }

        cleanup()
    }

    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
    ) {
        guard !isCancelled else {
            completionHandler(.cancel)
            return
        }

        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode >= 400 {
                let error = NSError(
                    domain: "SSEClient",
                    code: httpResponse.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode)"]
                )
                DispatchQueue.main.async { [weak self] in
                    self?.onError?(error)
                }
                completionHandler(.cancel)
                return
            }
        }

        completionHandler(.allow)
    }

    // MARK: - Private Methods

    private func processBuffer() {
        // SSE format: data: {...}\n\n
        let events = buffer.components(separatedBy: "\n\n")

        // Keep the last incomplete chunk in the buffer
        if !buffer.hasSuffix("\n\n") {
            buffer = events.last ?? ""
        } else {
            buffer = ""
        }

        // Process complete events (all but the last if buffer doesn't end with \n\n)
        let completeEvents = buffer.isEmpty ? events : Array(events.dropLast())

        for event in completeEvents {
            let trimmed = event.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            // Parse "data: {...}" format
            if trimmed.hasPrefix("data: ") {
                let dataContent = String(trimmed.dropFirst(6))
                DispatchQueue.main.async { [weak self] in
                    self?.onEvent?("data", dataContent)
                }
            }
        }
    }

    private func cleanup() {
        task = nil
        session = nil
        buffer = ""
        onEvent = nil
        onComplete = nil
        onError = nil
    }
}
