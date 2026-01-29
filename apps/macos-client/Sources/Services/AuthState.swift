import Foundation
import SwiftUI

@MainActor
@Observable
class AuthState {
    static let shared = AuthState()

    var currentUser: User?
    var isAuthenticated: Bool { currentUser != nil }
    var isLoading = false
    var error: String?

    private let tokenKey = "pulsync_auth_token"

    private init() {}

    func initialize() async {
        // Try to restore session from stored token
        if let token = UserDefaults.standard.string(forKey: tokenKey) {
            APIClient.shared.authToken = token
            do {
                currentUser = try await APIClient.shared.getCurrentUser()
            } catch {
                // Token expired or invalid
                logout()
            }
        }
    }

    func login(email: String) async throws {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let response = try await APIClient.shared.login(token: email)
            currentUser = response.user
            UserDefaults.standard.set(response.accessToken, forKey: tokenKey)
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }

    func logout() {
        currentUser = nil
        APIClient.shared.logout()
        UserDefaults.standard.removeObject(forKey: tokenKey)
    }
}
