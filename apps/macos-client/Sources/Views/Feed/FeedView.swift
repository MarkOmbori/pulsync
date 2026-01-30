import SwiftUI

struct FeedView: View {
    @State private var feedItems: [ContentFeedItem] = []
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
                        .tint(.white)
                } else if let error = error, feedItems.isEmpty {
                    errorView(message: error)
                } else if feedItems.isEmpty {
                    emptyView
                } else {
                    feedContent(geometry: geometry)
                }
            }
        }
        .task {
            await loadFeed()
        }
    }

    // MARK: - Feed Content

    private func feedContent(geometry: GeometryProxy) -> some View {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVStack(spacing: 0) {
                ForEach(Array(feedItems.enumerated()), id: \.element.id) { index, item in
                    ContentCard(item: item)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .onAppear {
                            recordView(for: item)

                            // Load more when near end
                            if index >= feedItems.count - 3 && hasMore && !isLoading {
                                Task { await loadMoreFeed() }
                            }
                        }
                }
            }
        }
    }

    // MARK: - Empty & Error Views

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 50))
                .foregroundStyle(.gray)
            Text("No content yet")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundStyle(.orange)
            Text(message)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Retry") {
                Task { await loadFeed() }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    // MARK: - Data Loading

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

            // Filter out video/audio items without valid media URLs
            feedItems = response.items.filter { item in
                switch item.contentType {
                case .video, .audio:
                    guard let mediaUrl = item.mediaUrl,
                          !mediaUrl.isEmpty,
                          URL(string: mediaUrl) != nil else {
                        return false
                    }
                    return true
                case .text:
                    return true
                }
            }
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

            // Filter out video/audio items without valid media URLs
            let validItems = response.items.filter { item in
                switch item.contentType {
                case .video, .audio:
                    guard let mediaUrl = item.mediaUrl,
                          !mediaUrl.isEmpty,
                          URL(string: mediaUrl) != nil else {
                        return false
                    }
                    return true
                case .text:
                    return true
                }
            }
            feedItems.append(contentsOf: validItems)
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
