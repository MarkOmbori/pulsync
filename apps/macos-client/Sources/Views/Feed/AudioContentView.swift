import SwiftUI
import AVFoundation

struct AudioContentView: View {
    let item: ContentFeedItem

    @State private var player: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var progress: Double = 0
    @State private var timer: Timer?

    var body: some View {
        VStack(spacing: 32) {
            // Thumbnail or waveform visualization
            ZStack {
                if let thumbnailUrl = item.thumbnailUrl, let url = URL(string: thumbnailUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        audioWaveform
                    }
                    .frame(width: 200, height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    audioWaveform
                        .frame(width: 200, height: 200)
                }
            }

            // Title
            VStack(spacing: 8) {
                if let title = item.title {
                    Text(title)
                        .font(.title.bold())
                        .foregroundStyle(.white)
                }

                Text(item.author.displayName)
                    .font(.headline)
                    .foregroundStyle(.gray)
            }

            // Progress bar
            VStack(spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.white.opacity(0.3))
                            .frame(height: 4)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.electricViolet)
                            .frame(width: geometry.size.width * progress, height: 4)
                    }
                }
                .frame(height: 4)

                HStack {
                    Text(formatTime(progress * Double(item.durationSeconds ?? 0)))
                        .font(.caption)
                        .foregroundStyle(.gray)
                    Spacer()
                    Text(formatTime(Double(item.durationSeconds ?? 0)))
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
            }
            .frame(width: 300)

            // Play/Pause button
            Button(action: togglePlayback) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.electricViolet)
            }
            .buttonStyle(.plain)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PulsyncTheme.background)
        .onDisappear {
            player?.stop()
            timer?.invalidate()
        }
    }

    private var audioWaveform: some View {
        HStack(spacing: 3) {
            ForEach(0..<30, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.electricViolet.opacity(isPlaying ? 1 : 0.5))
                    .frame(width: 4, height: CGFloat.random(in: 20...100))
                    .animation(
                        isPlaying ?
                            .easeInOut(duration: 0.3).repeatForever(autoreverses: true).delay(Double(i) * 0.05) :
                            .default,
                        value: isPlaying
                    )
            }
        }
    }

    private func togglePlayback() {
        if isPlaying {
            player?.pause()
            timer?.invalidate()
        } else {
            if player == nil, let mediaUrl = item.mediaUrl, let url = URL(string: mediaUrl) {
                // In a real app, you'd download and play the audio
                // For demo, we simulate playback
            }
            // Simulate playback for demo
            startSimulatedPlayback()
        }
        isPlaying.toggle()
    }

    private func startSimulatedPlayback() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            let duration = Double(item.durationSeconds ?? 180)
            if progress < 1.0 {
                progress += 0.1 / duration
            } else {
                timer?.invalidate()
                isPlaying = false
                progress = 0
            }
        }
    }

    private func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
