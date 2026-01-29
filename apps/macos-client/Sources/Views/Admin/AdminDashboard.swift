import SwiftUI

struct AdminDashboard: View {
    @State private var selectedSection: AdminSection = .content

    enum AdminSection: String, CaseIterable {
        case content = "Content"
        case analytics = "Analytics"
        case users = "Users"
    }

    var body: some View {
        NavigationSplitView {
            List(AdminSection.allCases, id: \.self, selection: $selectedSection) { section in
                Label {
                    Text(section.rawValue)
                } icon: {
                    Image(systemName: iconFor(section))
                }
            }
            .navigationTitle("Admin")
        } detail: {
            switch selectedSection {
            case .content:
                ContentReviewView()
            case .analytics:
                AnalyticsView()
            case .users:
                UsersView()
            }
        }
    }

    private func iconFor(_ section: AdminSection) -> String {
        switch section {
        case .content: return "doc.text"
        case .analytics: return "chart.bar"
        case .users: return "person.3"
        }
    }
}
