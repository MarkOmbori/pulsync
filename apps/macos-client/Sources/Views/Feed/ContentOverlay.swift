import SwiftUI

struct ContentOverlay: View {
    @Environment(\.layoutEnvironment) private var layout
    let item: ContentFeedItem
    @State private var isFollowing = false
    @State private var isDescriptionExpanded = false

    private var sizeCategory: SizeCategory {
        layout.sizeCategory
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Author row: Avatar + Username + Follow button
            HStack(spacing: 12) {
                // Avatar with optional follow badge
                avatarView
                    .frame(width: avatarSize, height: avatarSize)

                VStack(alignment: .leading, spacing: 2) {
                    // Username row with follow button
                    HStack(spacing: 8) {
                        Text(item.author.displayName)
                            .font(.system(size: 16 * sizeCategory.fontScale, weight: .bold))
                            .foregroundStyle(.white)
                            .textShadow()

                        FollowButton(isFollowing: $isFollowing) {
                            toggleFollow()
                        }
                    }

                    // Handle/department
                    Text("@\(item.author.department.lowercased().replacingOccurrences(of: " ", with: "_"))")
                        .font(.system(size: 13 * sizeCategory.fontScale))
                        .foregroundStyle(.white.opacity(0.8))
                        .textShadow()
                }
            }

            // Description with "...more" collapse
            if let title = item.title, !title.isEmpty {
                descriptionView(text: title)
            } else if let body = item.body, !body.isEmpty {
                descriptionView(text: body)
            }

            // Tags as hashtags
            if !item.tags.isEmpty {
                tagsView
            }

            // Audio indicator (if applicable)
            if item.contentType == .audio || item.contentType == .video {
                audioIndicator
            }
        }
        .responsiveOverlay(for: sizeCategory)
        // No background - transparent overlay on gradient
    }

    // MARK: - Subviews

    private var avatarView: some View {
        Group {
            if let avatarUrl = item.author.avatarUrl, let url = URL(string: avatarUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    defaultAvatar
                }
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                )
            } else {
                defaultAvatar
            }
        }
    }

    private var defaultAvatar: some View {
        Circle()
            .fill(Color.electricViolet)
            .overlay {
                Text(String(item.author.displayName.prefix(1)).uppercased())
                    .font(.system(size: avatarSize * 0.4, weight: .bold))
                    .foregroundStyle(.white)
            }
    }

    @ViewBuilder
    private func descriptionView(text: String) -> some View {
        let shouldTruncate = text.count > 80 && !isDescriptionExpanded

        VStack(alignment: .leading, spacing: 4) {
            Text(shouldTruncate ? String(text.prefix(80)) + "..." : text)
                .font(.system(size: 14 * sizeCategory.fontScale))
                .foregroundStyle(.white)
                .textShadow()
                .lineLimit(isDescriptionExpanded ? nil : 2)

            if text.count > 80 {
                Button(action: { isDescriptionExpanded.toggle() }) {
                    Text(isDescriptionExpanded ? "less" : "more")
                        .font(.system(size: 14 * sizeCategory.fontScale, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var tagsView: some View {
        // Horizontal scrolling tags (TikTok style)
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(item.tags) { tag in
                    Text("#\(tag.name)")
                        .font(.system(size: 14 * sizeCategory.fontScale, weight: .semibold))
                        .foregroundStyle(.white)
                        .textShadow()
                }
            }
        }
    }

    private var audioIndicator: some View {
        HStack(spacing: 8) {
            Image(systemName: "music.note")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)

            Text("Original audio - \(item.author.displayName)")
                .font(.system(size: 13 * sizeCategory.fontScale))
                .foregroundStyle(.white)
                .textShadow()
                .lineLimit(1)
        }
    }

    // MARK: - Computed Properties

    private var avatarSize: CGFloat {
        switch sizeCategory {
        case .small: return 40
        case .medium: return 48
        case .large: return 56
        }
    }

    // MARK: - Actions

    private func toggleFollow() {
        // TODO: API call to follow/unfollow user
        Task {
            // try? await APIClient.shared.toggleFollowUser(userId: item.author.id)
        }
    }
}

// Simple flow layout for tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY), proposal: .unspecified)
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        var frames: [CGRect] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        let maxWidth = proposal.width ?? .infinity

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), frames)
    }
}
