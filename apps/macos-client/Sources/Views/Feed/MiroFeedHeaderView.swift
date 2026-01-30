import SwiftUI

/// Complete Miro-style feed header with branding, tabs, and clean layout
struct MiroFeedHeaderView: View {
    @Environment(\.layoutEnvironment) private var layout
    @Binding var selectedTab: FeedTabView.FeedTab

    private var sizeCategory: SizeCategory {
        layout.sizeCategory
    }

    var body: some View {
        HStack {
            // Left spacer for balance
            Spacer()

            // Center: Tab Switcher
            MiroTabSwitcher(selectedTab: $selectedTab)

            Spacer()

            // Right: Miro + Pulsync branding
            brandingView
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.top, topPadding)
    }

    @ViewBuilder
    private var brandingView: some View {
        switch sizeCategory {
        case .small:
            MiroBrandingCompact()
        case .medium, .large:
            MiroBrandingView()
        }
    }

    private var horizontalPadding: CGFloat {
        switch sizeCategory {
        case .small: return 12
        case .medium: return 16
        case .large: return 20
        }
    }

    private var topPadding: CGFloat {
        switch sizeCategory {
        case .small: return 8
        case .medium: return 12
        case .large: return 16
        }
    }
}
