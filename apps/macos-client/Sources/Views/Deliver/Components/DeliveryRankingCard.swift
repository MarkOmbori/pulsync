import SwiftUI

struct DeliveryRankingCard: View {
    let ranking: DeliveryRanking

    private var trophyColor: Color {
        switch ranking.rank {
        case 1: return MiroColors.goldTrophy
        case 2: return MiroColors.silverTrophy
        case 3: return MiroColors.bronzeTrophy
        default: return MiroColors.miroYellow
        }
    }

    private var trendIcon: String {
        switch ranking.trend {
        case .up: return "arrow.up.circle.fill"
        case .down: return "arrow.down.circle.fill"
        case .stable: return "minus.circle.fill"
        }
    }

    private var trendColor: Color {
        switch ranking.trend {
        case .up: return MiroColors.statusGreen
        case .down: return MiroColors.statusRed
        case .stable: return MiroColors.statusGray
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Text("Set Goals")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(MiroColors.textMuted)
                Spacer()
                Image(systemName: trendIcon)
                    .font(.system(size: 12))
                    .foregroundStyle(trendColor)
            }

            Spacer()

            // Trophy Icon
            ZStack {
                Circle()
                    .fill(trophyColor.opacity(0.2))
                    .frame(width: 56, height: 56)

                Image(systemName: "trophy.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(trophyColor)
            }

            // Ranking Display
            VStack(spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(ranking.rank)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("of \(formatFullNumber(ranking.totalUsers))")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(MiroColors.textMuted)
                }

                Text("Mironeers")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(MiroColors.textMuted)
            }

            Spacer()
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 160)
        .background(MiroColors.cardDark)
        .clipShape(RoundedRectangle(cornerRadius: MiroRadius.card))
    }

    private func formatFullNumber(_ num: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: num)) ?? "\(num)"
    }
}
