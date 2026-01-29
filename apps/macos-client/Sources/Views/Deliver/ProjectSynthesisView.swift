import SwiftUI

struct ProjectSynthesisView: View {
    let project: ProjectWithRole
    @State private var isExpanded = false

    private var accomplishmentCount: Int {
        project.weeklyAccomplishments?.count ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main row
            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() } }) {
                HStack(spacing: 12) {
                    // Project icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(roleColor.opacity(0.2))
                            .frame(width: 44, height: 44)

                        Image(systemName: "folder.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(roleColor)
                    }

                    // Project info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(project.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)

                        HStack(spacing: 8) {
                            roleBadge
                            statusBadge
                        }
                    }

                    Spacer()

                    // Accomplishment count
                    if accomplishmentCount > 0 {
                        HStack(spacing: 4) {
                            Text("\(accomplishmentCount)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.green)
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.green)
                        }
                    }

                    // Expand indicator
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.gray)
                }
                .padding(12)
            }
            .buttonStyle(.plain)

            // Expanded content
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                        .background(Color.white.opacity(0.1))

                    // Description
                    if let description = project.description {
                        Text(description)
                            .font(.system(size: 13))
                            .foregroundStyle(.gray)
                    }

                    // Date range
                    if let startDate = project.startDate {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.system(size: 12))
                                .foregroundStyle(.gray)
                            Text("Started \(startDate.formatted(date: .abbreviated, time: .omitted))")
                                .font(.system(size: 13))
                                .foregroundStyle(.gray)
                        }
                    }

                    // This week's accomplishments
                    if let accomplishments = project.weeklyAccomplishments, !accomplishments.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.green)
                                Text("This Week's Accomplishments")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(.gray)
                            }

                            ForEach(accomplishments) { accomplishment in
                                accomplishmentRow(accomplishment)
                            }
                        }
                    } else {
                        HStack(spacing: 6) {
                            Image(systemName: "minus.circle")
                                .font(.system(size: 12))
                                .foregroundStyle(.gray)
                            Text("No accomplishments logged this week")
                                .font(.system(size: 13))
                                .foregroundStyle(.gray)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
        }
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func accomplishmentRow(_ accomplishment: Accomplishment) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(accomplishment.title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)

            if let description = accomplishment.description {
                Text(description)
                    .font(.system(size: 12))
                    .foregroundStyle(.gray)
                    .lineLimit(2)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var roleBadge: some View {
        Text(roleLabel)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(roleColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(roleColor.opacity(0.15))
            .clipShape(Capsule())
    }

    private var statusBadge: some View {
        Text(statusLabel)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(statusColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(statusColor.opacity(0.15))
            .clipShape(Capsule())
    }

    private var roleLabel: String {
        switch project.myRole {
        case .responsible: return "Responsible"
        case .accountable: return "Accountable"
        case .consulted: return "Consulted"
        case .informed: return "Informed"
        case .follower: return "Following"
        }
    }

    private var roleColor: Color {
        switch project.myRole {
        case .responsible: return .blue
        case .accountable: return .purple
        case .consulted: return .orange
        case .informed: return .cyan
        case .follower: return .gray
        }
    }

    private var statusLabel: String {
        switch project.status {
        case .planning: return "Planning"
        case .active: return "Active"
        case .onHold: return "On Hold"
        case .completed: return "Completed"
        case .archived: return "Archived"
        }
    }

    private var statusColor: Color {
        switch project.status {
        case .planning: return .yellow
        case .active: return .green
        case .onHold: return .orange
        case .completed: return .blue
        case .archived: return .gray
        }
    }
}
