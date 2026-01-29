import SwiftUI
import AppKit

struct ContentCard: View {
    @Environment(\.layoutEnvironment) private var layout
    let item: ContentFeedItem

    @State private var isLiked: Bool
    @State private var isBookmarked: Bool
    @State private var likeCount: Int
    @State private var showComments = false
    @State private var showLikeAnimation = false

    init(item: ContentFeedItem) {
        self.item = item
        _isLiked = State(initialValue: item.isLiked)
        _isBookmarked = State(initialValue: item.isBookmarked)
        _likeCount = State(initialValue: item.likeCount)
    }

    private var sizeCategory: SizeCategory {
        layout.sizeCategory
    }

    var body: some View {
        ZStack {
            // Layer 1: Background
            PulsyncTheme.background

            // Layer 2: Content based on type (full bleed)
            contentView
                .ignoresSafeArea()

            // Layer 3: Bottom gradient overlay
            VStack {
                Spacer()
                LinearGradient.bottomFade
                    .frame(height: gradientHeight)
            }
            .ignoresSafeArea()

            // Layer 4: Author info (bottom-left) + Actions (right)
            VStack {
                Spacer()

                HStack(alignment: .bottom, spacing: 16) {
                    // Left side: Author info (no background)
                    ContentOverlay(item: item)
                        .responsivePadding(for: sizeCategory)

                    Spacer()

                    // Right side: Floating action buttons
                    ActionButtonsView(
                        isLiked: $isLiked,
                        isBookmarked: $isBookmarked,
                        likeCount: $likeCount,
                        commentCount: item.commentCount,
                        audioThumbnail: item.contentType == .audio ? item.mediaUrl : nil,
                        onLike: toggleLike,
                        onBookmark: toggleBookmark,
                        onComment: { showComments = true },
                        onShare: shareContent
                    )
                    .padding(.trailing, sizeCategory.horizontalPadding)
                }
                .padding(.bottom, bottomPadding)
            }

            // Layer 5: Like animation (center, temporary)
            if showLikeAnimation {
                LikeAnimationView(isVisible: $showLikeAnimation)
            }
        }
        // Double-tap to like gesture
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            handleDoubleTap()
        }
        .sheet(isPresented: $showComments) {
            CommentsSheet(contentId: item.id, isPresented: $showComments)
        }
    }

    // MARK: - Content View Dispatch

    @ViewBuilder
    private var contentView: some View {
        switch item.contentType {
        case .text:
            TextContentView(item: item)
        case .video:
            VideoContentView(item: item)
        case .audio:
            AudioContentView(item: item)
        }
    }

    // MARK: - Responsive Sizing

    private var gradientHeight: CGFloat {
        switch sizeCategory {
        case .small: return 250
        case .medium: return 300
        case .large: return 350
        }
    }

    private var bottomPadding: CGFloat {
        switch sizeCategory {
        case .small: return 60
        case .medium: return 80
        case .large: return 100
        }
    }

    // MARK: - Actions

    private func handleDoubleTap() {
        // Show animation
        showLikeAnimation = true

        // Like if not already liked
        if !isLiked {
            withAnimation(PulsyncAnimation.bouncy) {
                isLiked = true
                likeCount += 1
            }
            // API call
            Task {
                do {
                    _ = try await APIClient.shared.toggleLike(contentId: item.id)
                } catch {
                    // Revert on error
                    await MainActor.run {
                        isLiked = false
                        likeCount -= 1
                    }
                }
            }
        }
    }

    private func toggleLike() {
        Task {
            do {
                let response = try await APIClient.shared.toggleLike(contentId: item.id)
                isLiked = response.isLiked
                likeCount += response.isLiked ? 1 : -1
            } catch {
                // Revert on error
                isLiked.toggle()
            }
        }
    }

    private func toggleBookmark() {
        Task {
            do {
                let response = try await APIClient.shared.toggleBookmark(contentId: item.id)
                isBookmarked = response.isBookmarked
            } catch {
                // Revert on error
                isBookmarked.toggle()
            }
        }
    }

    private func shareContent() {
        // macOS share sheet
        let content = "Check out this post on Pulsync: \(item.title ?? "Untitled")"
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(content, forType: .string)
    }
}
