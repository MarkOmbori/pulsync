import SwiftUI

struct AIAgentsCard: View {
    let stats: AIAgentsStats

    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Text("AI Agents")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(MiroColors.textMuted)
                Spacer()
                Image(systemName: "sparkles")
                    .font(.system(size: 12))
                    .foregroundStyle(MiroColors.miroTeal)
            }

            Spacer()

            // Agent Stats
            HStack(spacing: 8) {
                AgentStatBubble(
                    value: "\(stats.definedAgents)",
                    label: "Defined",
                    color: MiroColors.cardPurple
                )

                AgentStatBubble(
                    value: "\(stats.runningAgents)",
                    label: "Running",
                    color: MiroColors.cardGreen
                )
            }

            Spacer()

            // Token Consumption
            VStack(spacing: 4) {
                HStack {
                    Text("Tokens")
                        .font(.system(size: 10))
                        .foregroundStyle(MiroColors.textMuted)
                    Spacer()
                    Text("\(stats.tokenConsumption.formattedUsed) / \(stats.tokenConsumption.formattedLimit)")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white)
                }

                // Progress Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.1))

                        RoundedRectangle(cornerRadius: 3)
                            .fill(tokenProgressColor)
                            .frame(width: geo.size.width * CGFloat(min(stats.tokenConsumption.percentUsed, 100) / 100))
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 160)
        .background(MiroColors.cardDark)
        .clipShape(RoundedRectangle(cornerRadius: MiroRadius.card))
    }

    private var tokenProgressColor: Color {
        let percent = stats.tokenConsumption.percentUsed
        if percent >= 90 {
            return MiroColors.statusRed
        } else if percent >= 70 {
            return MiroColors.statusYellow
        }
        return MiroColors.miroTeal
    }
}

struct AgentStatBubble: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(MiroColors.textDark)

            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(MiroColors.textDark.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color)
        .clipShape(RoundedRectangle(cornerRadius: MiroRadius.medium))
    }
}
