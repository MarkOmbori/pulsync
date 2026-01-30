import SwiftUI

/// Miro logo icon - yellow rounded square with stylized M strokes
struct MiroLogoIcon: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            // Yellow rounded square background
            RoundedRectangle(cornerRadius: size * 0.22)
                .fill(MiroColors.miroYellow)
                .frame(width: size, height: size)

            // Three diagonal strokes forming stylized "M"
            Canvas { context, canvasSize in
                let strokeWidth = size * 0.12
                let color = Color(hex: "050038") // Dark navy from Miro logo

                // Calculate positions for three strokes
                let padding = size * 0.22
                let strokeSpacing = (canvasSize.width - padding * 2) / 3.5

                for i in 0..<3 {
                    let xOffset = padding + CGFloat(i) * strokeSpacing

                    var path = Path()
                    // Stroke goes from bottom-left to top-right
                    path.move(to: CGPoint(
                        x: xOffset,
                        y: canvasSize.height - padding
                    ))
                    path.addLine(to: CGPoint(
                        x: xOffset + strokeSpacing * 0.7,
                        y: padding
                    ))

                    context.stroke(
                        path,
                        with: .color(color),
                        style: StrokeStyle(
                            lineWidth: strokeWidth,
                            lineCap: .round
                        )
                    )
                }
            }
            .frame(width: size, height: size)
        }
    }
}

/// Pulsync branding with Miro logo icon + "Pulsync" text
struct PulsyncBrandingView: View {
    var body: some View {
        HStack(spacing: 8) {
            // Miro-style logo icon
            MiroLogoIcon(size: 28)

            // Pulsync text
            Text("Pulsync")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
    }
}

/// Compact version for smaller screens
struct PulsyncBrandingCompact: View {
    var body: some View {
        HStack(spacing: 6) {
            MiroLogoIcon(size: 24)

            Text("Pulsync")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
    }
}

// Keep old names for compatibility but mark as deprecated
@available(*, deprecated, renamed: "PulsyncBrandingView")
typealias MiroBrandingView = PulsyncBrandingView

@available(*, deprecated, renamed: "PulsyncBrandingCompact")
typealias MiroBrandingCompact = PulsyncBrandingCompact
