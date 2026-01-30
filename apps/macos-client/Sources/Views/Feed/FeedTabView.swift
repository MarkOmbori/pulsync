import SwiftUI

struct FeedTabView: View {
    @Environment(\.layoutEnvironment) private var layout
    @State private var selectedTab: FeedTab = .forYou

    enum FeedTab: String, CaseIterable {
        case forYou = "For You"
        case following = "Following"
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

            // Miro-style header with branding and tabs
            MiroFeedHeaderView(selectedTab: $selectedTab)
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
