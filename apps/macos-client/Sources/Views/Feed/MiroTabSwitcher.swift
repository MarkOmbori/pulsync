import SwiftUI

/// Inline tab switcher with underline indicator (TikTok/Instagram style)
struct MiroTabSwitcher: View {
    @Binding var selectedTab: FeedTabView.FeedTab

    var body: some View {
        HStack(spacing: 24) {
            ForEach(FeedTabView.FeedTab.allCases, id: \.self) { tab in
                tabButton(for: tab)
            }
        }
    }

    @ViewBuilder
    private func tabButton(for tab: FeedTabView.FeedTab) -> some View {
        let isSelected = selectedTab == tab

        Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                Text(tab.shortLabel)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .medium, design: .rounded))
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.5))

                // Underline indicator
                Rectangle()
                    .fill(isSelected ? .white : Color.clear)
                    .frame(height: 2)
                    .cornerRadius(1)
            }
            .padding(.horizontal, 4)
        }
        .buttonStyle(.plain)
    }
}

// Extension to provide short labels
extension FeedTabView.FeedTab {
    var shortLabel: String {
        switch self {
        case .forYou: return "For You"
        case .following: return "Following"
        }
    }
}
