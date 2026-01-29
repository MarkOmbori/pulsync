import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var onLogin: () -> Void

    var body: some View {
        VStack(spacing: 40) {
            // Logo
            VStack(spacing: 8) {
                Text("pulsync")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(.white)
                Text("Internal Content Platform")
                    .font(.headline)
                    .foregroundStyle(.gray)
            }

            // Login form
            VStack(spacing: 16) {
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 300)
                    .disabled(isLoading)

                if let error = errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }

                Button(action: login) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(.circular)
                        }
                        Text(isLoading ? "Signing in..." : "Sign In")
                    }
                    .frame(width: 300)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.electricViolet)
                .disabled(email.isEmpty || isLoading)
            }

            // Demo hint
            Text("For demo: enter any email address")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PulsyncTheme.background)
    }

    private func login() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                try await AuthState.shared.login(email: email)
                onLogin()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
