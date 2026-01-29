import SwiftUI

struct FeedTabView: View {
    @Environment(\.layoutEnvironment) private var layout
    @State private var selectedTab: FeedTab = .forYou
    @State private var hasScrolled = false

    enum FeedTab: String, CaseIterable {
        case forYou = "For You"
        case following = "Following"
    }

    private var sizeCategory: SizeCategory {
        layout.sizeCategory
    }

    var body: some View {
        ZStack(alignment: .top) {
            // Feed content (full screen, behind tabs)
            TabView(selection: $selectedTab) {
                FeedView(feedType: .forYou)
                    .tag(FeedTab.forYou)

                FeedView(feedType: .following)
                    .tag(FeedTab.following)
            }
            .tabViewStyle(.automatic)
            .ignoresSafeArea()

            // Floating tab bar overlay at top center
            floatingTabBar
                .padding(.top, topPadding)
        }
    }

    // MARK: - Floating Tab Bar (TikTok Style)

    private var floatingTabBar: some View {
        HStack(spacing: tabSpacing) {
            ForEach(FeedTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(PulsyncAnimation.smooth) {
                        selectedTab = tab
                    }
                }) {
                    Text(tab.rawValue)
                        .font(.system(size: fontSize, weight: selectedTab == tab ? .bold : .medium))
                        .foregroundStyle(selectedTab == tab ? .white : .white.opacity(0.6))
                        .textShadow()
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(
            // Semi-transparent background when scrolled
            Capsule()
                .fill(.ultraThinMaterial.opacity(hasScrolled ? 1 : 0))
        )
    }

    // MARK: - Responsive Sizing

    private var topPadding: CGFloat {
        switch sizeCategory {
        case .small: return 12
        case .medium: return 16
        case .large: return 24
        }
    }

    private var tabSpacing: CGFloat {
        switch sizeCategory {
        case .small: return 20
        case .medium: return 28
        case .large: return 36
        }
    }

    private var fontSize: CGFloat {
        switch sizeCategory {
        case .small: return 15
        case .medium: return 17
        case .large: return 19
        }
    }
}

// MARK: - Minimal Tab Indicator (Alternative Style)

struct MinimalTabIndicator: View {
    let isSelected: Bool

    var body: some View {
        Circle()
            .fill(isSelected ? Color.white : Color.clear)
            .frame(width: 4, height: 4)
    }
}
