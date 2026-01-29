import SwiftUI

struct OutcomeItemView: View {
    let outcome: Outcome
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main row
            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() } }) {
                HStack(spacing: 12) {
                    // Status indicator
                    statusIcon
                        .frame(width: 24, height: 24)

                    // Content
                    VStack(alignment: .leading, spacing: 4) {
                        Text(outcome.title)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(outcome.status == .done ? .gray : .white)
                            .strikethrough(outcome.status == .done)

                        if let description = outcome.description {
                            Text(description)
                                .font(.system(size: 13))
                                .foregroundStyle(.gray)
                                .lineLimit(isExpanded ? nil : 1)
                        }
                    }

                    Spacer()

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

                    // Status section
                    HStack(spacing: 8) {
                        Text("Status:")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.gray)
                        statusBadge
                    }

                    // How to accomplish section
                    if let howTo = outcome.howToAccomplish {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "lightbulb")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.yellow)
                                Text("How to accomplish")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(.gray)
                            }

                            Text(howTo)
                                .font(.system(size: 13))
                                .foregroundStyle(.white.opacity(0.8))
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.white.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }

                    // Due date
                    if let dueDate = outcome.dueDate {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.system(size: 12))
                                .foregroundStyle(.gray)
                            Text("Due: \(dueDate.formatted(date: .abbreviated, time: .omitted))")
                                .font(.system(size: 13))
                                .foregroundStyle(.gray)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
        }
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch outcome.status {
        case .todo:
            Circle()
                .stroke(Color.gray, lineWidth: 2)
        case .inProgress:
            ZStack {
                Circle()
                    .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(Color.blue, lineWidth: 2)
                    .rotationEffect(.degrees(-90))
            }
        case .done:
            ZStack {
                Circle()
                    .fill(Color.green)
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
    }

    private var statusBadge: some View {
        Text(statusText)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(statusColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.15))
            .clipShape(Capsule())
    }

    private var statusText: String {
        switch outcome.status {
        case .todo: return "To Do"
        case .inProgress: return "In Progress"
        case .done: return "Done"
        }
    }

    private var statusColor: Color {
        switch outcome.status {
        case .todo: return .gray
        case .inProgress: return .blue
        case .done: return .green
        }
    }
}
