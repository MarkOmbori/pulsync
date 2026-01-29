import SwiftUI

struct MainView: View {
    @Environment(AuthState.self) private var authState
    @Environment(\.layoutEnvironment) private var layout
    @State private var isInitializing = true
    @State private var selectedTab: BottomTab = .home
    @State private var apiOnline = false

    enum BottomTab: String, CaseIterable {
        case home = "Home"
        case discover = "Discover"
        case define = "Define"
        case deliver = "Deliver"
    }

    var body: some View {
        Group {
            if isInitializing {
                LoadingView()
            } else if !apiOnline {
                APIOfflineView {
                    Task { await checkAPI() }
                }
            } else if !authState.isAuthenticated {
                LoginView(onLogin: {})
            } else {
                socialMediaLayout
            }
        }
        .task {
            await initialize()
        }
    }

    // MARK: - Social Media Style Layout

    private var socialMediaLayout: some View {
        ZStack {
            // Full screen dark background
            Color.black
                .ignoresSafeArea()

            // Main content area
            VStack(spacing: 0) {
                // Content based on selected tab
                tabContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Bottom Navigation Bar
                bottomNavigationBar
            }
        }
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .home:
            FeedTabView()
        case .discover:
            DiscoverView()
        case .define:
            DefineView()
        case .deliver:
            DeliverView()
        }
    }

    // MARK: - Bottom Navigation Bar (TikTok Style)

    private var bottomNavigationBar: some View {
        HStack(spacing: 0) {
            ForEach(BottomTab.allCases, id: \.self) { tab in
                tabButton(for: tab)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(
            // Gradient fade from content
            LinearGradient(
                colors: [.clear, .black.opacity(0.8), .black],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 100)
            .offset(y: -40)
            .allowsHitTesting(false),
            alignment: .top
        )
        .background(Color.black)
    }

    private func tabButton(for tab: BottomTab) -> some View {
        Button(action: { selectedTab = tab }) {
            VStack(spacing: 4) {
                Image(systemName: iconFor(tab))
                    .font(.system(size: 22))
                    .fontWeight(selectedTab == tab ? .semibold : .regular)

                Text(tab.rawValue)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(selectedTab == tab ? .white : .gray)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }

    private func iconFor(_ tab: BottomTab) -> String {
        switch tab {
        case .home: return selectedTab == tab ? "house.fill" : "house"
        case .discover: return selectedTab == tab ? "magnifyingglass" : "magnifyingglass"
        case .define: return selectedTab == tab ? "checkmark.circle.fill" : "checkmark.circle"
        case .deliver: return selectedTab == tab ? "chart.bar.fill" : "chart.bar"
        }
    }

    private func initialize() async {
        await checkAPI()
        if apiOnline {
            await authState.initialize()
        }
        isInitializing = false
    }

    private func checkAPI() async {
        apiOnline = await APIClient.shared.checkHealth()
    }
}

// MARK: - Discover View (Search/Explore)

struct DiscoverView: View {
    @State private var searchText = ""

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.gray)
                TextField("Search", text: $searchText)
                    .textFieldStyle(.plain)
                    .foregroundStyle(.white)
            }
            .padding(12)
            .background(Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding()

            // Trending content grid would go here
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 2) {
                    ForEach(0..<12, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .aspectRatio(9/16, contentMode: .fill)
                    }
                }
            }
        }
        .background(Color.black)
    }
}

// MARK: - Loading View

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)
            Text("Loading...")
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

// MARK: - API Offline View

struct APIOfflineView: View {
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 64))
                .foregroundStyle(.orange)

            Text("Connection Error")
                .font(.title2.bold())
                .foregroundStyle(.white)

            Text("Unable to connect to server")
                .foregroundStyle(.gray)

            Button(action: onRetry) {
                Text("Retry")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 12)
                    .background(Color.electricViolet)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}
