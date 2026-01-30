import SwiftUI

struct DeliverView: View {
    @State private var selectedWeek = Date()
    @State private var dashboard: DeliverDashboard?
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 0) {
            // Header with week selector
            headerView

            if isLoading {
                Spacer()
                ProgressView()
                    .tint(MiroColors.miroYellow)
                Spacer()
            } else if let dashboard = dashboard {
                ScrollView {
                    VStack(spacing: 16) {
                        // Top Stats Row (3 columns)
                        statsRow(dashboard: dashboard)

                        // Projects Section
                        projectsSection(projects: dashboard.projects)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            } else {
                emptyState
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MiroColors.surfaceDark)
        .task {
            await loadDashboard()
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Deliver")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                Text("Weekly Accomplishments")
                    .font(.system(size: 13))
                    .foregroundStyle(MiroColors.textMuted)
            }
            Spacer()
            weekSelector
        }
        .padding(16)
    }

    private var weekSelector: some View {
        HStack(spacing: 8) {
            Button(action: { moveWeek(by: -7) }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(MiroColors.textMuted)
            }
            .buttonStyle(.plain)

            Text(weekLabel)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white)
                .frame(minWidth: 80)

            Button(action: { moveWeek(by: 7) }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(canMoveForward ? MiroColors.textMuted : MiroColors.textMuted.opacity(0.3))
            }
            .buttonStyle(.plain)
            .disabled(!canMoveForward)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(MiroColors.cardDark)
        .clipShape(Capsule())
    }

    private var weekLabel: String {
        let calendar = Calendar.current
        if calendar.isDate(selectedWeek, equalTo: Date(), toGranularity: .weekOfYear) {
            return "This Week"
        } else {
            let weekOfYear = calendar.component(.weekOfYear, from: selectedWeek)
            return "Week \(weekOfYear)"
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

    // MARK: - Stats Row

    private func statsRow(dashboard: DeliverDashboard) -> some View {
        HStack(spacing: 12) {
            DeliveryRankingCard(ranking: dashboard.ranking)
            MiroBehaviorsCard(behaviors: dashboard.behaviors)
            AIAgentsCard(stats: dashboard.aiAgents)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Projects Section

    private func projectsSection(projects: [EnhancedProject]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            HStack(spacing: 8) {
                Image(systemName: "folder.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(MiroColors.miroYellow)
                Text("My Projects")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)

                Spacer()

                Text("\(projects.count) projects")
                    .font(.system(size: 11))
                    .foregroundStyle(MiroColors.textMuted)
            }
            .padding(.top, 8)

            // Project Cards
            LazyVStack(spacing: 10) {
                ForEach(projects) { project in
                    EnhancedProjectCard(project: project)
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(MiroColors.miroYellow.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(MiroColors.miroYellow)
            }

            Text("No projects yet")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)

            Text("Projects you're involved in will appear here\nwith weekly accomplishment summaries.")
                .font(.system(size: 13))
                .foregroundStyle(MiroColors.textMuted)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding()
    }

    // MARK: - Data Loading

    private func loadDashboard() async {
        isLoading = true
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 300_000_000)
        // Load mock data
        dashboard = DeliverDashboard.mockData
        isLoading = false
    }
}
