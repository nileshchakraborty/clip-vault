import SwiftUI

public struct ShortcutsSettingsTab: View {
    @ObservedObject var settings: SettingsManager

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Floating HUD Window")
                        .font(.system(size: 13, weight: .bold))

                    Text("ClipVault can display an ultra-fast Spotlight-style floating palette over any fullscreen app or desktop space.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    Toggle("Enable Global Hotkey (⌘ + Shift + V)", isOn: $settings.enableGlobalHotKey)
                        .font(.system(size: 12))
                        .onChange(of: settings.enableGlobalHotKey) { enabled in
                            if enabled {
                                HotKeyManager.shared.registerDefaultHotKey()
                            } else {
                                HotKeyManager.shared.unregisterHotKey()
                            }
                        }

                    HStack(spacing: 8) {
                        Text("Current Shortcut:")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)

                        HStack(spacing: 3) {
                            keyCap("⌘")
                            keyCap("⇧")
                            keyCap("V")
                        }
                    }
                    .padding(.top, 4)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Quick Navigation Tips")
                        .font(.system(size: 13, weight: .bold))

                    shortcutTip(keys: ["⌘", "1...9"], description: "Directly copy any of the top 9 recent clips")
                    shortcutTip(keys: ["Return"], description: "Copy selected clip and dismiss HUD")
                    shortcutTip(keys: ["Esc"], description: "Dismiss Floating HUD")
                    shortcutTip(keys: ["Click row"], description: "Copy clip immediately to system pasteboard")
                    shortcutTip(keys: ["Right-click"], description: "Access Context Menu (Pin, Delete, Open URL)")
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)
            }
            .padding(16)
        }
    }

    private func keyCap(_ string: String) -> some View {
        Text(string)
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.secondary.opacity(0.18))
            .cornerRadius(4)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 0.5)
            )
    }

    private func shortcutTip(keys: [String], description: String) -> some View {
        HStack(spacing: 8) {
            HStack(spacing: 2) {
                ForEach(keys, id: \.self) { key in
                    keyCap(key)
                }
            }
            .frame(width: 80, alignment: .leading)

            Text(description)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
    }
}
