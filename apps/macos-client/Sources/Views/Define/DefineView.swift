import SwiftUI

struct DefineView: View {
    @State private var outcomes: [Outcome] = []
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Define")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    Text("Today's Outcomes")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                }
                Spacer()
            }
            .padding()

            if isLoading {
                Spacer()
                ProgressView()
                    .tint(.white)
                Spacer()
            } else if outcomes.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        // Meetings section
                        let meetings = outcomes.filter { $0.type == .meeting }
                        if !meetings.isEmpty {
                            sectionHeader(title: "Today's Meetings", icon: "calendar")
                            ForEach(meetings) { outcome in
                                MeetingBriefingView(outcome: outcome)
                            }
                        }

                        // Tasks section
                        let tasks = outcomes.filter { $0.type == .task }
                        if !tasks.isEmpty {
                            sectionHeader(title: "Outcomes to Accomplish", icon: "checkmark.circle")
                            ForEach(tasks) { outcome in
                                OutcomeItemView(outcome: outcome)
                            }
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
            await loadOutcomes()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "checkmark.circle")
                .font(.system(size: 64))
                .foregroundStyle(.gray.opacity(0.5))

            Text("No outcomes for today")
                .font(.title3.bold())
                .foregroundStyle(.white)

            Text("Your daily briefing will appear here.\nOutcomes show what you need to accomplish.")
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
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    private func loadOutcomes() async {
        isLoading = true
        // TODO: Load outcomes from API
        // For now, show sample data
        outcomes = sampleOutcomes
        isLoading = false
    }

    private var sampleOutcomes: [Outcome] {
        [
            Outcome(
                id: UUID(),
                userId: UUID(),
                type: .meeting,
                title: "Team Standup",
                description: "Daily sync with engineering team",
                howToAccomplish: nil,
                status: .todo,
                dueDate: nil,
                meetingTime: Date(),
                meetingParticipants: ["Alice", "Bob", "Charlie"],
                meetingAgenda: "1. Progress updates\n2. Blockers\n3. Goals for today",
                createdAt: Date(),
                updatedAt: Date()
            ),
            Outcome(
                id: UUID(),
                userId: UUID(),
                type: .task,
                title: "Review PR #123",
                description: "Code review for the new authentication feature",
                howToAccomplish: "1. Check out the branch\n2. Run tests locally\n3. Review code changes\n4. Leave comments",
                status: .todo,
                dueDate: Date(),
                meetingTime: nil,
                meetingParticipants: nil,
                meetingAgenda: nil,
                createdAt: Date(),
                updatedAt: Date()
            ),
            Outcome(
                id: UUID(),
                userId: UUID(),
                type: .task,
                title: "Update documentation",
                description: "Add API docs for new endpoints",
                howToAccomplish: "Document the /users and /projects endpoints in the OpenAPI spec",
                status: .inProgress,
                dueDate: Date(),
                meetingTime: nil,
                meetingParticipants: nil,
                meetingAgenda: nil,
                createdAt: Date(),
                updatedAt: Date()
            )
        ]
    }
}
