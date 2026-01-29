import SwiftUI
import AVKit

struct VideoContentView: View {
    let item: ContentFeedItem

    @State private var player: AVPlayer?

    var body: some View {
        ZStack {
            if let mediaUrl = item.mediaUrl, let url = URL(string: mediaUrl) {
                VideoPlayer(player: player)
                    .onAppear {
                        player = AVPlayer(url: url)
                        player?.play()
                    }
                    .onDisappear {
                        player?.pause()
                        player = nil
                    }
            } else {
                // Placeholder
                VStack(spacing: 16) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.white.opacity(0.5))

                    if let title = item.title {
                        Text(title)
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                    }

                    if let duration = item.durationSeconds {
                        Text(formatDuration(duration))
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                }
            }

            // Title overlay at top
            if let title = item.title {
                VStack {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.black.opacity(0.5))
                    Spacer()
                }
            }
        }
    }

    private func formatDuration(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
