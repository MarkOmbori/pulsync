import SwiftUI

/// Compact follow/following button (TikTok/Instagram style)
struct FollowButton: View {
    @Binding var isFollowing: Bool
    let onToggle: () -> Void

    @State private var isAnimating = false

    var body: some View {
        Button(action: toggleFollow) {
            HStack(spacing: 4) {
                if isFollowing {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                } else {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .bold))
                }

                Text(isFollowing ? "Following" : "Follow")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(isFollowing ? .white : PulsyncTheme.background)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isFollowing ? Color.clear : Color.white)
                    .overlay(
                        Capsule()
                            .stroke(Color.white, lineWidth: isFollowing ? 1 : 0)
                    )
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isAnimating ? 0.9 : 1.0)
        .animation(PulsyncAnimation.bouncy, value: isAnimating)
    }

    private func toggleFollow() {
        isAnimating = true

        withAnimation(PulsyncAnimation.smooth) {
            isFollowing.toggle()
        }

        onToggle()

        // Reset animation state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
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
                    .fill(isFollowing ? Color.gray.opacity(0.5) : Color.tikTokRed)
                    .frame(width: size, height: size)

                Image(systemName: isFollowing ? "checkmark" : "plus")
                    .font(.system(size: size * 0.5, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isAnimating ? 0.8 : 1.0)
        .animation(PulsyncAnimation.bouncy, value: isAnimating)
    }

    private func toggleFollow() {
        isAnimating = true

        withAnimation(PulsyncAnimation.smooth) {
            isFollowing.toggle()
        }

        onToggle()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
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
            .fill(Color.electricViolet)
            .overlay {
                Text(String(displayName.prefix(1)).uppercased())
                    .font(.system(size: avatarSize * 0.4, weight: .bold))
                    .foregroundStyle(.white)
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
    .background(Color.black)
}
