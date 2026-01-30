import SwiftUI

/// Miro-style compact pill tab switcher for "For You" / "Following"
struct MiroTabSwitcher: View {
    @Binding var selectedTab: FeedTabView.FeedTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(FeedTabView.FeedTab.allCases, id: \.self) { tab in
                tabButton(for: tab)
            }
        }
        .padding(3)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
        )
    }

    @ViewBuilder
    private func tabButton(for tab: FeedTabView.FeedTab) -> some View {
        let isSelected = selectedTab == tab

        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tab
            }
        } label: {
            Text(tab.shortLabel)
                .font(.system(size: 13, weight: isSelected ? .bold : .medium, design: .rounded))
                .foregroundStyle(isSelected ? MiroColors.textDark : .white.opacity(0.7))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
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
