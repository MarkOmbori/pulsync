import SwiftUI

/// Container that constrains content to a specific device preview size
struct DevicePreviewContainer<Content: View>: View {
    @Environment(\.layoutEnvironment) private var layout
    let content: Content
    var showFrame: Bool = true
    var showSizeLabel: Bool = true

    init(showFrame: Bool = true, showSizeLabel: Bool = true, @ViewBuilder content: () -> Content) {
        self.showFrame = showFrame
        self.showSizeLabel = showSizeLabel
        self.content = content()
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background (workspace)
                Color(nsColor: .windowBackgroundColor)
                    .ignoresSafeArea()

                if layout.isConstrained {
                    // Constrained preview mode
                    VStack(spacing: 12) {
                        // Device frame
                        previewFrame(in: geometry)

                        // Size label
                        if showSizeLabel {
                            SizeIndicatorBadge(size: layout.effectiveSize)
                        }
                    }
                } else {
                    // Full window mode - content fills entire space
                    content
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
    }

    @ViewBuilder
    private func previewFrame(in geometry: GeometryProxy) -> some View {
        let previewSize = constrainedSize(for: geometry.size)

        ZStack {
            if showFrame {
                // Device bezel
                RoundedRectangle(cornerRadius: deviceCornerRadius)
                    .fill(Color.black)
                    .frame(width: previewSize.width + bezelWidth * 2,
                           height: previewSize.height + bezelWidth * 2)
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            }

            // Content area
            content
                .frame(width: previewSize.width, height: previewSize.height)
                .clipShape(RoundedRectangle(cornerRadius: contentCornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: contentCornerRadius)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        }
    }

    // MARK: - Size Calculations

    private func constrainedSize(for containerSize: CGSize) -> CGSize {
        let targetSize = layout.effectiveSize

        // Calculate scale to fit within container with padding
        let padding: CGFloat = 60
        let availableWidth = containerSize.width - padding * 2
        let availableHeight = containerSize.height - padding * 2 - 40 // Extra for label

        let scaleX = availableWidth / targetSize.width
        let scaleY = availableHeight / targetSize.height
        let scale = min(scaleX, scaleY, 1.0) // Don't scale up

        return CGSize(
            width: targetSize.width * scale,
            height: targetSize.height * scale
        )
    }

    // MARK: - Device Frame Properties

    private var deviceCornerRadius: CGFloat {
        switch layout.currentPreviewSize {
        case .iPhoneSE:
            return 30
        case .iPhone14Pro, .iPhone15ProMax:
            return 47
        case .iPadMini, .iPadPro11:
            return 20
        default:
            return 12
        }
    }

    private var contentCornerRadius: CGFloat {
        switch layout.currentPreviewSize {
        case .iPhoneSE:
            return 0 // SE has flat screen edges
        case .iPhone14Pro, .iPhone15ProMax:
            return 44
        case .iPadMini, .iPadPro11:
            return 18
        default:
            return 8
        }
    }

    private var bezelWidth: CGFloat {
        switch layout.currentPreviewSize {
        case .iPhoneSE, .iPhone14Pro, .iPhone15ProMax:
            return 8
        case .iPadMini, .iPadPro11:
            return 12
        default:
            return 4
        }
    }
}

// MARK: - Preview With Device Frame Modifier

extension View {
    /// Wrap content in device preview container
    func devicePreview(showFrame: Bool = true, showSizeLabel: Bool = true) -> some View {
        DevicePreviewContainer(showFrame: showFrame, showSizeLabel: showSizeLabel) {
            self
        }
    }
}

// MARK: - Device Frame Overlay (Standalone)

struct DeviceFrameOverlay: View {
    let size: DevicePreviewSize
    var color: Color = .black

    var body: some View {
        GeometryReader { geometry in
            if shouldShowNotch {
                // iPhone notch/Dynamic Island
                notchOverlay(in: geometry)
            }
        }
    }

    private var shouldShowNotch: Bool {
        switch size {
        case .iPhone14Pro, .iPhone15ProMax:
            return true
        default:
            return false
        }
    }

    @ViewBuilder
    private func notchOverlay(in geometry: GeometryProxy) -> some View {
        VStack {
            // Dynamic Island
            Capsule()
                .fill(color)
                .frame(width: 126, height: 36)
                .padding(.top, 12)

            Spacer()

            // Home indicator
            Capsule()
                .fill(Color.white.opacity(0.3))
                .frame(width: 134, height: 5)
                .padding(.bottom, 8)
        }
    }
}

// MARK: - Preview

#Preview {
    DevicePreviewContainer {
        Color.blue
            .overlay {
                Text("Content")
                    .foregroundStyle(.white)
            }
    }
    .environment(\.layoutEnvironment, {
        let env = LayoutEnvironment()
        env.currentPreviewSize = .iPhone14Pro
        return env
    }())
}
