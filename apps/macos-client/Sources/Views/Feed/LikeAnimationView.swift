import SwiftUI

/// Heart burst animation shown on double-tap like (TikTok/Instagram style)
struct LikeAnimationView: View {
    @Binding var isVisible: Bool
    var onComplete: (() -> Void)? = nil

    @State private var scale: CGFloat = 0
    @State private var opacity: Double = 1
    @State private var particles: [Particle] = []

    private let particleCount = 12

    var body: some View {
        ZStack {
            // Main heart
            Image(systemName: "heart.fill")
                .font(.system(size: 100, weight: .bold))
                .foregroundStyle(Color.tikTokRed)
                .scaleEffect(scale)
                .opacity(opacity)
                .textShadow()

            // Particle effects
            ForEach(particles) { particle in
                Image(systemName: "heart.fill")
                    .font(.system(size: particle.size))
                    .foregroundStyle(particle.color)
                    .offset(particle.offset)
                    .scaleEffect(particle.scale)
                    .opacity(particle.opacity)
            }
        }
        .onChange(of: isVisible) { _, newValue in
            if newValue {
                startAnimation()
            }
        }
        .onAppear {
            if isVisible {
                startAnimation()
            }
        }
    }

    private func startAnimation() {
        // Reset state
        scale = 0
        opacity = 1
        particles = createParticles()

        // Animate main heart: 0 → 1.2 → 1.0
        withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
            scale = 1.2
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.15, dampingFraction: 0.7)) {
                scale = 1.0
            }
        }

        // Animate particles outward
        withAnimation(.easeOut(duration: 0.4)) {
            for i in particles.indices {
                particles[i].offset = particles[i].targetOffset
                particles[i].scale = 0.3
                particles[i].opacity = 0
            }
        }

        // Fade out main heart
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.easeOut(duration: 0.2)) {
                opacity = 0
            }
        }

        // Complete and hide
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isVisible = false
            onComplete?()
        }
    }

    private func createParticles() -> [Particle] {
        (0..<particleCount).map { i in
            let angle = Double(i) * (360.0 / Double(particleCount))
            let radians = angle * .pi / 180
            let distance: CGFloat = CGFloat.random(in: 60...120)

            return Particle(
                id: i,
                color: i % 2 == 0 ? .tikTokRed : .tikTokPink,
                size: CGFloat.random(in: 12...24),
                offset: .zero,
                targetOffset: CGSize(
                    width: cos(radians) * distance,
                    height: sin(radians) * distance
                ),
                scale: 1.0,
                opacity: 1.0
            )
        }
    }
}

// MARK: - Particle Model

struct Particle: Identifiable {
    let id: Int
    let color: Color
    let size: CGFloat
    var offset: CGSize
    let targetOffset: CGSize
    var scale: CGFloat
    var opacity: Double
}

// MARK: - Double Tap Like Extension

extension View {
    /// Add double-tap to like with heart animation
    func doubleTapToLike(isLiked: Binding<Bool>, showAnimation: Binding<Bool>, onLike: @escaping () -> Void) -> some View {
        self
            .overlay {
                if showAnimation.wrappedValue {
                    LikeAnimationView(isVisible: showAnimation)
                }
            }
            .onTapGesture(count: 2) {
                // Only trigger animation if not already liked
                if !isLiked.wrappedValue {
                    isLiked.wrappedValue = true
                    onLike()
                }
                // Always show animation on double tap
                showAnimation.wrappedValue = true
            }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black
        LikeAnimationView(isVisible: .constant(true))
    }
}
