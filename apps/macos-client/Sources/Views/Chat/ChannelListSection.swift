import SwiftUI

struct ChannelListSection: View {
    @Binding var selectedChannel: Channel?
    @State private var isExpanded = true
    let onSelect: (Channel) -> Void

    private let channels = MockChatData.channels

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header
            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() } }) {
                HStack(spacing: PulsyncSpacing.xs) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(PulsyncTheme.textMuted)
                        .frame(width: 12)

                    Text("Channels")
                        .font(.pulsyncCaption)
                        .fontWeight(.semibold)
                        .foregroundStyle(PulsyncTheme.textMuted)
                        .textCase(.uppercase)

                    Spacer()

                    Image(systemName: "plus")
                        .font(.system(size: 12))
                        .foregroundStyle(PulsyncTheme.textMuted)
                }
                .padding(.horizontal, PulsyncSpacing.ms)
                .padding(.vertical, PulsyncSpacing.sm)
            }
            .buttonStyle(.plain)

            // Channel list
            if isExpanded {
                ForEach(channels) { channel in
                    ChannelRow(
                        channel: channel,
                        isSelected: selectedChannel?.id == channel.id,
                        onSelect: { onSelect(channel) }
                    )
                }
            }
        }
    }
}

struct ChannelRow: View {
    let channel: Channel
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: PulsyncSpacing.sm) {
                Text("#")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(isSelected ? PulsyncTheme.primary : PulsyncTheme.textMuted)

                Text(channel.name)
                    .font(.pulsyncBody)
                    .foregroundStyle(isSelected ? PulsyncTheme.textPrimary : PulsyncTheme.textSecondary)
                    .lineLimit(1)

                Spacer()

                if channel.unreadCount > 0 {
                    Text("\(channel.unreadCount)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(PulsyncTheme.primary)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, PulsyncSpacing.ms)
            .padding(.vertical, PulsyncSpacing.xs + 2)
            .background(
                RoundedRectangle(cornerRadius: PulsyncRadius.sm)
                    .fill(isSelected ? PulsyncTheme.primary.opacity(0.15) : Color.clear)
            )
            .padding(.horizontal, PulsyncSpacing.xs)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ChannelListSection(
        selectedChannel: .constant(MockChatData.channels.first),
        onSelect: { _ in }
    )
    .frame(width: 240)
    .background(PulsyncTheme.surface)
}
