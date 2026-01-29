import SwiftUI

struct ContentReviewView: View {
    @State private var content: [ContentFeedItem] = []
    @State private var isLoading = false
    @State private var error: String?
    @State private var filterType: String?
    @State private var filterImportant: Bool?

    var body: some View {
        VStack(spacing: 0) {
            // Filters
            HStack(spacing: 16) {
                Picker("Type", selection: $filterType) {
                    Text("All Types").tag(nil as String?)
                    Text("Text").tag("text" as String?)
                    Text("Video").tag("video" as String?)
                    Text("Audio").tag("audio" as String?)
                }
                .pickerStyle(.menu)

                Picker("Important", selection: $filterImportant) {
                    Text("All").tag(nil as Bool?)
                    Text("Important Only").tag(true as Bool?)
                    Text("Regular Only").tag(false as Bool?)
                }
                .pickerStyle(.menu)

                Spacer()

                Button("Refresh") {
                    Task { await loadContent() }
                }
            }
            .padding()
            .background(PulsyncTheme.surface)

            Divider()

            if isLoading && content.isEmpty {
                Spacer()
                ProgressView()
                Spacer()
            } else if let error = error, content.isEmpty {
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
                Table(content) {
                    TableColumn("Type") { item in
                        HStack {
                            Image(systemName: iconFor(item.contentType))
                            Text(item.contentType.rawValue.capitalized)
                        }
                    }
                    .width(80)

                    TableColumn("Title") { item in
                        Text(item.title ?? "Untitled")
                    }
                    .width(min: 150, ideal: 200)

                    TableColumn("Author") { item in
                        Text(item.author.displayName)
                    }
                    .width(120)

                    TableColumn("Important") { item in
                        Toggle("", isOn: Binding(
                            get: { item.isCompanyImportant },
                            set: { _ in toggleImportant(item) }
                        ))
                        .toggleStyle(.switch)
                    }
                    .width(80)

                    TableColumn("Engagement") { item in
                        HStack(spacing: 8) {
                            Label("\(item.likeCount)", systemImage: "heart")
                            Label("\(item.commentCount)", systemImage: "bubble.right")
                        }
                        .font(.caption)
                    }
                    .width(120)

                    TableColumn("Actions") { item in
                        HStack {
                            Button(action: { deleteContent(item) }) {
                                Image(systemName: "trash")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .width(60)
                }
            }
        }
        .background(PulsyncTheme.background)
        .task {
            await loadContent()
        }
        .onChange(of: filterType) { _, _ in Task { await loadContent() } }
        .onChange(of: filterImportant) { _, _ in Task { await loadContent() } }
    }

    private func loadContent() async {
        isLoading = true
        error = nil

        do {
            // Build query parameters
            var path = "/admin/content?"
            if let type = filterType {
                path += "content_type=\(type)&"
            }
            if let important = filterImportant {
                path += "is_company_important=\(important)&"
            }
            content = try await APIClient.shared.get(path)
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    private func toggleImportant(_ item: ContentFeedItem) {
        Task {
            do {
                struct ImportantRequest: Encodable {
                    let isImportant: Bool

                    enum CodingKeys: String, CodingKey {
                        case isImportant = "is_important"
                    }
                }
                let _: EmptyResponse = try await APIClient.shared.patch(
                    "/admin/content/\(item.id)/important?is_important=\(!item.isCompanyImportant)",
                    body: EmptyBody()
                )
                await loadContent()
            } catch {
                // Show error
            }
        }
    }

    private func deleteContent(_ item: ContentFeedItem) {
        Task {
            do {
                try await APIClient.shared.delete("/admin/content/\(item.id)")
                content.removeAll { $0.id == item.id }
            } catch {
                // Show error
            }
        }
    }

    private func iconFor(_ type: ContentType) -> String {
        switch type {
        case .text: return "doc.text"
        case .video: return "play.circle"
        case .audio: return "waveform"
        }
    }
}
