import SwiftUI
import AppKit

struct EnhancedProjectCard: View {
    let project: EnhancedProject
    @State private var isExpanded = false
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main Card Content
            Button(action: { withAnimation(.spring(response: 0.3)) { isExpanded.toggle() } }) {
                VStack(alignment: .leading, spacing: 10) {
                    // Top Row: Name, Status, Links
                    ProjectHeaderRow(project: project)

                    // Phase Indicator
                    PhaseIndicatorView(
                        currentPhase: project.phase,
                        releaseSubState: project.releaseSubState
                    )

                    // Progress Bar
                    ProjectProgressBar(
                        progress: project.progressPercent,
                        healthStatus: project.healthStatus
                    )

                    // Bottom Row: Meta info
                    ProjectMetaRow(project: project, isExpanded: isExpanded)
                }
                .padding(12)
            }
            .buttonStyle(.plain)

            // Expanded Details
            if isExpanded {
                ProjectExpandedDetails(project: project)
            }
        }
        .background(isHovered ? MiroColors.cardDarkHover : MiroColors.cardDark)
        .clipShape(RoundedRectangle(cornerRadius: MiroRadius.card))
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Project Header Row

struct ProjectHeaderRow: View {
    let project: EnhancedProject

    private var statusColor: Color {
        switch project.healthStatus {
        case .green: return MiroColors.statusGreen
        case .yellow: return MiroColors.statusYellow
        case .red: return MiroColors.statusRed
        case .onHold: return MiroColors.statusGray
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            // Status Indicator
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)

            // Project Name
            Text(project.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(1)

            Spacer()

            // External Links
            HStack(spacing: 6) {
                if project.miroUrl != nil {
                    LinkButton(icon: "rectangle.grid.2x2", label: "Miro", url: project.miroUrl)
                }
                if project.jiraUrl != nil {
                    LinkButton(icon: "list.bullet.clipboard", label: "Jira", url: project.jiraUrl)
                }
            }

            // Role Badge
            RoleBadge(role: project.myRole)
        }
    }
}

struct LinkButton: View {
    let icon: String
    let label: String
    let url: URL?

    var body: some View {
        Button(action: {
            if let url = url {
                NSWorkspace.shared.open(url)
            }
        }) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 9))
                Text(label)
                    .font(.system(size: 9, weight: .medium))
            }
            .foregroundStyle(MiroColors.miroBlue)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(MiroColors.miroBlue.opacity(0.15))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(url == nil)
    }
}

struct RoleBadge: View {
    let role: ProjectRole

    private var roleColor: Color {
        switch role {
        case .responsible: return MiroColors.miroBlue
        case .accountable: return Color.purple
        case .consulted: return Color.orange
        case .informed: return MiroColors.miroTeal
        case .follower: return MiroColors.statusGray
        }
    }

    private var roleLabel: String {
        switch role {
        case .responsible: return "R"
        case .accountable: return "A"
        case .consulted: return "C"
        case .informed: return "I"
        case .follower: return "F"
        }
    }

    var body: some View {
        Text(roleLabel)
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(roleColor)
            .frame(width: 18, height: 18)
            .background(roleColor.opacity(0.2))
            .clipShape(Circle())
    }
}

// MARK: - Project Meta Row

struct ProjectMetaRow: View {
    let project: EnhancedProject
    let isExpanded: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Description preview
            if let desc = project.description, !isExpanded {
                Text(desc)
                    .font(.system(size: 11))
                    .foregroundStyle(MiroColors.textMuted)
                    .lineLimit(1)
            }

            Spacer()

            // Team size
            HStack(spacing: 3) {
                Image(systemName: "person.2")
                    .font(.system(size: 9))
                Text("\(project.teamSize)")
                    .font(.system(size: 10))
            }
            .foregroundStyle(MiroColors.textMuted)

            // Expand indicator
            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(MiroColors.textMuted)
        }
    }
}

// MARK: - Project Expanded Details

struct ProjectExpandedDetails: View {
    let project: EnhancedProject

    private var statusColor: Color {
        switch project.healthStatus {
        case .green: return MiroColors.statusGreen
        case .yellow: return MiroColors.statusYellow
        case .red: return MiroColors.statusRed
        case .onHold: return MiroColors.statusGray
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider()
                .background(Color.white.opacity(0.1))

            // Description
            if let description = project.description {
                Text(description)
                    .font(.system(size: 12))
                    .foregroundStyle(MiroColors.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Dates
            HStack(spacing: 16) {
                if let startDate = project.startDate {
                    DateLabel(icon: "calendar", label: "Started", date: startDate)
                }
                if let targetDate = project.targetDate {
                    DateLabel(icon: "flag.fill", label: "Target", date: targetDate)
                }
            }

            // Status Badge
            HStack(spacing: 4) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 6, height: 6)
                Text(project.healthStatus.displayName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(statusColor)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.15))
            .clipShape(Capsule())

            // Accomplishments this week
            if let accomplishments = project.weeklyAccomplishments, !accomplishments.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(MiroColors.statusGreen)
                        Text("This Week (\(accomplishments.count))")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(MiroColors.textMuted)
                    }

                    ForEach(accomplishments) { accomplishment in
                        Text("• \(accomplishment.title)")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
            }
        }
        .padding(12)
        .padding(.top, 0)
    }
}

struct DateLabel: View {
    let icon: String
    let label: String
    let date: Date

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9))
                .foregroundStyle(MiroColors.textMuted)
            Text("\(label): \(date.formatted(date: .abbreviated, time: .omitted))")
                .font(.system(size: 10))
                .foregroundStyle(MiroColors.textMuted)
        }
    }
}
