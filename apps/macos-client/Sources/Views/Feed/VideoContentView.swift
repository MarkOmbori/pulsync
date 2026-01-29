import SwiftUI
import AVKit
import Combine

// Container view that forwards all scroll events to the parent scroll view
class ScrollPassthroughView: NSView {
    override func scrollWheel(with event: NSEvent) {
        // Find the enclosing NSScrollView and forward the event
        var responder: NSResponder? = self.superview
        while responder != nil {
            if let scrollView = responder as? NSScrollView {
                scrollView.scrollWheel(with: event)
                return
            }
            responder = responder?.nextResponder
        }
        // If no scroll view found, pass to next responder
        super.scrollWheel(with: event)
    }
}

// Custom NSViewRepresentable for AVPlayer that doesn't capture scroll
struct NativeVideoPlayer: NSViewRepresentable {
    let player: AVPlayer

    func makeNSView(context: Context) -> NSView {
        // Container that passes scroll events through
        let container = ScrollPassthroughView()

        // Create player layer instead of AVPlayerView to avoid scroll capture
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill

        // Host the layer in an NSView
        let layerHost = NSView()
        layerHost.wantsLayer = true
        layerHost.layer = playerLayer

        layerHost.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(layerHost)

        NSLayoutConstraint.activate([
            layerHost.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            layerHost.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            layerHost.topAnchor.constraint(equalTo: container.topAnchor),
            layerHost.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        // Update player if needed
        if let layerHost = nsView.subviews.first,
           let playerLayer = layerHost.layer as? AVPlayerLayer {
            playerLayer.player = player
        }
    }
}

struct VideoContentView: View {
    let item: ContentFeedItem

    @StateObject private var viewModel = VideoPlayerViewModel()

    var body: some View {
        ZStack {
            PulsyncTheme.background

            if let mediaUrl = item.mediaUrl {
                switch viewModel.state {
                case .idle:
                    Color.black
                        .onAppear {
                            viewModel.load(urlString: mediaUrl)
                        }

                case .loading:
                    loadingView

                case .ready:
                    if let player = viewModel.player {
                        NativeVideoPlayer(player: player)
                            .onTapGesture {
                                // Toggle play/pause on tap
                                if player.timeControlStatus == .playing {
                                    player.pause()
                                } else {
                                    player.play()
                                }
                            }
                            .onAppear {
                                player.play()
                            }
                            .onDisappear {
                                player.pause()
                            }
                    }

                case .failed(let error):
                    errorView(message: error)
                }
            } else {
                noMediaView
            }

            // Gradient overlay at bottom
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

    private var loadingView: some View {
        ZStack {
            // Thumbnail background
            if let thumbnailUrl = item.thumbnailUrl, let url = URL(string: thumbnailUrl) {
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Color.black
                    }
                }
            } else {
                Color.black
            }

            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                Text("Loading video...")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }

    private var noMediaView: some View {
        VStack(spacing: 16) {
            Image(systemName: "video.slash")
                .font(.system(size: 60))
                .foregroundStyle(.gray)
            Text("No video URL")
                .font(.headline)
                .foregroundStyle(.white)
        }
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundStyle(.orange)

            Text("Video failed to load")
                .font(.headline)
                .foregroundStyle(.white)

            Text(message)
                .font(.caption)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Retry") {
                if let mediaUrl = item.mediaUrl {
                    viewModel.load(urlString: mediaUrl)
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

// ViewModel to manage video player state
@MainActor
class VideoPlayerViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case loading
        case ready
        case failed(String)
    }

    @Published var state: State = .idle
    @Published var player: AVPlayer?

    private var cancellables = Set<AnyCancellable>()
    private var statusObserver: NSKeyValueObservation?
    private var loopObserver: Any?

    func load(urlString: String) {
        guard let url = URL(string: urlString) else {
            state = .failed("Invalid URL")
            return
        }

        state = .loading

        // Clean up previous player
        cleanup()

        // Create new player
        let playerItem = AVPlayerItem(url: url)
        let newPlayer = AVPlayer(playerItem: playerItem)
        newPlayer.isMuted = false

        // Observe status using KVO
        statusObserver = playerItem.observe(\.status, options: [.new]) { [weak self] item, _ in
            DispatchQueue.main.async {
                switch item.status {
                case .readyToPlay:
                    self?.player = newPlayer
                    self?.state = .ready
                    newPlayer.play()
                case .failed:
                    let errorMsg = item.error?.localizedDescription ?? "Unknown playback error"
                    self?.state = .failed(errorMsg)
                case .unknown:
                    break
                @unknown default:
                    break
                }
            }
        }

        // Loop when video ends
        loopObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak newPlayer] _ in
            newPlayer?.seek(to: .zero)
            newPlayer?.play()
        }

        // Timeout after 15 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) { [weak self] in
            if self?.state == .loading {
                self?.state = .failed("Timeout - video took too long to load")
            }
        }
    }

    private func cleanup() {
        statusObserver?.invalidate()
        statusObserver = nil

        if let observer = loopObserver {
            NotificationCenter.default.removeObserver(observer)
            loopObserver = nil
        }

        player?.pause()
        player = nil
    }

}
