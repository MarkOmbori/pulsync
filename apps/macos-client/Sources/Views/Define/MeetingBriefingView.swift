import SwiftUI

struct MeetingBriefingView: View {
    let outcome: Outcome
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main row
            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() } }) {
                HStack(spacing: 12) {
                    // Calendar icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 40, height: 40)

                        Image(systemName: "calendar")
                            .font(.system(size: 18))
                            .foregroundStyle(.blue)
                    }

                    // Content
                    VStack(alignment: .leading, spacing: 4) {
                        Text(outcome.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)

                        if let meetingTime = outcome.meetingTime {
                            Text(meetingTime.formatted(date: .omitted, time: .shortened))
                                .font(.system(size: 13))
                                .foregroundStyle(.blue)
                        }
                    }

                    Spacer()

                    // Participant count
                    if let participants = outcome.meetingParticipants {
                        HStack(spacing: 4) {
                            Image(systemName: "person.2")
                                .font(.system(size: 12))
                            Text("\(participants.count)")
                                .font(.system(size: 12))
                        }
                        .foregroundStyle(.gray)
                    }

                    // Expand indicator
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.gray)
                }
                .padding(12)
            }
            .buttonStyle(.plain)

            // Expanded content
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                        .background(Color.white.opacity(0.1))

                    // Description
                    if let description = outcome.description {
                        Text(description)
                            .font(.system(size: 13))
                            .foregroundStyle(.gray)
                    }

                    // Participants
                    if let participants = outcome.meetingParticipants, !participants.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "person.2")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.gray)
                                Text("Participants")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(.gray)
                            }

                            HStack(spacing: 8) {
                                ForEach(participants, id: \.self) { participant in
                                    Text(participant)
                                        .font(.system(size: 12))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color.white.opacity(0.1))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }

                    // Agenda
                    if let agenda = outcome.meetingAgenda {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "list.bullet")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.gray)
                                Text("Agenda")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(.gray)
                            }

                            Text(agenda)
                                .font(.system(size: 13))
                                .foregroundStyle(.white.opacity(0.8))
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.white.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }

                    // Quick actions
                    HStack(spacing: 12) {
                        quickActionButton(icon: "video", label: "Join")
                        quickActionButton(icon: "doc.text", label: "Notes")
                        quickActionButton(icon: "bell", label: "Remind")
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
        }
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func quickActionButton(icon: String, label: String) -> some View {
        Button(action: {}) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(label)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundStyle(.blue)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.blue.opacity(0.15))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
