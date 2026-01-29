import SwiftUI
import AVKit

// Custom NSViewRepresentable for AVPlayer to avoid VideoPlayer crash
struct NativeVideoPlayer: NSViewRepresentable {
    let player: AVPlayer

    func makeNSView(context: Context) -> NSView {
        let view = AVPlayerView()
        view.player = player
        view.controlsStyle = .inline
        view.showsFullScreenToggleButton = false
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if let playerView = nsView as? AVPlayerView {
            playerView.player = player
        }
    }
}

struct VideoContentView: View {
    let item: ContentFeedItem

    @State private var player: AVPlayer?
    @State private var isLoading = true
    @State private var hasError = false

    var body: some View {
        ZStack {
            PulsyncTheme.background

            if let mediaUrl = item.mediaUrl, let url = URL(string: mediaUrl) {
                if let player = player {
                    NativeVideoPlayer(player: player)
                        .onAppear {
                            player.play()
                        }
                        .onDisappear {
                            player.pause()
                        }
                } else if isLoading {
                    // Loading state with thumbnail
                    ZStack {
                        if let thumbnailUrl = item.thumbnailUrl, let url = URL(string: thumbnailUrl) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Color.black
                            }
                        }

                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                    }
                    .task {
                        await loadVideo(from: url)
                    }
                } else if hasError {
                    errorView
                }
            } else {
                placeholderView
            }

            // Gradient overlay at bottom for text readability
            VStack {
                Spacer()
                LinearGradient(
                    colors: [.clear, .black.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 200)
            }
        }
    }

    private var placeholderView: some View {
        VStack(spacing: 16) {
            if let thumbnailUrl = item.thumbnailUrl, let url = URL(string: thumbnailUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.black
                }
            }

            VStack(spacing: 12) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.white.opacity(0.7))

                if let title = item.title {
                    Text(title)
                        .font(.pulsyncTitle2)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                }

                if let duration = item.durationSeconds {
                    Text(formatDuration(duration))
                        .font(.pulsyncCaption)
                        .foregroundStyle(.gray)
                }
            }
        }
    }

    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundStyle(.orange)

            Text("Video failed to load")
                .font(.pulsyncBody)
                .foregroundStyle(.white)

            Button("Retry") {
                if let mediaUrl = item.mediaUrl, let url = URL(string: mediaUrl) {
                    hasError = false
                    isLoading = true
                    Task {
                        await loadVideo(from: url)
                    }
                }
            }
            .buttonStyle(.bordered)
        }
    }

    private func loadVideo(from url: URL) async {
        let asset = AVAsset(url: url)

        do {
            let isPlayable = try await asset.load(.isPlayable)
            if isPlayable {
                await MainActor.run {
                    let playerItem = AVPlayerItem(asset: asset)
                    self.player = AVPlayer(playerItem: playerItem)
                    self.isLoading = false

                    // Loop video
                    NotificationCenter.default.addObserver(
                        forName: .AVPlayerItemDidPlayToEndTime,
                        object: playerItem,
                        queue: .main
                    ) { _ in
                        self.player?.seek(to: .zero)
                        self.player?.play()
                    }
                }
            } else {
                await MainActor.run {
                    self.hasError = true
                    self.isLoading = false
                }
            }
        } catch {
            await MainActor.run {
                self.hasError = true
                self.isLoading = false
            }
        }
    }

    private func formatDuration(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
