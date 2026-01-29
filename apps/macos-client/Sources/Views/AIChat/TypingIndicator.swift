import SwiftUI

struct TypingIndicator: View {
    @State private var animationOffset: CGFloat = 0

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // AI avatar
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.electricViolet, Color.electricViolet.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))

                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text("Assistant")
                    .font(.caption2)
                    .foregroundStyle(.gray)

                HStack(spacing: 4) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color.white.opacity(0.6))
                            .frame(width: 8, height: 8)
                            .offset(y: animationOffset(for: index))
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(PulsyncTheme.surface)
                .cornerRadius(16, corners: [.topLeft, .topRight, .bottomRight])
            }

            Spacer(minLength: 40)
        }
        .onAppear {
            startAnimation()
        }
    }

    private func animationOffset(for index: Int) -> CGFloat {
        let delay = Double(index) * 0.15
        let progress = (animationOffset + CGFloat(delay)).truncatingRemainder(dividingBy: 1.0)
        return -sin(progress * .pi * 2) * 4
    }

    private func startAnimation() {
        withAnimation(.linear(duration: 0.6).repeatForever(autoreverses: false)) {
            animationOffset = 1.0
        }
    }
}

#Preview {
    TypingIndicator()
        .padding()
        .background(PulsyncTheme.background)
}
