import SwiftUI

struct ProjectProgressBar: View {
    let progress: Int
    let healthStatus: ProjectHealthStatus

    private var progressColor: Color {
        switch healthStatus {
        case .green: return MiroColors.statusGreen
        case .yellow: return MiroColors.statusYellow
        case .red: return MiroColors.statusRed
        case .onHold: return MiroColors.statusGray
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            // Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background Track
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.1))

                    // Progress Fill
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [progressColor, progressColor.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * CGFloat(progress) / 100)
                }
            }
            .frame(height: 6)

            // Percentage Label
            Text("\(progress)%")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(progressColor)
                .frame(width: 36, alignment: .trailing)
        }
    }
}
