import SwiftUI

struct MiroBehaviorsCard: View {
    let behaviors: MiroBehaviors

    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Text("Miro Behaviors")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(MiroColors.textMuted)
                Spacer()
                Text(String(format: "%.1f", behaviors.averageScore))
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(MiroColors.miroYellow)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(MiroColors.miroYellow.opacity(0.2))
                    .clipShape(Capsule())
            }

            Spacer()

            // Behavior Ratings
            VStack(spacing: 6) {
                BehaviorRatingRow(
                    icon: "person.3.fill",
                    label: "Play as a team",
                    rating: behaviors.playAsTeam
                )
                BehaviorRatingRow(
                    icon: "lightbulb.fill",
                    label: "Learn First",
                    rating: behaviors.learnFirst
                )
                BehaviorRatingRow(
                    icon: "target",
                    label: "Deliver impact",
                    rating: behaviors.deliverImpact
                )
                BehaviorRatingRow(
                    icon: "bolt.fill",
                    label: "Launch fast",
                    rating: behaviors.launchFastIterate
                )
            }

            Spacer()
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 160)
        .background(MiroColors.cardDark)
        .clipShape(RoundedRectangle(cornerRadius: MiroRadius.card))
    }
}

struct BehaviorRatingRow: View {
    let icon: String
    let label: String
    let rating: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(MiroColors.miroYellow)
                .frame(width: 14)

            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(MiroColors.textMuted)
                .lineLimit(1)

            Spacer()

            // Star Rating
            HStack(spacing: 1) {
                ForEach(1...5, id: \.self) { index in
                    Image(systemName: index <= rating ? "star.fill" : "star")
                        .font(.system(size: 8))
                        .foregroundStyle(
                            index <= rating
                                ? MiroColors.ratingFilled
                                : MiroColors.ratingEmpty
                        )
                }
            }
        }
    }
}
