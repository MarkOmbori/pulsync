import SwiftUI

/// Miro-style playful action buttons with colorful accents
struct MiroActionButtonsView: View {
    @Environment(\.layoutEnvironment) private var layout
    @Binding var isLiked: Bool
    @Binding var isBookmarked: Bool
    @Binding var likeCount: Int
    let commentCount: Int

    let onLike: () -> Void
    let onBookmark: () -> Void
    let onComment: () -> Void
    let onShare: () -> Void

    private var sizeCategory: SizeCategory {
        layout.sizeCategory
    }

    var body: some View {
        VStack(spacing: buttonSpacing) {
            // Like button - Coral/Red accent
            MiroActionButton(
                icon: isLiked ? "heart.fill" : "heart",
                count: likeCount,
                isActive: isLiked,
                accentColor: MiroColors.statusRed,
                category: sizeCategory
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isLiked.toggle()
                    likeCount += isLiked ? 1 : -1
                }
                onLike()
            }

            // Comment button - Teal accent
            MiroActionButton(
                icon: "bubble.left.fill",
                count: commentCount,
                isActive: false,
                accentColor: MiroColors.miroTeal,
                category: sizeCategory,
                action: onComment
            )

            // Bookmark button - Yellow accent
            MiroActionButton(
                icon: isBookmarked ? "bookmark.fill" : "bookmark",
                count: nil,
                isActive: isBookmarked,
                accentColor: MiroColors.miroYellow,
                category: sizeCategory
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isBookmarked.toggle()
                }
                onBookmark()
            }

            // Share button - Blue accent
            MiroActionButton(
                icon: "paperplane.fill",
                count: nil,
                isActive: false,
                accentColor: MiroColors.miroBlue,
                category: sizeCategory,
                action: onShare
            )
        }
    }

    private var buttonSpacing: CGFloat {
        switch sizeCategory {
        case .small: return 14
        case .medium: return 18
        case .large: return 22
        }
    }
}

/// Individual Miro-style action button with playful design
struct MiroActionButton: View {
    let icon: String
    let count: Int?
    let isActive: Bool
    let accentColor: Color
    let category: SizeCategory
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    // Soft rounded square background
                    RoundedRectangle(cornerRadius: MiroRadius.medium)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: MiroRadius.medium)
                                .fill(isActive ? accentColor.opacity(0.2) : Color.clear)
                        )

                    // Icon
                    Image(systemName: icon)
                        .font(.system(size: iconSize, weight: .semibold))
                        .foregroundStyle(isActive ? accentColor : .white)
                        .symbolEffect(.bounce, value: isActive)
                }
                .frame(width: buttonSize, height: buttonSize)
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)

                // Count label
                if let count = count {
                    Text(formatCount(count))
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                }
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }

    private var buttonSize: CGFloat {
        switch category {
        case .small: return 42
        case .medium: return 48
        case .large: return 54
        }
    }

    private var iconSize: CGFloat {
        switch category {
        case .small: return 20
        case .medium: return 24
        case .large: return 28
        }
    }

    private func formatCount(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000)
        } else if count >= 1000 {
            return String(format: "%.1fK", Double(count) / 1000)
        }
        return "\(count)"
    }
}
