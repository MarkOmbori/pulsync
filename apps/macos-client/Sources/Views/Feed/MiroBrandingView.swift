import SwiftUI

/// Miro-style branding with "miro" logotype followed by "pulsync"
struct MiroBrandingView: View {
    var body: some View {
        HStack(spacing: 2) {
            // Miro logotype style
            Text("miro")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(MiroColors.miroYellow)

            // Separator dot
            Circle()
                .fill(MiroColors.textMuted.opacity(0.5))
                .frame(width: 4, height: 4)
                .padding(.horizontal, 4)

            // Pulsync in same style
            Text("pulsync")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
        )
    }
}

/// Compact version for smaller screens
struct MiroBrandingCompact: View {
    var body: some View {
        HStack(spacing: 3) {
            Text("m")
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(MiroColors.miroYellow)
            Text("p")
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
        )
    }
}
