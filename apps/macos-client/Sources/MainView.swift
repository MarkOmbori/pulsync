import SwiftUI

struct MainView: View {
    @Environment(AuthState.self) private var authState
    @Environment(\.layoutEnvironment) private var layout
    @State private var isInitializing = true
    @State private var selectedTab: BottomTab = .home
    @State private var apiOnline = false
    @State private var globalAIChatState = GlobalAIChatState()

    enum BottomTab: String, CaseIterable {
        case home = "Home"
        case discover = "Discover"
        case define = "Define"
        case deliver = "Deliver"
        case chat = "Chat"
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
            PulsyncTheme.background
                .ignoresSafeArea()

            // Main content area
            VStack(spacing: 0) {
                // Content based on selected tab
                tabContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Bottom Navigation Bar
                bottomNavigationBar

                // Global AI Chat Bar (at very bottom)
                GlobalAIChatBar()
            }
        }
        .environment(\.globalAIChat, globalAIChatState)
        .task {
            await globalAIChatState.initialize()
        }
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .home:
            FeedTabView()
        case .discover:
            DiscoverFeedView()
        case .define:
            DefineView()
        case .deliver:
            DeliverView()
        case .chat:
            // Use SlackChatView for Slack integration, fallback to CompanyChatView
            SlackChatView()
        }
    }

    // MARK: - Bottom Navigation Bar (TikTok Style)

    private var bottomNavigationBar: some View {
        HStack(spacing: 0) {
            ForEach(BottomTab.allCases, id: \.self) { tab in
                tabButton(for: tab)
            }
        }
        .padding(.horizontal, PulsyncSpacing.sm)
        .padding(.top, PulsyncSpacing.sm)
        .padding(.bottom, PulsyncSpacing.xs)
        .background(
            // Gradient fade from content
            LinearGradient.navigationFade
                .frame(height: 100)
                .offset(y: -40)
                .allowsHitTesting(false),
            alignment: .top
        )
        .background(PulsyncTheme.background)
    }

    private func tabButton(for tab: BottomTab) -> some View {
        Button(action: { selectedTab = tab }) {
            VStack(spacing: PulsyncSpacing.xs) {
                Image(systemName: iconFor(tab))
                    .font(.system(size: PulsyncSize.Icon.lg))
                    .fontWeight(selectedTab == tab ? .semibold : .regular)

                Text(tab.rawValue)
                    .font(.pulsyncMicro)
            }
            .foregroundStyle(selectedTab == tab ? PulsyncTheme.textPrimary : PulsyncTheme.textMuted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, PulsyncSpacing.sm)
        }
        .buttonStyle(.plain)
    }

    private func iconFor(_ tab: BottomTab) -> String {
        switch tab {
        case .home: return selectedTab == tab ? "house.fill" : "house"
        case .discover: return selectedTab == tab ? "magnifyingglass" : "magnifyingglass"
        case .define: return selectedTab == tab ? "checkmark.circle.fill" : "checkmark.circle"
        case .deliver: return selectedTab == tab ? "chart.bar.fill" : "chart.bar"
        case .chat: return selectedTab == tab ? "bubble.left.and.bubble.right.fill" : "bubble.left.and.bubble.right"
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
            HStack(spacing: PulsyncSpacing.sm) {
                Image(systemName: PulsyncIcons.search)
                    .foregroundStyle(PulsyncTheme.textMuted)
                TextField("Search Pulsync", text: $searchText)
                    .textFieldStyle(.plain)
                    .foregroundStyle(PulsyncTheme.textPrimary)
            }
            .padding(PulsyncSpacing.ms)
            .background(PulsyncTheme.surface)
            .clipShape(Capsule())
            .padding(PulsyncSpacing.md)

            // Trending content grid
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 2) {
                    ForEach(0..<12, id: \.self) { _ in
                        Rectangle()
                            .fill(PulsyncTheme.surface)
                            .aspectRatio(9/16, contentMode: .fill)
                    }
                }
            }
        }
        .background(PulsyncTheme.background)
    }
}

// MARK: - Loading View

struct LoadingView: View {
    var body: some View {
        VStack(spacing: PulsyncSpacing.md) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(PulsyncTheme.primary)
            Text("Loading...")
                .font(.pulsyncBody)
                .foregroundStyle(PulsyncTheme.textMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PulsyncTheme.background)
    }
}

// MARK: - API Offline View

struct APIOfflineView: View {
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: PulsyncSpacing.lg) {
            Image(systemName: PulsyncIcons.error)
                .font(.system(size: PulsyncSize.Icon.huge))
                .foregroundStyle(PulsyncTheme.warning)

            Text("Connection Error")
                .font(.pulsyncTitle1)
                .foregroundStyle(PulsyncTheme.textPrimary)

            Text("Unable to connect to server")
                .font(.pulsyncBody)
                .foregroundStyle(PulsyncTheme.textMuted)

            Button(action: onRetry) {
                Text("Retry")
                    .font(.pulsyncLabel)
                    .foregroundStyle(.white)
                    .padding(.horizontal, PulsyncSpacing.xxl)
                    .padding(.vertical, PulsyncSpacing.ms)
                    .background(PulsyncTheme.primary)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PulsyncTheme.background)
    }
}
