import SwiftUI

struct MarkdownView: View {
    let content: String
    let isStreaming: Bool

    init(content: String, isStreaming: Bool = false) {
        self.content = content
        self.isStreaming = isStreaming
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Parse and render markdown
            ForEach(Array(parseMarkdown().enumerated()), id: \.offset) { _, block in
                renderBlock(block)
            }

            // Streaming cursor
            if isStreaming {
                Rectangle()
                    .fill(Color.electricViolet)
                    .frame(width: 8, height: 16)
                    .opacity(0.8)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isStreaming)
            }
        }
    }

    private func parseMarkdown() -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        let lines = content.components(separatedBy: "\n")
        var codeBlock: [String] = []
        var inCodeBlock = false
        var codeLanguage = ""

        for line in lines {
            if line.hasPrefix("```") {
                if inCodeBlock {
                    // End code block
                    blocks.append(.code(language: codeLanguage, content: codeBlock.joined(separator: "\n")))
                    codeBlock = []
                    inCodeBlock = false
                    codeLanguage = ""
                } else {
                    // Start code block
                    inCodeBlock = true
                    codeLanguage = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                }
            } else if inCodeBlock {
                codeBlock.append(line)
            } else if line.hasPrefix("# ") {
                blocks.append(.heading(level: 1, text: String(line.dropFirst(2))))
            } else if line.hasPrefix("## ") {
                blocks.append(.heading(level: 2, text: String(line.dropFirst(3))))
            } else if line.hasPrefix("### ") {
                blocks.append(.heading(level: 3, text: String(line.dropFirst(4))))
            } else if line.hasPrefix("- ") || line.hasPrefix("* ") {
                blocks.append(.listItem(text: String(line.dropFirst(2))))
            } else if line.hasPrefix("> ") {
                blocks.append(.blockquote(text: String(line.dropFirst(2))))
            } else if !line.isEmpty {
                blocks.append(.paragraph(text: line))
            }
        }

        // Handle unclosed code block (streaming)
        if inCodeBlock && !codeBlock.isEmpty {
            blocks.append(.code(language: codeLanguage, content: codeBlock.joined(separator: "\n")))
        }

        return blocks
    }

    @ViewBuilder
    private func renderBlock(_ block: MarkdownBlock) -> some View {
        switch block {
        case .heading(let level, let text):
            Text(text)
                .font(level == 1 ? .title2.bold() : level == 2 ? .title3.bold() : .headline)
                .foregroundStyle(.white)

        case .paragraph(let text):
            Text(renderInlineMarkdown(text))
                .foregroundStyle(.white.opacity(0.9))

        case .code(let language, let content):
            CodeBlockView(language: language, content: content)

        case .listItem(let text):
            HStack(alignment: .top, spacing: 8) {
                Text("•")
                    .foregroundStyle(Color.electricViolet)
                Text(renderInlineMarkdown(text))
                    .foregroundStyle(.white.opacity(0.9))
            }

        case .blockquote(let text):
            HStack(spacing: 8) {
                Rectangle()
                    .fill(Color.electricViolet)
                    .frame(width: 3)
                Text(renderInlineMarkdown(text))
                    .foregroundStyle(.white.opacity(0.7))
                    .italic()
            }
            .padding(.leading, 8)
        }
    }

    private func renderInlineMarkdown(_ text: String) -> AttributedString {
        var result = AttributedString(text)

        // Bold: **text** or __text__
        if let boldRegex = try? Regex("\\*\\*(.+?)\\*\\*|__(.+?)__") {
            // Note: Full implementation would require proper regex replacement
            // This is simplified for demo purposes
        }

        // Inline code: `code`
        if let codeRegex = try? Regex("`(.+?)`") {
            // Note: Full implementation would require proper regex replacement
        }

        return result
    }
}

enum MarkdownBlock {
    case heading(level: Int, text: String)
    case paragraph(text: String)
    case code(language: String, content: String)
    case listItem(text: String)
    case blockquote(text: String)
}

struct CodeBlockView: View {
    let language: String
    let content: String

    @State private var isCopied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                if !language.isEmpty {
                    Text(language)
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                Spacer()
                Button(action: copyCode) {
                    HStack(spacing: 4) {
                        Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                        Text(isCopied ? "Copied" : "Copy")
                    }
                    .font(.caption)
                    .foregroundStyle(isCopied ? .green : .gray)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.3))

            // Code content
            ScrollView(.horizontal, showsIndicators: false) {
                Text(content)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.white)
                    .padding(12)
            }
        }
        .background(Color.black.opacity(0.5))
        .cornerRadius(8)
    }

    private func copyCode() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(content, forType: .string)
        isCopied = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isCopied = false
        }
    }
}
