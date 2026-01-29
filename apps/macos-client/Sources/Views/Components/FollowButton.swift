import SwiftUI

/// Compact follow/following button (TikTok/Instagram style)
struct FollowButton: View {
    @Binding var isFollowing: Bool
    let onToggle: () -> Void

    @State private var isAnimating = false

    var body: some View {
        Button(action: toggleFollow) {
            HStack(spacing: PulsyncSpacing.xs) {
                Image(systemName: isFollowing ? PulsyncIcons.checkmark : "plus")
                    .font(.system(size: PulsyncTypography.Size.micro, weight: .bold))

                Text(isFollowing ? "Following" : "Follow")
                    .font(.pulsyncCaption)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(isFollowing ? PulsyncTheme.textPrimary : PulsyncTheme.background)
            .padding(.horizontal, PulsyncSpacing.ms)
            .padding(.vertical, PulsyncSpacing.xs + 2)
            .background(
                Capsule()
                    .fill(isFollowing ? Color.clear : PulsyncTheme.textPrimary)
                    .overlay(
                        Capsule()
                            .stroke(PulsyncTheme.textPrimary, lineWidth: isFollowing ? 1 : 0)
                    )
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isAnimating ? 0.9 : 1.0)
        .animation(DesignSystem.Animation.bouncy, value: isAnimating)
    }

    private func toggleFollow() {
        isAnimating = true

        withAnimation(DesignSystem.Animation.smooth) {
            isFollowing.toggle()
        }

        onToggle()

        // Reset animation state
        DispatchQueue.main.asyncAfter(deadline: .now() + DesignSystem.Animation.fast) {
            isAnimating = false
        }
    }
}

// MARK: - Compact Follow Button (Icon Only)

struct CompactFollowButton: View {
    @Binding var isFollowing: Bool
    let onToggle: () -> Void
    var size: CGFloat = 24

    @State private var isAnimating = false

    var body: some View {
        Button(action: toggleFollow) {
            ZStack {
                Circle()
                    .fill(isFollowing ? PulsyncTheme.textMuted : PulsyncTheme.followBlue)
                    .frame(width: size, height: size)

                Image(systemName: isFollowing ? PulsyncIcons.checkmark : "plus")
                    .font(.system(size: size * 0.5, weight: .bold))
                    .foregroundStyle(PulsyncTheme.textPrimary)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isAnimating ? 0.8 : 1.0)
        .animation(DesignSystem.Animation.bouncy, value: isAnimating)
    }

    private func toggleFollow() {
        isAnimating = true

        withAnimation(DesignSystem.Animation.smooth) {
            isFollowing.toggle()
        }

        onToggle()

        DispatchQueue.main.asyncAfter(deadline: .now() + DesignSystem.Animation.fast) {
            isAnimating = false
        }
    }
}

// MARK: - Avatar with Follow Badge

struct AvatarWithFollowBadge: View {
    let avatarUrl: String?
    let displayName: String
    @Binding var isFollowing: Bool
    let onFollowToggle: () -> Void
    var avatarSize: CGFloat = 48

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Avatar
            if let urlString = avatarUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    defaultAvatar
                }
                .frame(width: avatarSize, height: avatarSize)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                )
            } else {
                defaultAvatar
                    .frame(width: avatarSize, height: avatarSize)
            }

            // Follow badge
            CompactFollowButton(
                isFollowing: $isFollowing,
                onToggle: onFollowToggle,
                size: avatarSize * 0.4
            )
            .offset(x: 4, y: 4)
        }
    }

    private var defaultAvatar: some View {
        Circle()
            .fill(PulsyncTheme.primary)
            .overlay {
                Text(String(displayName.prefix(1)).uppercased())
                    .font(.system(size: avatarSize * 0.4, weight: .bold))
                    .foregroundStyle(PulsyncTheme.textPrimary)
            }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        FollowButton(isFollowing: .constant(false)) {}
        FollowButton(isFollowing: .constant(true)) {}

        CompactFollowButton(isFollowing: .constant(false), onToggle: {})
        CompactFollowButton(isFollowing: .constant(true), onToggle: {})

        AvatarWithFollowBadge(
            avatarUrl: nil,
            displayName: "John Doe",
            isFollowing: .constant(false),
            onFollowToggle: {}
        )
    }
    .padding()
    .background(PulsyncTheme.background)
}
