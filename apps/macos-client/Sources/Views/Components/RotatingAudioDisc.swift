import SwiftUI

/// TikTok-style rotating audio disc with album art
struct RotatingAudioDisc: View {
    let thumbnailUrl: String?
    let isPlaying: Bool
    var size: CGFloat = 48

    @State private var rotation: Double = 0

    // Vinyl record appearance
    private let innerRingRatio: CGFloat = 0.4
    private let grooveCount = 3

    var body: some View {
        ZStack {
            // Outer disc with gradient border
            Circle()
                .fill(
                    AngularGradient(
                        colors: [.gray.opacity(0.3), .white.opacity(0.1), .gray.opacity(0.3)],
                        center: .center
                    )
                )
                .frame(width: size + 8, height: size + 8)

            // Vinyl grooves (decorative rings)
            ForEach(0..<grooveCount, id: \.self) { i in
                let ringSize = size * (1 - CGFloat(i) * 0.15)
                Circle()
                    .stroke(Color.black.opacity(0.3), lineWidth: 1)
                    .frame(width: ringSize, height: ringSize)
            }

            // Album art / thumbnail
            if let urlString = thumbnailUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    defaultDisc
                }
                .frame(width: size, height: size)
                .clipShape(Circle())
            } else {
                defaultDisc
                    .frame(width: size, height: size)
            }

            // Center hole (vinyl record style)
            Circle()
                .fill(Color.pulsyncDark)
                .frame(width: size * innerRingRatio, height: size * innerRingRatio)

            // Musical note in center
            Image(systemName: "music.note")
                .font(.system(size: size * 0.2, weight: .semibold))
                .foregroundStyle(.white)
        }
        .rotationEffect(.degrees(rotation))
        .onAppear {
            if isPlaying {
                startRotation()
            }
        }
        .onChange(of: isPlaying) { _, playing in
            if playing {
                startRotation()
            }
        }
    }

    private var defaultDisc: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [Color.electricViolet, Color.electricViolet.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }

    private func startRotation() {
        withAnimation(
            .linear(duration: PulsyncAnimation.discRotation)
            .repeatForever(autoreverses: false)
        ) {
            rotation = 360
        }
    }
}

// MARK: - Audio Indicator Bar (alternative compact view)

struct AudioIndicatorBar: View {
    let songName: String
    let artistName: String?

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "music.note")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)

            MarqueeText(text: displayText)
                .frame(maxWidth: 200, alignment: .leading)
        }
    }

    private var displayText: String {
        if let artist = artistName {
            return "\(songName) - \(artist)"
        }
        return songName
    }
}

// MARK: - Marquee Text (scrolling text for long content)

struct MarqueeText: View {
    let text: String
    var font: Font = .caption
    var speed: Double = 30 // points per second

    @State private var offset: CGFloat = 0
    @State private var textWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0

    private var needsScrolling: Bool {
        textWidth > containerWidth
    }

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width

            HStack(spacing: 50) {
                Text(text)
                    .font(font)
                    .foregroundStyle(.white)
                    .fixedSize()
                    .background(
                        GeometryReader { textGeometry in
                            Color.clear
                                .onAppear {
                                    textWidth = textGeometry.size.width
                                    containerWidth = width
                                }
                        }
                    )

                if needsScrolling {
                    Text(text)
                        .font(font)
                        .foregroundStyle(.white)
                        .fixedSize()
                }
            }
            .offset(x: needsScrolling ? offset : 0)
            .onAppear {
                if needsScrolling {
                    startScrolling()
                }
            }
        }
        .clipped()
    }

    private func startScrolling() {
        let totalWidth = textWidth + 50 // text + spacing
        let duration = totalWidth / speed

        withAnimation(
            .linear(duration: duration)
            .repeatForever(autoreverses: false)
        ) {
            offset = -totalWidth
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        RotatingAudioDisc(thumbnailUrl: nil, isPlaying: true, size: 48)
        RotatingAudioDisc(thumbnailUrl: nil, isPlaying: true, size: 64)
        AudioIndicatorBar(songName: "Original Sound", artistName: "username")
    }
    .padding()
    .background(Color.black)
}
