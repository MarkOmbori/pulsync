import SwiftUI

struct UsersView: View {
    @State private var users: [User] = []
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Users")
                    .font(.title.bold())
                Spacer()
                Button("Refresh") {
                    Task { await loadUsers() }
                }
            }
            .padding()
            .background(PulsyncTheme.surface)

            Divider()

            if isLoading && users.isEmpty {
                Spacer()
                ProgressView()
                Spacer()
            } else if let error = error, users.isEmpty {
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
                Table(users) {
                    TableColumn("Name") { user in
                        HStack {
                            Circle()
                                .fill(Color.electricViolet)
                                .frame(width: 32, height: 32)
                                .overlay {
                                    Text(String(user.displayName.prefix(1)))
                                        .font(.caption.bold())
                                        .foregroundStyle(.white)
                                }
                            Text(user.displayName)
                        }
                    }

                    TableColumn("Email") { user in
                        Text(user.email)
                    }

                    TableColumn("Role") { user in
                        Text(user.role.rawValue.capitalized)
                    }
                    .width(100)

                    TableColumn("Department") { user in
                        Text(user.department)
                    }
                    .width(120)

                    TableColumn("Comms Team") { user in
                        Toggle("", isOn: Binding(
                            get: { user.isCommsTeam },
                            set: { _ in toggleCommsTeam(user) }
                        ))
                        .toggleStyle(.switch)
                    }
                    .width(100)
                }
            }
        }
        .background(PulsyncTheme.background)
        .task {
            await loadUsers()
        }
    }

    private func loadUsers() async {
        isLoading = true
        error = nil

        do {
            users = try await APIClient.shared.get("/admin/users")
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    private func toggleCommsTeam(_ user: User) {
        Task {
            do {
                let _: EmptyResponse = try await APIClient.shared.patch(
                    "/admin/users/\(user.id)/comms-team?is_comms_team=\(!user.isCommsTeam)",
                    body: EmptyBody()
                )
                await loadUsers()
            } catch {
                // Show error
            }
        }
    }
}
