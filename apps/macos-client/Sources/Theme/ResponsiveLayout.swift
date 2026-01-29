import SwiftUI

/// Device preview sizes for responsive design testing
enum DevicePreviewSize: String, CaseIterable, Identifiable {
    case iPhoneSE = "iPhone SE"
    case iPhone14Pro = "iPhone 14 Pro"
    case iPhone15ProMax = "iPhone 15 Pro Max"
    case iPadMini = "iPad Mini"
    case iPadPro11 = "iPad Pro 11\""
    case desktop = "Desktop"
    case custom = "Custom"

    var id: String { rawValue }

    /// Physical screen dimensions
    var size: CGSize {
        switch self {
        case .iPhoneSE: return CGSize(width: 375, height: 667)
        case .iPhone14Pro: return CGSize(width: 393, height: 852)
        case .iPhone15ProMax: return CGSize(width: 430, height: 932)
        case .iPadMini: return CGSize(width: 744, height: 1133)
        case .iPadPro11: return CGSize(width: 834, height: 1194)
        case .desktop: return CGSize(width: 0, height: 0) // Full window
        case .custom: return CGSize(width: 400, height: 800)
        }
    }

    /// SF Symbol icon for device type
    var icon: String {
        switch self {
        case .iPhoneSE, .iPhone14Pro, .iPhone15ProMax:
            return "iphone"
        case .iPadMini, .iPadPro11:
            return "ipad"
        case .desktop:
            return "macbook"
        case .custom:
            return "rectangle.dashed"
        }
    }

    /// Size category for responsive layouts
    var sizeCategory: SizeCategory {
        switch self {
        case .iPhoneSE, .iPhone14Pro:
            return .small
        case .iPhone15ProMax, .iPadMini:
            return .medium
        case .iPadPro11, .desktop:
            return .large
        case .custom:
            return .medium
        }
    }
}

/// Size categories for responsive adaptations
enum SizeCategory {
    case small   // iPhone SE/14
    case medium  // Pro Max/iPad Mini
    case large   // iPad Pro/Desktop

    /// Button size for action buttons
    var buttonSize: CGFloat {
        switch self {
        case .small: return 44
        case .medium: return 52
        case .large: return 60
        }
    }

    /// Icon size for action button icons
    var iconSize: CGFloat {
        switch self {
        case .small: return 22
        case .medium: return 26
        case .large: return 30
        }
    }

    /// Spacing between action buttons
    var buttonSpacing: CGFloat {
        switch self {
        case .small: return 16
        case .medium: return 18
        case .large: return 24
        }
    }

    /// Maximum width for author overlay
    var overlayWidth: CGFloat {
        switch self {
        case .small: return 280
        case .medium: return 340
        case .large: return 400
        }
    }

    /// Font scale factor
    var fontScale: CGFloat {
        switch self {
        case .small: return 0.85
        case .medium: return 1.0
        case .large: return 1.1
        }
    }

    /// Horizontal padding
    var horizontalPadding: CGFloat {
        switch self {
        case .small: return 12
        case .medium: return 16
        case .large: return 24
        }
    }

    /// Vertical padding
    var verticalPadding: CGFloat {
        switch self {
        case .small: return 8
        case .medium: return 12
        case .large: return 16
        }
    }
}

/// Observable environment for layout configuration
@Observable
final class LayoutEnvironment: @unchecked Sendable {
    var currentPreviewSize: DevicePreviewSize = .desktop
    var customSize: CGSize = CGSize(width: 400, height: 800)
    var isImmersiveMode: Bool = false

    /// Get the actual size to use for preview
    var effectiveSize: CGSize {
        if currentPreviewSize == .custom {
            return customSize
        }
        return currentPreviewSize.size
    }

    /// Whether the preview should be constrained (not full window)
    var isConstrained: Bool {
        currentPreviewSize != .desktop
    }

    /// Current size category for responsive layouts
    var sizeCategory: SizeCategory {
        if currentPreviewSize == .custom {
            // Determine category based on width
            if customSize.width < 400 {
                return .small
            } else if customSize.width < 750 {
                return .medium
            } else {
                return .large
            }
        }
        return currentPreviewSize.sizeCategory
    }
}

/// Environment key for LayoutEnvironment
struct LayoutEnvironmentKey: EnvironmentKey {
    static let defaultValue = LayoutEnvironment()
}

extension EnvironmentValues {
    var layoutEnvironment: LayoutEnvironment {
        get { self[LayoutEnvironmentKey.self] }
        set { self[LayoutEnvironmentKey.self] = newValue }
    }
}
