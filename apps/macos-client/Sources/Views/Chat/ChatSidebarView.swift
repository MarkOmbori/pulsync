import SwiftUI

struct ChatSidebarView: View {
    @Binding var selectedChannel: Channel?
    @Binding var selectedDM: DirectMessage?
    @Binding var searchText: String

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack(spacing: PulsyncSpacing.sm) {
                Image(systemName: PulsyncIcons.search)
                    .foregroundStyle(PulsyncTheme.textMuted)
                    .font(.system(size: 14))

                TextField("Search", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.pulsyncBody)
                    .foregroundStyle(PulsyncTheme.textPrimary)
            }
            .padding(.horizontal, PulsyncSpacing.ms)
            .padding(.vertical, PulsyncSpacing.sm)
            .background(PulsyncTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: PulsyncRadius.md))
            .padding(PulsyncSpacing.sm)

            // Channels section
            ChannelListSection(
                selectedChannel: $selectedChannel,
                onSelect: { channel in
                    selectedChannel = channel
                    selectedDM = nil
                }
            )

            // Direct Messages section
            DMListSection(
                selectedDM: $selectedDM,
                onSelect: { dm in
                    selectedDM = dm
                    selectedChannel = nil
                }
            )

            Spacer()
        }
        .background(PulsyncTheme.surface.opacity(0.5))
    }
}

#Preview {
    ChatSidebarView(
        selectedChannel: .constant(MockChatData.channels.first),
        selectedDM: .constant(nil),
        searchText: .constant("")
    )
    .frame(width: 240, height: 500)
}
