import SwiftUI

struct PhaseIndicatorView: View {
    let currentPhase: ProjectPhase
    let releaseSubState: ReleaseSubState?

    private let phases = ProjectPhase.allCases

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Phase Pills
            HStack(spacing: 3) {
                ForEach(phases, id: \.self) { phase in
                    PhasePill(
                        phase: phase,
                        isCurrent: phase == currentPhase,
                        isPast: phase.order < currentPhase.order
                    )
                }
            }

            // Release Sub-state (if in Release Loop)
            if currentPhase == .releaseLoop, let subState = releaseSubState {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.turn.down.right")
                        .font(.system(size: 8))
                        .foregroundStyle(MiroColors.textMuted)

                    Text(subState.displayName)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(MiroColors.phaseRelease)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(MiroColors.phaseRelease.opacity(0.2))
                        .clipShape(Capsule())
                }
                .padding(.leading, 4)
            }
        }
    }
}

struct PhasePill: View {
    let phase: ProjectPhase
    let isCurrent: Bool
    let isPast: Bool

    private var phaseColor: Color {
        switch phase {
        case .braindump: return MiroColors.phaseBraindump
        case .kickoff: return MiroColors.phaseKickoff
        case .earlyConceptReview: return MiroColors.phaseEarlyConcept
        case .solutionsReview: return MiroColors.phaseSolutions
        case .releaseLoop: return MiroColors.phaseRelease
        }
    }

    var body: some View {
        HStack(spacing: 2) {
            if isPast {
                Image(systemName: "checkmark")
                    .font(.system(size: 6, weight: .bold))
                    .foregroundStyle(phaseColor)
            }
            Text(phase.displayName)
                .font(.system(size: 8, weight: isCurrent ? .semibold : .medium))
                .foregroundStyle(isCurrent ? .white : (isPast ? phaseColor : MiroColors.textMuted))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            isCurrent
                ? phaseColor
                : (isPast ? phaseColor.opacity(0.25) : Color.white.opacity(0.05))
        )
        .overlay(
            Capsule()
                .stroke(isPast ? phaseColor.opacity(0.5) : Color.clear, lineWidth: 1)
        )
        .clipShape(Capsule())
    }
}
