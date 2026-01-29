import SwiftUI

struct AnalyticsView: View {
    @State private var analytics: AnalyticsData?
    @State private var isLoading = false
    @State private var error: String?
    @State private var selectedPeriod = 7

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Period selector
                HStack {
                    Text("Analytics")
                        .font(.title.bold())

                    Spacer()

                    Picker("Period", selection: $selectedPeriod) {
                        Text("7 days").tag(7)
                        Text("30 days").tag(30)
                        Text("90 days").tag(90)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 250)
                }
                .padding()

                if isLoading && analytics == nil {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 300)
                } else if let error = error {
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.title)
                            .foregroundStyle(.orange)
                        Text(error)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 300)
                } else if let data = analytics {
                    // Totals
                    HStack(spacing: 16) {
                        StatCard(title: "Total Content", value: "\(data.totals.content)", icon: "doc.text", color: .blue)
                        StatCard(title: "Total Users", value: "\(data.totals.users)", icon: "person.3", color: .green)
                    }

                    // Recent activity
                    HStack(spacing: 16) {
                        StatCard(title: "New Content", value: "\(data.recentActivity.contentCreated)", icon: "plus.circle", color: Color.electricViolet)
                        StatCard(title: "Likes", value: "\(data.recentActivity.likes)", icon: "heart", color: .red)
                        StatCard(title: "Comments", value: "\(data.recentActivity.comments)", icon: "bubble.right", color: .orange)
                        StatCard(title: "Views", value: "\(data.recentActivity.views)", icon: "eye", color: .purple)
                    }

                    // Completion rate
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Average Completion Rate")
                            .font(.headline)
                        HStack {
                            Text("\(String(format: "%.1f", data.avgCompletionPercent))%")
                                .font(.largeTitle.bold())
                                .foregroundStyle(Color.electricViolet)

                            Spacer()

                            // Progress bar
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(.gray.opacity(0.3))
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.electricViolet)
                                        .frame(width: geo.size.width * data.avgCompletionPercent / 100)
                                }
                            }
                            .frame(height: 16)
                        }
                    }
                    .padding()
                    .background(PulsyncTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Top content
                    HStack(alignment: .top, spacing: 16) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Top Liked")
                                .font(.headline)
                            ForEach(data.topLiked, id: \.id) { item in
                                HStack {
                                    Text(item.title ?? "Untitled")
                                        .lineLimit(1)
                                    Spacer()
                                    Text("\(item.likes)")
                                        .foregroundStyle(.gray)
                                }
                            }
                        }
                        .padding()
                        .background(PulsyncTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Top Viewed")
                                .font(.headline)
                            ForEach(data.topViewed, id: \.id) { item in
                                HStack {
                                    Text(item.title ?? "Untitled")
                                        .lineLimit(1)
                                    Spacer()
                                    Text("\(item.views)")
                                        .foregroundStyle(.gray)
                                }
                            }
                        }
                        .padding()
                        .background(PulsyncTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding()
        }
        .background(PulsyncTheme.background)
        .task {
            await loadAnalytics()
        }
        .onChange(of: selectedPeriod) { _, _ in
            Task { await loadAnalytics() }
        }
    }

    private func loadAnalytics() async {
        isLoading = true
        error = nil

        do {
            analytics = try await APIClient.shared.get("/admin/analytics?days=\(selectedPeriod)")
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .foregroundStyle(.gray)
            }
            .font(.caption)

            Text(value)
                .font(.title.bold())
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(PulsyncTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// Analytics data model
struct AnalyticsData: Decodable {
    let periodDays: Int
    let totals: Totals
    let recentActivity: RecentActivity
    let contentByType: [String: Int]
    let topLiked: [TopContent]
    let topViewed: [TopContent]
    let avgCompletionPercent: Double

    enum CodingKeys: String, CodingKey {
        case totals
        case topLiked = "top_liked"
        case topViewed = "top_viewed"
        case periodDays = "period_days"
        case recentActivity = "recent_activity"
        case contentByType = "content_by_type"
        case avgCompletionPercent = "avg_completion_percent"
    }

    struct Totals: Decodable {
        let content: Int
        let users: Int
    }

    struct RecentActivity: Decodable {
        let contentCreated: Int
        let likes: Int
        let comments: Int
        let views: Int

        enum CodingKeys: String, CodingKey {
            case likes, comments, views
            case contentCreated = "content_created"
        }
    }

    struct TopContent: Decodable {
        let id: String
        let title: String?
        let type: String
        let likes: Int
        let views: Int

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(String.self, forKey: .id)
            title = try container.decodeIfPresent(String.self, forKey: .title)
            type = try container.decode(String.self, forKey: .type)
            likes = try container.decodeIfPresent(Int.self, forKey: .likes) ?? 0
            views = try container.decodeIfPresent(Int.self, forKey: .views) ?? 0
        }

        enum CodingKeys: String, CodingKey {
            case id, title, type, likes, views
        }
    }
}
