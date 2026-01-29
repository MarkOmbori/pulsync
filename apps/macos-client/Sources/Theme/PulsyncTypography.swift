import SwiftUI

// MARK: - Pulsync Typography System

/// Typography scale for Pulsync design system.
/// Uses SF Pro (system font) with semantic naming.
enum PulsyncTypography {
    // MARK: - Font Sizes

    enum Size {
        static let display: CGFloat = 36
        static let headline: CGFloat = 28
        static let title1: CGFloat = 22
        static let title2: CGFloat = 18
        static let bodyLarge: CGFloat = 17
        static let body: CGFloat = 15
        static let label: CGFloat = 14
        static let caption: CGFloat = 12
        static let micro: CGFloat = 10
    }

    // MARK: - Line Heights

    enum LineHeight {
        static let tight: CGFloat = 1.1
        static let snug: CGFloat = 1.25
        static let normal: CGFloat = 1.5
        static let relaxed: CGFloat = 1.625
    }

    // MARK: - Letter Spacing

    enum Tracking {
        static let tight: CGFloat = -0.02
        static let normal: CGFloat = 0
        static let wide: CGFloat = 0.02
    }
}

// MARK: - Font Styles

extension Font {
    /// Display style - Hero sections, large headings
    static var pulsyncDisplay: Font {
        .system(size: PulsyncTypography.Size.display, weight: .bold, design: .default)
    }

    /// Headline style - Page titles
    static var pulsyncHeadline: Font {
        .system(size: PulsyncTypography.Size.headline, weight: .semibold, design: .default)
    }

    /// Title 1 style - Section headers
    static var pulsyncTitle1: Font {
        .system(size: PulsyncTypography.Size.title1, weight: .semibold, design: .default)
    }

    /// Title 2 style - Card titles
    static var pulsyncTitle2: Font {
        .system(size: PulsyncTypography.Size.title2, weight: .medium, design: .default)
    }

    /// Body Large style - Primary content
    static var pulsyncBodyLarge: Font {
        .system(size: PulsyncTypography.Size.bodyLarge, weight: .regular, design: .default)
    }

    /// Body style - Standard content
    static var pulsyncBody: Font {
        .system(size: PulsyncTypography.Size.body, weight: .regular, design: .default)
    }

    /// Label style - Buttons, tabs, form labels
    static var pulsyncLabel: Font {
        .system(size: PulsyncTypography.Size.label, weight: .medium, design: .default)
    }

    /// Caption style - Meta information, timestamps
    static var pulsyncCaption: Font {
        .system(size: PulsyncTypography.Size.caption, weight: .regular, design: .default)
    }

    /// Micro style - Badges, counts
    static var pulsyncMicro: Font {
        .system(size: PulsyncTypography.Size.micro, weight: .medium, design: .default)
    }
}

// MARK: - View Modifiers

extension View {
    /// Apply display typography style
    func displayStyle() -> some View {
        self
            .font(.pulsyncDisplay)
            .tracking(PulsyncTypography.Tracking.tight * PulsyncTypography.Size.display)
    }

    /// Apply headline typography style
    func headlineStyle() -> some View {
        self
            .font(.pulsyncHeadline)
            .tracking(PulsyncTypography.Tracking.tight * PulsyncTypography.Size.headline)
    }

    /// Apply title 1 typography style
    func title1Style() -> some View {
        self
            .font(.pulsyncTitle1)
    }

    /// Apply title 2 typography style
    func title2Style() -> some View {
        self
            .font(.pulsyncTitle2)
    }

    /// Apply body large typography style
    func bodyLargeStyle() -> some View {
        self
            .font(.pulsyncBodyLarge)
            .lineSpacing(PulsyncTypography.Size.bodyLarge * (PulsyncTypography.LineHeight.normal - 1))
    }

    /// Apply body typography style
    func bodyStyle() -> some View {
        self
            .font(.pulsyncBody)
            .lineSpacing(PulsyncTypography.Size.body * (PulsyncTypography.LineHeight.normal - 1))
    }

    /// Apply label typography style
    func labelStyle() -> some View {
        self
            .font(.pulsyncLabel)
            .tracking(PulsyncTypography.Tracking.wide * PulsyncTypography.Size.label)
    }

    /// Apply caption typography style
    func captionStyle() -> some View {
        self
            .font(.pulsyncCaption)
            .foregroundColor(PulsyncColors.textSecondary)
    }

    /// Apply micro typography style
    func microStyle() -> some View {
        self
            .font(.pulsyncMicro)
            .tracking(PulsyncTypography.Tracking.wide * PulsyncTypography.Size.micro)
    }
}

// MARK: - Text Styles

extension Text {
    /// Primary text style (high emphasis)
    func textPrimary() -> Text {
        self.foregroundColor(PulsyncColors.textPrimary)
    }

    /// Secondary text style (medium emphasis)
    func textSecondary() -> Text {
        self.foregroundColor(PulsyncColors.textSecondary)
    }

    /// Muted text style (low emphasis)
    func textMuted() -> Text {
        self.foregroundColor(PulsyncColors.textMuted)
    }
}
