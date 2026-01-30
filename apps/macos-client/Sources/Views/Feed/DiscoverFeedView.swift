import SwiftUI
import AppKit

// MARK: - News Article Model

struct NewsArticle: Identifiable {
    let id = UUID()
    let title: String
    let summary: String
    let url: String
    let date: Date
    let source: String
}

// MARK: - Discover Feed View

struct DiscoverFeedView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PulsyncSpacing.lg) {
                // Header
                Text("Discover")
                    .font(.pulsyncHeadline)
                    .foregroundStyle(PulsyncTheme.textPrimary)
                    .padding(.horizontal, PulsyncSpacing.lg)
                    .padding(.top, PulsyncSpacing.lg)

                // Two-column layout
                HStack(alignment: .top, spacing: PulsyncSpacing.lg) {
                    // Left: Company News
                    VStack(alignment: .leading, spacing: PulsyncSpacing.md) {
                        SectionHeader(title: "COMPANY NEWS")

                        ForEach(companyNews) { article in
                            NewsArticleCard(article: article)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    // Right: Industry News
                    VStack(alignment: .leading, spacing: PulsyncSpacing.md) {
                        SectionHeader(title: "INDUSTRY NEWS")

                        ForEach(industryNews) { article in
                            NewsArticleCard(article: article)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, PulsyncSpacing.lg)
                .padding(.bottom, PulsyncSpacing.huge)
            }
        }
        .background(PulsyncTheme.background)
    }

    // MARK: - Seed Data: Company News

    private var companyNews: [NewsArticle] {
        [
            NewsArticle(
                title: "What's New: January 2026",
                summary: "Miro Engage, AI Knowledge Integrations, 76 new prototyping components and more.",
                url: "https://miro.com/blog/whats-new-january-2026/",
                date: Date().addingTimeInterval(-2 * 24 * 60 * 60), // 2 days ago
                source: "miro.com"
            ),
            NewsArticle(
                title: "Miro 2025 Recap: Top 25 Updates",
                summary: "100M users milestone, AI Innovation Workspace launch, and the features that defined the year.",
                url: "https://miro.com/blog/2025-recap/",
                date: Date().addingTimeInterval(-7 * 24 * 60 * 60), // 1 week ago
                source: "miro.com"
            ),
            NewsArticle(
                title: "Miro Acquires Butter",
                summary: "Bringing facilitation expertise into Miro's ecosystem to enhance collaborative workshops.",
                url: "https://www.butter.us/blog/a-new-chapter-for-butter-with-miro",
                date: Date().addingTimeInterval(-14 * 24 * 60 * 60), // 2 weeks ago
                source: "butter.us"
            ),
            NewsArticle(
                title: "Uizard Joins Miro",
                summary: "AI-powered design platform integration enables rapid prototyping directly in Miro.",
                url: "https://uizard.io/blog/uizard-joins-miro/",
                date: Date().addingTimeInterval(-21 * 24 * 60 * 60), // 3 weeks ago
                source: "uizard.io"
            ),
            NewsArticle(
                title: "Miro Puts AI Where Teams Work",
                summary: "Announcing AI Innovation Workspace - bringing generative AI directly into team collaboration.",
                url: "https://miro.com/newsroom/miro-puts-ai-where-teams-work/",
                date: Date().addingTimeInterval(-30 * 24 * 60 * 60), // 1 month ago
                source: "miro.com"
            ),
            NewsArticle(
                title: "Miro Community: Product News",
                summary: "Latest feature updates and announcements from the Miro product team.",
                url: "https://community.miro.com/product-news-31",
                date: Date().addingTimeInterval(-3 * 24 * 60 * 60), // 3 days ago
                source: "community.miro.com"
            )
        ]
    }

    // MARK: - Seed Data: Industry News

    private var industryNews: [NewsArticle] {
        [
            NewsArticle(
                title: "AI Tech Trends 2026",
                summary: "Multi-agent systems moving from lab to production, reshaping enterprise workflows.",
                url: "https://www.ibm.com/think/news/ai-tech-trends-predictions-2026",
                date: Date().addingTimeInterval(-7 * 24 * 60 * 60), // 1 week ago
                source: "ibm.com"
            ),
            NewsArticle(
                title: "Enterprise Tech: 15 Trends to Watch",
                summary: "AI, SaaS, and data trends shaping enterprise technology in 2026.",
                url: "https://www.constellationr.com/blog-news/insights/enterprise-technology-2026-15-ai-saas-data-business-trends-watch",
                date: Date().addingTimeInterval(-3 * 24 * 60 * 60), // 3 days ago
                source: "constellationr.com"
            ),
            NewsArticle(
                title: "6 Workplace Trends Shaping 2026",
                summary: "AI integration, flexibility, and middle manager pressure define the evolving workplace.",
                url: "https://www.prsa.org/article/6-workplace-trends-shaping-2026-jan26",
                date: Date().addingTimeInterval(-5 * 24 * 60 * 60), // 5 days ago
                source: "prsa.org"
            ),
            NewsArticle(
                title: "CES 2026: Collaboration Tech",
                summary: "10 technologies reshaping enterprise workplaces from this year's Consumer Electronics Show.",
                url: "https://www.uctoday.com/devices-workspace-tech/ces-2026-10-collaboration-technologies-reshaping-enterprise-workplaces/",
                date: Date().addingTimeInterval(-10 * 24 * 60 * 60), // 10 days ago
                source: "uctoday.com"
            ),
            NewsArticle(
                title: "AI Adoption in Enterprise 2026",
                summary: "Only 3% of companies have AI truly reshaping work - what separates leaders from laggards.",
                url: "https://www.techrepublic.com/article/ai-adoption-trends-enterprise/",
                date: Date().addingTimeInterval(-4 * 24 * 60 * 60), // 4 days ago
                source: "techrepublic.com"
            ),
            NewsArticle(
                title: "Top 3% of Companies & Enterprise AI",
                summary: "What successful AI adopters do differently to drive real business transformation.",
                url: "https://allwork.space/2026/01/5-things-the-top-3-of-companies-get-right-about-enterprise-ai/",
                date: Date().addingTimeInterval(-6 * 24 * 60 * 60), // 6 days ago
                source: "allwork.space"
            ),
            NewsArticle(
                title: "FigJam AI Features",
                summary: "AI templates, sticky sorting, and automatic action items transform whiteboard collaboration.",
                url: "https://www.figma.com/figjam/",
                date: Date().addingTimeInterval(-14 * 24 * 60 * 60), // 2 weeks ago
                source: "figma.com"
            ),
            NewsArticle(
                title: "Infosys + AWS AI Partnership",
                summary: "Accelerating enterprise generative AI adoption through strategic cloud collaboration.",
                url: "https://www.infosys.com/newsroom/press-releases/2026/accelerate-enterprise-adoption-generative-ai.html",
                date: Date().addingTimeInterval(-8 * 24 * 60 * 60), // 8 days ago
                source: "infosys.com"
            )
        ]
    }
}

// MARK: - Section Header

private struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.pulsyncCaption)
            .fontWeight(.semibold)
            .foregroundStyle(PulsyncTheme.textMuted)
            .tracking(1.5)
    }
}

// MARK: - News Article Card

private struct NewsArticleCard: View {
    let article: NewsArticle
    @State private var isHovered = false

    var body: some View {
        Button(action: openArticle) {
            VStack(alignment: .leading, spacing: PulsyncSpacing.sm) {
                // Title
                Text(article.title)
                    .font(.pulsyncLabel)
                    .fontWeight(.semibold)
                    .foregroundStyle(PulsyncTheme.textPrimary)
                    .lineLimit(2)

                // Summary
                Text(article.summary)
                    .font(.pulsyncCaption)
                    .foregroundStyle(PulsyncTheme.textSecondary)
                    .lineLimit(3)

                // Source + Date
                HStack(spacing: PulsyncSpacing.xs) {
                    Text(article.source)
                        .foregroundStyle(PulsyncTheme.textMuted)

                    Text("·")
                        .foregroundStyle(PulsyncTheme.textMuted)

                    Text(relativeDate(article.date))
                        .foregroundStyle(PulsyncTheme.textMuted)
                }
                .font(.pulsyncMicro)
            }
            .padding(PulsyncSpacing.ms)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: PulsyncRadius.md)
                    .fill(isHovered ? PulsyncTheme.surfaceElevated : PulsyncTheme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: PulsyncRadius.md)
                    .strokeBorder(
                        isHovered ? PulsyncTheme.borderStrong : Color.clear,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(DesignSystem.Animation.quick) {
                isHovered = hovering
            }
        }
    }

    private func openArticle() {
        guard let url = URL(string: article.url) else { return }
        NSWorkspace.shared.open(url)
    }

    private func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Preview

#Preview {
    DiscoverFeedView()
        .frame(width: 600, height: 800)
}
