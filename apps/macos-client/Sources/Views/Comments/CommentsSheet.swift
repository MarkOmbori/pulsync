import SwiftUI

struct CommentsSheet: View {
    let contentId: UUID
    @Binding var isPresented: Bool

    @State private var comments: [Comment] = []
    @State private var newComment = ""
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Comments")
                    .font(.headline)
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.gray)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(PulsyncTheme.surface)

            Divider()

            // Comments list
            if isLoading && comments.isEmpty {
                Spacer()
                ProgressView()
                Spacer()
            } else if let error = error, comments.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title)
                        .foregroundStyle(.orange)
                    Text(error)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            } else if comments.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.title)
                        .foregroundStyle(.gray)
                    Text("No comments yet")
                        .foregroundStyle(.secondary)
                    Text("Be the first to comment!")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(comments) { comment in
                            CommentRow(comment: comment, onDelete: {
                                deleteComment(comment)
                            })
                        }
                    }
                    .padding()
                }
            }

            Divider()

            // New comment input
            HStack(spacing: 12) {
                TextField("Add a comment...", text: $newComment)
                    .textFieldStyle(.roundedBorder)

                Button(action: postComment) {
                    Image(systemName: "paperplane.fill")
                        .foregroundStyle(newComment.isEmpty ? .gray : Color.electricViolet)
                }
                .buttonStyle(.plain)
                .disabled(newComment.isEmpty)
            }
            .padding()
            .background(PulsyncTheme.surface)
        }
        .frame(minWidth: 400, minHeight: 500)
        .background(PulsyncTheme.background)
        .task {
            await loadComments()
        }
    }

    private func loadComments() async {
        isLoading = true
        error = nil

        do {
            comments = try await APIClient.shared.getComments(contentId: contentId)
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    private func postComment() {
        guard !newComment.isEmpty else { return }

        let body = newComment
        newComment = ""

        Task {
            do {
                let comment = try await APIClient.shared.createComment(contentId: contentId, body: body)
                comments.insert(comment, at: 0)
            } catch {
                // Show error
                newComment = body // Restore on failure
            }
        }
    }

    private func deleteComment(_ comment: Comment) {
        Task {
            do {
                try await APIClient.shared.deleteComment(id: comment.id)
                comments.removeAll { $0.id == comment.id }
            } catch {
                // Show error
            }
        }
    }
}

struct CommentRow: View {
    let comment: Comment
    let onDelete: () -> Void

    @State private var showDeleteConfirm = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar
            Circle()
                .fill(Color.electricViolet)
                .frame(width: 36, height: 36)
                .overlay {
                    Text(String(comment.author.displayName.prefix(1)))
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(comment.author.displayName)
                        .font(.caption.bold())
                        .foregroundStyle(.white)

                    Text(comment.createdAt, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.gray)

                    Spacer()

                    if comment.author.id == AuthState.shared.currentUser?.id {
                        Button(action: { showDeleteConfirm = true }) {
                            Image(systemName: "trash")
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Text(comment.body)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.9))

                if comment.replyCount > 0 {
                    Text("\(comment.replyCount) replies")
                        .font(.caption)
                        .foregroundStyle(Color.electricViolet)
                }
            }
        }
        .alert("Delete Comment", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive, action: onDelete)
        } message: {
            Text("Are you sure you want to delete this comment?")
        }
    }
}
