import SwiftUI
import AppKit

@main
struct PulsyncApp: App {
    @State private var authState = AuthState.shared
    @State private var layoutEnvironment = LayoutEnvironment()

    init() {
        // Required for swift run to show GUI window
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(authState)
                .environment(\.layoutEnvironment, layoutEnvironment)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 900, height: 700)
        .commands {
            // Add keyboard shortcuts for preview sizes
            CommandGroup(after: .windowArrangement) {
                Menu("Preview Size") {
                    ForEach(DevicePreviewSize.allCases.filter { $0 != .custom }, id: \.self) { size in
                        Button(size.rawValue) {
                            layoutEnvironment.currentPreviewSize = size
                        }
                        .keyboardShortcut(keyboardShortcut(for: size), modifiers: [.command, .shift])
                    }

                    Divider()

                    Toggle("Immersive Mode", isOn: $layoutEnvironment.isImmersiveMode)
                        .keyboardShortcut("f", modifiers: [.command, .control])
                }
            }
        }
    }

    private func keyboardShortcut(for size: DevicePreviewSize) -> KeyEquivalent {
        switch size {
        case .iPhoneSE: return "1"
        case .iPhone14Pro: return "2"
        case .iPhone15ProMax: return "3"
        case .iPadMini: return "4"
        case .iPadPro11: return "5"
        case .desktop: return "0"
        case .custom: return "9"
        }
    }
}
