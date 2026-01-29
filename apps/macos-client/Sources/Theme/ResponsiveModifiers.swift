import SwiftUI

// MARK: - Responsive View Modifiers

extension View {
    /// Apply responsive sizing to action buttons
    func responsiveActionButton(for category: SizeCategory) -> some View {
        self.frame(width: category.buttonSize, height: category.buttonSize)
    }

    /// Apply responsive sizing to content overlay
    func responsiveOverlay(for category: SizeCategory) -> some View {
        self.frame(maxWidth: category.overlayWidth, alignment: .leading)
    }

    /// Apply responsive padding
    func responsivePadding(for category: SizeCategory) -> some View {
        self
            .padding(.horizontal, category.horizontalPadding)
            .padding(.vertical, category.verticalPadding)
    }

    /// Scale font based on size category
    func responsiveFont(_ style: Font.TextStyle, for category: SizeCategory, weight: Font.Weight = .regular) -> some View {
        self
            .font(.system(style, weight: weight))
            .scaleEffect(category.fontScale)
    }

    /// Floating container with blur background
    func floatingContainer(cornerRadius: CGFloat = 20) -> some View {
        self
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .floatingShadow()
    }
}

// MARK: - Action Button Style

struct PillButtonStyle: ButtonStyle {
    let isActive: Bool
    let activeColor: Color
    let category: SizeCategory

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: category.buttonSize, height: category.buttonSize)
            .background(
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Circle()
                            .fill(isActive ? activeColor.opacity(0.3) : Color.clear)
                    )
            )
            .clipShape(Circle())
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(PulsyncAnimation.bouncy, value: configuration.isPressed)
    }
}

// MARK: - Safe Area Calculations

struct SafeAreaInsets {
    let category: SizeCategory

    var actionButtonsInset: CGFloat {
        switch category {
        case .small: return 8
        case .medium: return 12
        case .large: return 16
        }
    }

    var bottomOverlayInset: CGFloat {
        switch category {
        case .small: return 80
        case .medium: return 100
        case .large: return 120
        }
    }
}
