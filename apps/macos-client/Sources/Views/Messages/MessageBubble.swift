import SwiftUI

struct MessageBubble: View {
    let message: Message
    let isFromCurrentUser: Bool

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isFromCurrentUser {
                Spacer(minLength: 60)
            } else {
                // Avatar for other user
                avatarView
            }

            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                if !isFromCurrentUser {
                    Text(message.sender.displayName)
                        .font(.caption2)
                        .foregroundStyle(.gray)
                }

                Text(message.body)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(isFromCurrentUser ? Color.electricViolet : PulsyncTheme.surface)
                    .foregroundStyle(.white)
                    .cornerRadius(16, corners: isFromCurrentUser
                        ? [.topLeft, .topRight, .bottomLeft]
                        : [.topLeft, .topRight, .bottomRight])

                Text(message.createdAt, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.gray)
            }

            if !isFromCurrentUser {
                Spacer(minLength: 60)
            }
        }
    }

    private var avatarView: some View {
        ZStack {
            Circle()
                .fill(Color.electricViolet.opacity(0.3))

            Text(String(message.sender.displayName.prefix(1)).uppercased())
                .font(.caption2.bold())
                .foregroundStyle(Color.electricViolet)
        }
        .frame(width: 28, height: 28)
    }
}

// Custom corner radius extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = NSBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

extension NSBezierPath {
    convenience init(roundedRect rect: CGRect, byRoundingCorners corners: UIRectCorner, cornerRadii: CGSize) {
        self.init()

        let topLeft = corners.contains(.topLeft)
        let topRight = corners.contains(.topRight)
        let bottomLeft = corners.contains(.bottomLeft)
        let bottomRight = corners.contains(.bottomRight)

        let minX = rect.minX
        let minY = rect.minY
        let maxX = rect.maxX
        let maxY = rect.maxY

        let radius = cornerRadii.width

        // Start at top-left
        move(to: CGPoint(x: minX + (topLeft ? radius : 0), y: minY))

        // Top edge and top-right corner
        line(to: CGPoint(x: maxX - (topRight ? radius : 0), y: minY))
        if topRight {
            curve(to: CGPoint(x: maxX, y: minY + radius),
                  controlPoint1: CGPoint(x: maxX, y: minY),
                  controlPoint2: CGPoint(x: maxX, y: minY + radius))
        }

        // Right edge and bottom-right corner
        line(to: CGPoint(x: maxX, y: maxY - (bottomRight ? radius : 0)))
        if bottomRight {
            curve(to: CGPoint(x: maxX - radius, y: maxY),
                  controlPoint1: CGPoint(x: maxX, y: maxY),
                  controlPoint2: CGPoint(x: maxX - radius, y: maxY))
        }

        // Bottom edge and bottom-left corner
        line(to: CGPoint(x: minX + (bottomLeft ? radius : 0), y: maxY))
        if bottomLeft {
            curve(to: CGPoint(x: minX, y: maxY - radius),
                  controlPoint1: CGPoint(x: minX, y: maxY),
                  controlPoint2: CGPoint(x: minX, y: maxY - radius))
        }

        // Left edge and top-left corner
        line(to: CGPoint(x: minX, y: minY + (topLeft ? radius : 0)))
        if topLeft {
            curve(to: CGPoint(x: minX + radius, y: minY),
                  controlPoint1: CGPoint(x: minX, y: minY),
                  controlPoint2: CGPoint(x: minX + radius, y: minY))
        }

        close()
    }

    var cgPath: CGPath {
        let path = CGMutablePath()
        var points = [CGPoint](repeating: .zero, count: 3)

        for i in 0..<elementCount {
            let type = element(at: i, associatedPoints: &points)
            switch type {
            case .moveTo:
                path.move(to: points[0])
            case .lineTo:
                path.addLine(to: points[0])
            case .curveTo:
                path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .closePath:
                path.closeSubpath()
            @unknown default:
                break
            }
        }

        return path
    }
}

// UIRectCorner equivalent for macOS
struct UIRectCorner: OptionSet {
    let rawValue: Int

    static let topLeft = UIRectCorner(rawValue: 1 << 0)
    static let topRight = UIRectCorner(rawValue: 1 << 1)
    static let bottomLeft = UIRectCorner(rawValue: 1 << 2)
    static let bottomRight = UIRectCorner(rawValue: 1 << 3)
    static let allCorners: UIRectCorner = [.topLeft, .topRight, .bottomLeft, .bottomRight]
}
