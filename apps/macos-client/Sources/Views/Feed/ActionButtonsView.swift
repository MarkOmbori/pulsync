import SwiftUI

struct ActionButtonsView: View {
    @Environment(\.layoutEnvironment) private var layout
    @Binding var isLiked: Bool
    @Binding var isBookmarked: Bool
    @Binding var likeCount: Int
    let commentCount: Int
    let audioThumbnail: String? // URL for rotating disc

    let onLike: () -> Void
    let onBookmark: () -> Void
    let onComment: () -> Void
    let onShare: () -> Void
    var onDoubleTapLike: (() -> Void)? = nil

    private var sizeCategory: SizeCategory {
        layout.sizeCategory
    }

    var body: some View {
        VStack(spacing: sizeCategory.buttonSpacing) {
            // Like button with animated heart
            FloatingActionButton(
                icon: isLiked ? "heart.fill" : "heart",
                count: likeCount,
                isActive: isLiked,
                activeColor: .tikTokRed,
                category: sizeCategory,
                action: {
                    withAnimation(PulsyncAnimation.bouncy) {
                        isLiked.toggle()
                    }
                    onLike()
                }
            )

            // Comment button
            FloatingActionButton(
                icon: "bubble.right.fill",
                count: commentCount,
                isActive: false,
                activeColor: .white,
                category: sizeCategory,
                action: onComment
            )

            // Bookmark button
            FloatingActionButton(
                icon: isBookmarked ? "bookmark.fill" : "bookmark",
                count: nil,
                isActive: isBookmarked,
                activeColor: .yellow,
                category: sizeCategory,
                action: {
                    withAnimation(PulsyncAnimation.bouncy) {
                        isBookmarked.toggle()
                    }
                    onBookmark()
                }
            )

            // Share button
            FloatingActionButton(
                icon: "arrowshape.turn.up.right.fill",
                count: nil,
                isActive: false,
                activeColor: .white,
                category: sizeCategory,
                action: onShare
            )

            // Rotating audio disc (TikTok-style)
            if let thumbnail = audioThumbnail {
                RotatingAudioDisc(
                    thumbnailUrl: thumbnail,
                    isPlaying: true,
                    size: sizeCategory.buttonSize
                )
                .padding(.top, 8)
            }
        }
        // No background - floating individual buttons
    }
}

// MARK: - Floating Action Button (TikTok/YouTube Shorts Style)

struct FloatingActionButton: View {
    let icon: String
    let count: Int?
    let isActive: Bool
    let activeColor: Color
    let category: SizeCategory
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    // Frosted glass background
                    Circle()
                        .fill(.ultraThinMaterial)

                    // Active state overlay
                    if isActive {
                        Circle()
                            .fill(activeColor.opacity(0.2))
                    }

                    // Icon
                    Image(systemName: icon)
                        .font(.system(size: category.iconSize, weight: .semibold))
                        .foregroundStyle(isActive ? activeColor : .white)
                        .textShadow()
                }
                .frame(width: category.buttonSize, height: category.buttonSize)
                .floatingShadow()

                // Count label below button
                if let count = count {
                    Text(formatCount(count))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .textShadow()
                }
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.85 : 1.0)
        .animation(PulsyncAnimation.bouncy, value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
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

// MARK: - Legacy ActionButton (for compatibility)

struct ActionButton: View {
    let icon: String
    let count: Int?
    let isActive: Bool
    let activeColor: Color
    let action: () -> Void

    var body: some View {
        FloatingActionButton(
            icon: icon,
            count: count,
            isActive: isActive,
            activeColor: activeColor,
            category: .medium,
            action: action
        )
    }
}
