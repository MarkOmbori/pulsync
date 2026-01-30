import SwiftUI

/// Clean feed header with logo and inline tabs
struct MiroFeedHeaderView: View {
    @Environment(\.layoutEnvironment) private var layout
    @Binding var selectedTab: FeedTabView.FeedTab

    private var sizeCategory: SizeCategory {
        layout.sizeCategory
    }

    var body: some View {
        HStack(spacing: tabSpacing) {
            // Left: Pulsync branding with Miro logo
            brandingView

            // Inline: Tab Switcher (immediately after branding)
            MiroTabSwitcher(selectedTab: $selectedTab)

            Spacer()
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.top, topPadding)
    }

    private var tabSpacing: CGFloat {
        switch sizeCategory {
        case .small: return 16
        case .medium: return 20
        case .large: return 24
        }
    }

    @ViewBuilder
    private var brandingView: some View {
        switch sizeCategory {
        case .small:
            PulsyncBrandingCompact()
        case .medium, .large:
            PulsyncBrandingView()
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
