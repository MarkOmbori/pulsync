import SwiftUI

// MARK: - Pulsync Spacing System

/// 4pt-based spacing scale for Pulsync design system.
enum PulsyncSpacing {
    // MARK: - Base Scale (4pt grid)

    /// No spacing (0pt)
    static let zero: CGFloat = 0

    /// Extra small spacing (4pt)
    static let xs: CGFloat = 4

    /// Small spacing (8pt)
    static let sm: CGFloat = 8

    /// Medium-small spacing (12pt)
    static let ms: CGFloat = 12

    /// Medium spacing (16pt) - Standard padding
    static let md: CGFloat = 16

    /// Medium-large spacing (20pt)
    static let ml: CGFloat = 20

    /// Large spacing (24pt) - Section gaps
    static let lg: CGFloat = 24

    /// Extra large spacing (32pt)
    static let xl: CGFloat = 32

    /// 2x extra large spacing (40pt)
    static let xxl: CGFloat = 40

    /// 3x extra large spacing (48pt)
    static let xxxl: CGFloat = 48

    /// Huge spacing (64pt) - Major sections
    static let huge: CGFloat = 64

    /// Massive spacing (80pt) - Page sections
    static let massive: CGFloat = 80
}

// MARK: - Border Radius

enum PulsyncRadius {
    /// No radius (0pt) - Square corners
    static let none: CGFloat = 0

    /// Small radius (4pt) - Small elements
    static let sm: CGFloat = 4

    /// Medium radius (8pt) - Buttons, inputs
    static let md: CGFloat = 8

    /// Large radius (12pt) - Cards
    static let lg: CGFloat = 12

    /// Extra large radius (16pt) - Large cards
    static let xl: CGFloat = 16

    /// 2x extra large radius (24pt) - Modals
    static let xxl: CGFloat = 24

    /// Full radius (9999pt) - Pills, circles
    static let full: CGFloat = 9999
}

// MARK: - Elevation (Shadows)

enum PulsyncElevation {
    /// Level 0 - No shadow
    static let level0 = ShadowConfig(radius: 0, y: 0, opacity: 0)

    /// Level 1 - Cards
    static let level1 = ShadowConfig(radius: 3, y: 1, opacity: 0.1)

    /// Level 2 - Floating buttons
    static let level2 = ShadowConfig(radius: 12, y: 4, opacity: 0.15)

    /// Level 3 - Modals
    static let level3 = ShadowConfig(radius: 24, y: 8, opacity: 0.2)

    /// Level 4 - Overlays
    static let level4 = ShadowConfig(radius: 48, y: 16, opacity: 0.25)

    struct ShadowConfig {
        let radius: CGFloat
        let y: CGFloat
        let opacity: Double
    }
}

// MARK: - Component Sizes

enum PulsyncSize {
    /// Touch target sizes
    enum TouchTarget {
        /// Minimum touch target (44pt)
        static let minimum: CGFloat = 44

        /// Recommended touch target (48pt)
        static let recommended: CGFloat = 48

        /// Large touch target (56pt)
        static let large: CGFloat = 56
    }

    /// Avatar sizes
    enum Avatar {
        /// Extra small (24pt) - Inline mentions
        static let xs: CGFloat = 24

        /// Small (32pt) - Comments, lists
        static let sm: CGFloat = 32

        /// Medium (40pt) - Feed items
        static let md: CGFloat = 40

        /// Large (56pt) - Profiles
        static let lg: CGFloat = 56

        /// Extra large (80pt) - Profile headers
        static let xl: CGFloat = 80
    }

    /// Icon sizes
    enum Icon {
        /// Small (16pt)
        static let sm: CGFloat = 16

        /// Medium (20pt)
        static let md: CGFloat = 20

        /// Large (24pt) - Standard
        static let lg: CGFloat = 24

        /// Extra large (32pt)
        static let xl: CGFloat = 32

        /// Huge (48pt) - Action buttons
        static let huge: CGFloat = 48
    }

    /// Button heights
    enum Button {
        /// Small button (32pt)
        static let sm: CGFloat = 32

        /// Medium button (36pt)
        static let md: CGFloat = 36

        /// Large button (44pt)
        static let lg: CGFloat = 44

        /// Extra large button (52pt)
        static let xl: CGFloat = 52
    }
}

// MARK: - View Modifiers

extension View {
    /// Apply standard card padding
    func cardPadding() -> some View {
        self.padding(PulsyncSpacing.md)
    }

    /// Apply section spacing
    func sectionSpacing() -> some View {
        self.padding(.vertical, PulsyncSpacing.lg)
    }

    /// Apply content padding (horizontal)
    func contentPadding() -> some View {
        self.padding(.horizontal, PulsyncSpacing.md)
    }

    /// Apply shadow elevation
    func elevation(_ level: PulsyncElevation.ShadowConfig) -> some View {
        self.shadow(
            color: .black.opacity(level.opacity),
            radius: level.radius,
            x: 0,
            y: level.y
        )
    }

    /// Apply card style (radius + elevation)
    func cardStyle() -> some View {
        self
            .clipShape(RoundedRectangle(cornerRadius: PulsyncRadius.lg))
            .elevation(PulsyncElevation.level1)
    }

    /// Apply modal style (radius + elevation)
    func modalStyle() -> some View {
        self
            .clipShape(RoundedRectangle(cornerRadius: PulsyncRadius.xxl))
            .elevation(PulsyncElevation.level3)
    }

    /// Apply pill shape (full radius)
    func pillShape() -> some View {
        self.clipShape(Capsule())
    }
}

// MARK: - Layout Helpers

extension View {
    /// Center content in available space
    func centered() -> some View {
        self.frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Full width
    func fullWidth() -> some View {
        self.frame(maxWidth: .infinity)
    }

    /// Safe area aware bottom padding (for tab bars)
    func tabBarSafeArea() -> some View {
        self.padding(.bottom, PulsyncSpacing.huge)
    }
}
