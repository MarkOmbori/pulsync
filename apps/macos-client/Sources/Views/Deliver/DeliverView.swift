import SwiftUI

struct DeliverView: View {
    @State private var selectedWeek = Date()
    @State private var projects: [ProjectWithRole] = []
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Deliver")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    Text("Weekly Accomplishments")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                }
                Spacer()

                // Week selector
                weekSelector
            }
            .padding()

            if isLoading {
                Spacer()
                ProgressView()
                    .tint(.white)
                Spacer()
            } else if projects.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Summary card
                        WeeklyAccomplishmentsView(weekOf: selectedWeek, projects: projects)

                        // Projects section
                        sectionHeader(title: "My Projects", icon: "folder")
                        ForEach(projects) { project in
                            ProjectSynthesisView(project: project)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .task {
            await loadProjects()
        }
    }

    private var weekSelector: some View {
        HStack(spacing: 8) {
            Button(action: { moveWeek(by: -7) }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.gray)
            }
            .buttonStyle(.plain)

            Text(weekLabel)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)
                .frame(minWidth: 100)

            Button(action: { moveWeek(by: 7) }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(canMoveForward ? .gray : .gray.opacity(0.3))
            }
            .buttonStyle(.plain)
            .disabled(!canMoveForward)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.1))
        .clipShape(Capsule())
    }

    private var weekLabel: String {
        let calendar = Calendar.current
        let weekOfYear = calendar.component(.weekOfYear, from: selectedWeek)
        let year = calendar.component(.year, from: selectedWeek)

        if calendar.isDate(selectedWeek, equalTo: Date(), toGranularity: .weekOfYear) {
            return "This Week"
        } else {
            return "Week \(weekOfYear), \(year)"
        }
    }

    private var canMoveForward: Bool {
        let calendar = Calendar.current
        return !calendar.isDate(selectedWeek, equalTo: Date(), toGranularity: .weekOfYear)
    }

    private func moveWeek(by days: Int) {
        if let newDate = Calendar.current.date(byAdding: .day, value: days, to: selectedWeek) {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedWeek = newDate
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "chart.bar")
                .font(.system(size: 64))
                .foregroundStyle(.gray.opacity(0.5))

            Text("No projects yet")
                .font(.title3.bold())
                .foregroundStyle(.white)

            Text("Projects you're involved in will appear here\nwith weekly accomplishment summaries.")
                .font(.subheadline)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding()
    }

    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.gray)
            Text(title)
                .font(.headline)
                .foregroundStyle(.gray)
            Spacer()
        }
        .padding(.top, 8)
        .padding(.bottom, 8)
    }

    private func loadProjects() async {
        isLoading = true
        // TODO: Load projects from API
        // For now, show sample data
        projects = sampleProjects
        isLoading = false
    }

    private var sampleProjects: [ProjectWithRole] {
        [
            ProjectWithRole(
                id: UUID(),
                name: "Pulsync Mobile App",
                description: "Cross-platform mobile app for iOS and Android",
                status: .active,
                myRole: .responsible,
                startDate: Calendar.current.date(byAdding: .month, value: -2, to: Date()),
                endDate: nil,
                weeklyAccomplishments: [
                    Accomplishment(
                        id: UUID(),
                        projectId: UUID(),
                        userId: UUID(),
                        title: "Implemented feed infinite scroll",
                        description: "Added cursor-based pagination to the main feed",
                        weekOf: Date(),
                        createdAt: Date()
                    ),
                    Accomplishment(
                        id: UUID(),
                        projectId: UUID(),
                        userId: UUID(),
                        title: "Fixed video playback issues",
                        description: "Resolved memory leaks in video player component",
                        weekOf: Date(),
                        createdAt: Date()
                    )
                ]
            ),
            ProjectWithRole(
                id: UUID(),
                name: "API Infrastructure",
                description: "Backend services and database optimization",
                status: .active,
                myRole: .consulted,
                startDate: Calendar.current.date(byAdding: .month, value: -1, to: Date()),
                endDate: nil,
                weeklyAccomplishments: [
                    Accomplishment(
                        id: UUID(),
                        projectId: UUID(),
                        userId: UUID(),
                        title: "Reviewed database schema changes",
                        description: "Provided feedback on new user preferences table",
                        weekOf: Date(),
                        createdAt: Date()
                    )
                ]
            ),
            ProjectWithRole(
                id: UUID(),
                name: "Design System",
                description: "Component library and design tokens",
                status: .active,
                myRole: .follower,
                startDate: Calendar.current.date(byAdding: .month, value: -3, to: Date()),
                endDate: nil,
                weeklyAccomplishments: nil
            )
        ]
    }
}
