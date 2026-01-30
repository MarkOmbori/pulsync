import SwiftUI

struct DMListSection: View {
    @Binding var selectedDM: DirectMessage?
    @State private var isExpanded = true
    let onSelect: (DirectMessage) -> Void

    private let directMessages = MockChatData.directMessages

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header
            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() } }) {
                HStack(spacing: PulsyncSpacing.xs) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(PulsyncTheme.textMuted)
                        .frame(width: 12)

                    Text("Direct Messages")
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

            // DM list
            if isExpanded {
                ForEach(directMessages) { dm in
                    DMRow(
                        dm: dm,
                        isSelected: selectedDM?.id == dm.id,
                        onSelect: { onSelect(dm) }
                    )
                }
            }
        }
    }
}

struct DMRow: View {
    let dm: DirectMessage
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: PulsyncSpacing.sm) {
                // Online indicator + Avatar
                ZStack(alignment: .bottomTrailing) {
                    UserAvatarView(user: dm.participant, size: 24)

                    Circle()
                        .fill(dm.participant.isOnline ? Color.green : Color.gray)
                        .frame(width: 8, height: 8)
                        .overlay(
                            Circle()
                                .stroke(PulsyncTheme.surface, lineWidth: 2)
                        )
                        .offset(x: 2, y: 2)
                }

                Text(dm.participant.displayName)
                    .font(.pulsyncBody)
                    .foregroundStyle(isSelected ? PulsyncTheme.textPrimary : PulsyncTheme.textSecondary)
                    .lineLimit(1)

                Spacer()

                if dm.unreadCount > 0 {
                    Text("\(dm.unreadCount)")
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

// MARK: - User Avatar View

struct UserAvatarView: View {
    let user: ChatUser
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: user.avatarColor))

            Text(user.initials)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    DMListSection(
        selectedDM: .constant(nil),
        onSelect: { _ in }
    )
    .frame(width: 240)
    .background(PulsyncTheme.surface)
}
