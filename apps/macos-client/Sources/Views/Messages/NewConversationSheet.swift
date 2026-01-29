import SwiftUI

struct NewConversationSheet: View {
    @Binding var isPresented: Bool
    let onConversationCreated: (Conversation) -> Void

    @State private var searchQuery = ""
    @State private var searchResults: [UserPublic] = []
    @State private var selectedUsers: [UserPublic] = []
    @State private var initialMessage = ""
    @State private var isSearching = false
    @State private var isCreating = false
    @State private var error: String?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("New Conversation")
                    .font(.headline)
                Spacer()
                Button("Cancel") {
                    isPresented = false
                }
                .buttonStyle(.plain)
                .foregroundStyle(.gray)
            }
            .padding()
            .background(PulsyncTheme.surface)

            Divider()

            // Selected users
            if !selectedUsers.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(selectedUsers) { user in
                            SelectedUserChip(user: user) {
                                selectedUsers.removeAll { $0.id == user.id }
                            }
                        }
                    }
                    .padding()
                }
                .background(PulsyncTheme.surface.opacity(0.5))

                Divider()
            }

            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.gray)
                TextField("Search users...", text: $searchQuery)
                    .textFieldStyle(.plain)
                    .onChange(of: searchQuery) { _, newValue in
                        performSearch(query: newValue)
                    }
                if isSearching {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }
            .padding()
            .background(PulsyncTheme.surface)

            Divider()

            // Search results
            if searchResults.isEmpty && !searchQuery.isEmpty && !isSearching {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "person.slash")
                        .font(.title)
                        .foregroundStyle(.gray)
                    Text("No users found")
                        .foregroundStyle(.secondary)
                }
                Spacer()
            } else {
                List(searchResults) { user in
                    UserSearchRow(user: user, isSelected: selectedUsers.contains { $0.id == user.id }) {
                        toggleUserSelection(user)
                    }
                    .listRowBackground(Color.clear)
                }
                .listStyle(.plain)
            }

            if !selectedUsers.isEmpty {
                Divider()

                // Initial message (optional)
                HStack {
                    TextField("Message (optional)", text: $initialMessage, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(1...3)
                }
                .padding()
                .background(PulsyncTheme.surface)

                Divider()

                // Create button
                Button(action: createConversation) {
                    if isCreating {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    } else {
                        Text("Start Conversation")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                }
                .buttonStyle(.plain)
                .background(Color.electricViolet)
                .foregroundStyle(.white)
                .cornerRadius(8)
                .disabled(isCreating || selectedUsers.isEmpty)
                .padding()
            }

            if let error = error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            }
        }
        .frame(minWidth: 400, minHeight: 500)
        .background(PulsyncTheme.background)
    }

    private func performSearch(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }

        isSearching = true

        Task {
            do {
                // Debounce
                try await Task.sleep(nanoseconds: 300_000_000)
                searchResults = try await APIClient.shared.searchUsers(query: query)
            } catch {
                // Ignore errors during typing
            }
            isSearching = false
        }
    }

    private func toggleUserSelection(_ user: UserPublic) {
        if let index = selectedUsers.firstIndex(where: { $0.id == user.id }) {
            selectedUsers.remove(at: index)
        } else {
            selectedUsers.append(user)
        }
    }

    private func createConversation() {
        guard !selectedUsers.isEmpty else { return }

        isCreating = true
        error = nil

        Task {
            do {
                let conversation = try await APIClient.shared.createConversation(
                    participantIds: selectedUsers.map { $0.id },
                    initialMessage: initialMessage.isEmpty ? nil : initialMessage
                )
                onConversationCreated(conversation)
                isPresented = false
            } catch {
                self.error = error.localizedDescription
            }
            isCreating = false
        }
    }
}

struct SelectedUserChip: View {
    let user: UserPublic
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Text(user.displayName)
                .font(.caption)
                .foregroundStyle(.white)

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.electricViolet)
        .cornerRadius(16)
    }
}

struct UserSearchRow: View {
    let user: UserPublic
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(Color.electricViolet.opacity(0.3))

                    Text(String(user.displayName.prefix(1)).uppercased())
                        .font(.caption.bold())
                        .foregroundStyle(Color.electricViolet)
                }
                .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(user.displayName)
                        .font(.body)
                        .foregroundStyle(.white)

                    Text(user.department)
                        .font(.caption)
                        .foregroundStyle(.gray)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.electricViolet)
                }
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
