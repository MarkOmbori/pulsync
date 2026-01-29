import SwiftUI

/// Toolbar dropdown for switching device preview sizes
struct ScreenSizeSwitcher: View {
    @Environment(\.layoutEnvironment) private var layout

    var body: some View {
        Menu {
            // Device presets
            Section("Device Presets") {
                ForEach(DevicePreviewSize.allCases.filter { $0 != .custom }) { size in
                    Button(action: { selectSize(size) }) {
                        Label {
                            HStack {
                                Text(size.rawValue)
                                Spacer()
                                if size != .desktop {
                                    Text(sizeLabel(for: size))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        } icon: {
                            Image(systemName: size.icon)
                        }
                    }
                    .disabled(layout.currentPreviewSize == size)
                }
            }

            Divider()

            // Custom size option
            Section {
                Button(action: { selectSize(.custom) }) {
                    Label("Custom Size...", systemImage: "rectangle.dashed")
                }
            }

            Divider()

            // Immersive mode toggle
            Section {
                Toggle(isOn: Binding(
                    get: { layout.isImmersiveMode },
                    set: { layout.isImmersiveMode = $0 }
                )) {
                    Label("Immersive Mode", systemImage: "rectangle.expand.vertical")
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: layout.currentPreviewSize.icon)
                Text(currentSizeLabel)
                    .font(.caption)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.quaternary)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }

    private var currentSizeLabel: String {
        if layout.currentPreviewSize == .desktop {
            return "Full"
        } else if layout.currentPreviewSize == .custom {
            return "\(Int(layout.customSize.width))×\(Int(layout.customSize.height))"
        } else {
            return layout.currentPreviewSize.rawValue
        }
    }

    private func sizeLabel(for size: DevicePreviewSize) -> String {
        let dimensions = size.size
        return "\(Int(dimensions.width))×\(Int(dimensions.height))"
    }

    private func selectSize(_ size: DevicePreviewSize) {
        withAnimation(PulsyncAnimation.smooth) {
            layout.currentPreviewSize = size
        }
    }
}

// MARK: - Custom Size Popover

struct CustomSizePopover: View {
    @Environment(\.layoutEnvironment) private var layout
    @State private var width: String = ""
    @State private var height: String = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Custom Size")
                .font(.headline)

            HStack {
                VStack(alignment: .leading) {
                    Text("Width")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("Width", text: $width)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                }

                Text("×")
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading) {
                    Text("Height")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("Height", text: $height)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                }
            }

            // Quick presets
            HStack(spacing: 8) {
                ForEach(quickPresets, id: \.0) { preset in
                    Button(preset.0) {
                        width = "\(Int(preset.1.width))"
                        height = "\(Int(preset.1.height))"
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Apply") {
                    applyCustomSize()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValidSize)
            }
        }
        .padding()
        .frame(width: 280)
        .onAppear {
            width = "\(Int(layout.customSize.width))"
            height = "\(Int(layout.customSize.height))"
        }
    }

    private var quickPresets: [(String, CGSize)] {
        [
            ("Mobile", CGSize(width: 390, height: 844)),
            ("Tablet", CGSize(width: 768, height: 1024)),
            ("Square", CGSize(width: 500, height: 500))
        ]
    }

    private var isValidSize: Bool {
        guard let w = Int(width), let h = Int(height) else { return false }
        return w >= 200 && w <= 2000 && h >= 200 && h <= 2000
    }

    private func applyCustomSize() {
        guard let w = Int(width), let h = Int(height) else { return }
        layout.customSize = CGSize(width: w, height: h)
        layout.currentPreviewSize = .custom
        dismiss()
    }
}

// MARK: - Size Indicator Badge

struct SizeIndicatorBadge: View {
    let size: CGSize

    var body: some View {
        Text("\(Int(size.width)) × \(Int(size.height))")
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
    }
}

// MARK: - Preview

#Preview {
    VStack {
        ScreenSizeSwitcher()
    }
    .padding()
    .environment(\.layoutEnvironment, LayoutEnvironment())
}
