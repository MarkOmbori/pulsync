import SwiftUI

struct TextContentView: View {
    let item: ContentFeedItem

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            if let title = item.title {
                Text(title)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.white)
            }

            if let body = item.body {
                ScrollView {
                    Text(body)
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.9))
                        .lineSpacing(8)
                }
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
