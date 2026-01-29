import SwiftUI

struct BookmarksView: View {
    @State private var bookmarks: [ContentFeedItem] = []
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Bookmarks")
                    .font(.title2.bold())
                Spacer()
            }
            .padding()
            .background(PulsyncTheme.surface)

            Divider()

            if isLoading && bookmarks.isEmpty {
                Spacer()
                ProgressView()
                Spacer()
            } else if let error = error, bookmarks.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title)
                        .foregroundStyle(.orange)
                    Text(error)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            } else if bookmarks.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "bookmark")
                        .font(.largeTitle)
                        .foregroundStyle(.gray)
                    Text("No bookmarks yet")
                        .foregroundStyle(.secondary)
                    Text("Save content to view it here later")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(bookmarks) { item in
                            BookmarkRow(item: item)
                        }
                    }
                    .padding()
                }
            }
        }
        .background(PulsyncTheme.background)
        .task {
            await loadBookmarks()
        }
    }

    private func loadBookmarks() async {
        isLoading = true
        error = nil

        do {
            bookmarks = try await APIClient.shared.getBookmarks()
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

struct BookmarkRow: View {
    let item: ContentFeedItem

    var body: some View {
        HStack(spacing: 16) {
            // Thumbnail/icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(PulsyncTheme.surface)
                    .frame(width: 80, height: 80)

                switch item.contentType {
                case .text:
                    Image(systemName: "doc.text")
                        .font(.title)
                        .foregroundStyle(Color.electricViolet)
                case .video:
                    Image(systemName: "play.circle.fill")
                        .font(.title)
                        .foregroundStyle(Color.electricViolet)
                case .audio:
                    Image(systemName: "waveform")
                        .font(.title)
                        .foregroundStyle(Color.electricViolet)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title ?? "Untitled")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(2)

                Text(item.author.displayName)
                    .font(.caption)
                    .foregroundStyle(.gray)

                HStack(spacing: 16) {
                    Label("\(item.likeCount)", systemImage: "heart")
                    Label("\(item.commentCount)", systemImage: "bubble.right")
                }
                .font(.caption)
                .foregroundStyle(.gray)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.gray)
        }
        .padding()
        .background(PulsyncTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
