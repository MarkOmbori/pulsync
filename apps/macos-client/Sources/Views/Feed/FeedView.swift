import SwiftUI

struct FeedView: View {
    @State private var feedItems: [ContentFeedItem] = []
    @State private var currentIndex = 0
    @State private var isLoading = false
    @State private var error: String?
    @State private var nextCursor: String?
    @State private var hasMore = true

    let feedType: FeedType

    enum FeedType {
        case forYou
        case following
        case discover
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                PulsyncTheme.background
                    .ignoresSafeArea()

                if isLoading && feedItems.isEmpty {
                    ProgressView()
                        .scaleEffect(1.5)
                } else if let error = error, feedItems.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundStyle(.orange)
                        Text(error)
                            .foregroundStyle(.secondary)
                        Button("Retry") {
                            Task { await loadFeed() }
                        }
                    }
                } else if feedItems.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "tray")
                            .font(.largeTitle)
                            .foregroundStyle(.gray)
                        Text("No content yet")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    // Vertical swipe container
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(feedItems.enumerated()), id: \.element.id) { index, item in
                                ContentCard(item: item)
                                    .frame(width: geometry.size.width, height: geometry.size.height)
                                    .onAppear {
                                        // Record view when card appears
                                        recordView(for: item)

                                        // Load more when near end
                                        if index >= feedItems.count - 3 && hasMore && !isLoading {
                                            Task { await loadMoreFeed() }
                                        }
                                    }
                            }
                        }
                    }
                    .scrollTargetBehavior(.paging)
                }
            }
        }
        .task {
            await loadFeed()
        }
    }

    private func loadFeed() async {
        isLoading = true
        error = nil

        do {
            let response: FeedResponse
            switch feedType {
            case .forYou:
                response = try await APIClient.shared.getForYouFeed()
            case .following:
                response = try await APIClient.shared.getFollowingFeed()
            case .discover:
                response = try await APIClient.shared.getDiscoverFeed()
            }

            feedItems = response.items
            nextCursor = response.nextCursor
            hasMore = response.hasMore
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    private func loadMoreFeed() async {
        guard let cursor = nextCursor, !isLoading else { return }
        isLoading = true

        do {
            let response: FeedResponse
            switch feedType {
            case .forYou:
                response = try await APIClient.shared.getForYouFeed(cursor: cursor)
            case .following:
                response = try await APIClient.shared.getFollowingFeed(cursor: cursor)
            case .discover:
                response = try await APIClient.shared.getDiscoverFeed(cursor: cursor)
            }

            feedItems.append(contentsOf: response.items)
            nextCursor = response.nextCursor
            hasMore = response.hasMore
        } catch {
            // Silently fail on load more
        }

        isLoading = false
    }

    private func recordView(for item: ContentFeedItem) {
        Task {
            try? await APIClient.shared.recordView(
                contentId: item.id,
                duration: 5,
                completion: 100.0
            )
        }
    }
}
