import SwiftUI

/// Integrated tab switcher with subtle selection indicator
struct MiroTabSwitcher: View {
    @Binding var selectedTab: FeedTabView.FeedTab

    var body: some View {
        HStack(spacing: 4) {
            ForEach(FeedTabView.FeedTab.allCases, id: \.self) { tab in
                tabButton(for: tab)
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.1))
        )
    }

    @ViewBuilder
    private func tabButton(for tab: FeedTabView.FeedTab) -> some View {
        let isSelected = selectedTab == tab

        Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                selectedTab = tab
            }
        } label: {
            Text(tab.shortLabel)
                .font(.system(size: 13, weight: isSelected ? .semibold : .medium, design: .rounded))
                .foregroundStyle(isSelected ? MiroColors.textDark : .white.opacity(0.6))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? MiroColors.miroYellow : Color.clear)
                )
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
