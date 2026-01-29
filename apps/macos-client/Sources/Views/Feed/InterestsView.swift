import SwiftUI

struct InterestsView: View {
    @State private var tags: [Tag] = []
    @State private var followedTagIds: Set<UUID> = []
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Interests")
                    .font(.title2.bold())
                Spacer()
            }
            .padding()
            .background(PulsyncTheme.surface)

            Divider()

            if isLoading && tags.isEmpty {
                Spacer()
                ProgressView()
                Spacer()
            } else if let error = error, tags.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title)
                        .foregroundStyle(.orange)
                    Text(error)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // Group by category
                        let grouped = Dictionary(grouping: tags) { $0.category ?? "Other" }
                        ForEach(grouped.keys.sorted(), id: \.self) { category in
                            Section {
                                ForEach(grouped[category] ?? []) { tag in
                                    TagRow(
                                        tag: tag,
                                        isFollowed: followedTagIds.contains(tag.id),
                                        onToggle: { toggleFollow(tag) }
                                    )
                                }
                            } header: {
                                HStack {
                                    Text(category.capitalized)
                                        .font(.headline)
                                        .foregroundStyle(.gray)
                                    Spacer()
                                }
                                .padding()
                                .background(PulsyncTheme.background)
                            }
                        }
                    }
                }
            }
        }
        .background(PulsyncTheme.background)
        .task {
            await loadTags()
        }
    }

    private func loadTags() async {
        isLoading = true
        error = nil

        do {
            tags = try await APIClient.shared.getTags()
            // Load user interests to see which are followed
            // For now, we'll track locally
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    private func toggleFollow(_ tag: Tag) {
        let isCurrentlyFollowed = followedTagIds.contains(tag.id)

        if isCurrentlyFollowed {
            followedTagIds.remove(tag.id)
        } else {
            followedTagIds.insert(tag.id)
        }

        Task {
            do {
                try await APIClient.shared.followTag(tagId: tag.id, follow: !isCurrentlyFollowed)
            } catch {
                // Revert on error
                if isCurrentlyFollowed {
                    followedTagIds.insert(tag.id)
                } else {
                    followedTagIds.remove(tag.id)
                }
            }
        }
    }
}

struct TagRow: View {
    let tag: Tag
    let isFollowed: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(tag.name)
                    .font(.headline)
                    .foregroundStyle(.white)

                Text("#\(tag.slug)")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }

            Spacer()

            Button(action: onToggle) {
                Text(isFollowed ? "Following" : "Follow")
                    .font(.caption.bold())
                    .foregroundStyle(isFollowed ? .white : Color.electricViolet)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(isFollowed ? Color.electricViolet : Color.electricViolet.opacity(0.2))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(PulsyncTheme.surface)
    }
}
