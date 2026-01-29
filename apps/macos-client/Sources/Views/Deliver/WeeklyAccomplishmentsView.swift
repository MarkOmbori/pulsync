import SwiftUI

struct WeeklyAccomplishmentsView: View {
    let weekOf: Date
    let projects: [ProjectWithRole]

    private var totalAccomplishments: Int {
        projects.compactMap { $0.weeklyAccomplishments?.count }.reduce(0, +)
    }

    private var activeProjects: Int {
        projects.filter { $0.status == .active }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Week header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(weekRangeLabel)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.gray)
                    Text("\(totalAccomplishments) accomplishments")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                }
                Spacer()

                // Accomplishment indicator
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Text("\(totalAccomplishments)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.green)
                }
            }

            Divider()
                .background(Color.white.opacity(0.1))

            // Stats row
            HStack(spacing: 24) {
                statItem(value: "\(activeProjects)", label: "Active Projects", icon: "folder.fill", color: .blue)
                statItem(value: "\(totalAccomplishments)", label: "Completed", icon: "checkmark.circle.fill", color: .green)
                statItem(value: roleBreakdown, label: "My Roles", icon: "person.fill", color: .purple)
            }

            // Recent accomplishments preview
            if totalAccomplishments > 0 {
                Divider()
                    .background(Color.white.opacity(0.1))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent Accomplishments")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.gray)

                    ForEach(recentAccomplishments.prefix(3)) { accomplishment in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)
                            Text(accomplishment.title)
                                .font(.system(size: 13))
                                .foregroundStyle(.white.opacity(0.8))
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.08), Color.white.opacity(0.04)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var weekRangeLabel: String {
        let calendar = Calendar.current
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: weekOf)),
              let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else {
            return ""
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"

        return "\(formatter.string(from: weekStart)) - \(formatter.string(from: weekEnd))"
    }

    private var roleBreakdown: String {
        let roles = Set(projects.map { $0.myRole })
        return "\(roles.count)"
    }

    private var recentAccomplishments: [Accomplishment] {
        projects
            .compactMap { $0.weeklyAccomplishments }
            .flatMap { $0 }
            .sorted { $0.createdAt > $1.createdAt }
    }

    private func statItem(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(color)
                Text(value)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
            }
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.gray)
        }
    }
}
