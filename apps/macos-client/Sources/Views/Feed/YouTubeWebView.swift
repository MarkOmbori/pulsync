import SwiftUI
import WebKit

/// A WKWebView wrapper for playing YouTube videos via embed iframe.
/// AVPlayer cannot play YouTube URLs directly, so we use the official YouTube embed API.
struct YouTubeWebView: NSViewRepresentable {
    let videoId: String

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()

        // Allow autoplay without user interaction
        config.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: config)

        // Make background transparent
        webView.setValue(false, forKey: "drawsBackground")

        loadVideo(in: webView)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        // Only reload if the video ID changed
        if context.coordinator.currentVideoId != videoId {
            context.coordinator.currentVideoId = videoId
            loadVideo(in: webView)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(videoId: videoId)
    }

    private func loadVideo(in webView: WKWebView) {
        // YouTube embed with autoplay, loop, and playsinline for a seamless experience
        // Using 100% width/height with absolute positioning to fill the container
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                * { margin: 0; padding: 0; }
                html, body { width: 100%; height: 100%; overflow: hidden; background: #000; }
                iframe {
                    position: absolute;
                    top: 0;
                    left: 0;
                    width: 100%;
                    height: 100%;
                    border: none;
                }
            </style>
        </head>
        <body>
            <iframe
                src="https://www.youtube.com/embed/\(videoId)?autoplay=1&playsinline=1&loop=1&playlist=\(videoId)&mute=0&controls=1&rel=0&modestbranding=1"
                allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
                allowfullscreen>
            </iframe>
        </body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: URL(string: "https://www.youtube.com"))
    }

    class Coordinator {
        var currentVideoId: String

        init(videoId: String) {
            self.currentVideoId = videoId
        }
    }
}

// MARK: - YouTube URL Helpers

/// Checks if a URL is a YouTube URL (youtube.com or youtu.be)
func isYouTubeUrl(_ url: String) -> Bool {
    return url.contains("youtube.com") || url.contains("youtu.be")
}

/// Extracts the video ID from various YouTube URL formats:
/// - https://www.youtube.com/watch?v=VIDEO_ID
/// - https://youtu.be/VIDEO_ID
/// - https://www.youtube.com/shorts/VIDEO_ID
/// - https://youtube.com/embed/VIDEO_ID
func extractYouTubeVideoId(from url: String) -> String? {
    // Pattern matches common YouTube URL formats
    // Video IDs are 11 characters: alphanumeric, underscore, or hyphen
    let patterns = [
        // Standard watch URLs: youtube.com/watch?v=VIDEO_ID
        #"(?:youtube\.com\/watch\?.*v=)([a-zA-Z0-9_-]{11})"#,
        // Short URLs: youtu.be/VIDEO_ID
        #"(?:youtu\.be\/)([a-zA-Z0-9_-]{11})"#,
        // Shorts URLs: youtube.com/shorts/VIDEO_ID
        #"(?:youtube\.com\/shorts\/)([a-zA-Z0-9_-]{11})"#,
        // Embed URLs: youtube.com/embed/VIDEO_ID
        #"(?:youtube\.com\/embed\/)([a-zA-Z0-9_-]{11})"#
    ]

    for pattern in patterns {
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
            let range = NSRange(url.startIndex..., in: url)
            if let match = regex.firstMatch(in: url, options: [], range: range) {
                if let idRange = Range(match.range(at: 1), in: url) {
                    return String(url[idRange])
                }
            }
        }
    }

    return nil
}
