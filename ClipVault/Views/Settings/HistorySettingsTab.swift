import SwiftUI

public struct HistorySettingsTab: View {
    @ObservedObject var settings: SettingsManager
    @EnvironmentObject var appState: AppState

    @State private var customValue: Int = 15

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // SECTION 1: HISTORY CAPACITY (LAST N)
                VStack(alignment: .leading, spacing: 8) {
                    Text("History Capacity (Last N Items)")
                        .font(.system(size: 13, weight: .bold))

                    Text("Configure how many recent clipboard items ClipVault holds in memory. The maximum allowed limit is 50.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    // Presets
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Presets:")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 8), spacing: 6) {
                            ForEach(SettingsManager.presetLimits, id: \.self) { preset in
                                Button(action: {
                                    settings.maxHistoryLimit = preset
                                    customValue = preset
                                }) {
                                    Text("\(preset)")
                                        .font(.system(size: 11, weight: settings.maxHistoryLimit == preset ? .bold : .regular))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 5)
                                        .background(settings.maxHistoryLimit == preset ? Color.accentColor : Color.secondary.opacity(0.12))
                                        .foregroundColor(settings.maxHistoryLimit == preset ? .white : .primary)
                                        .cornerRadius(6)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.top, 4)

                    // Custom Stepper
                    HStack(spacing: 12) {
                        Text("Custom Limit:")
                            .font(.system(size: 12))

                        Stepper(value: $settings.maxHistoryLimit, in: SettingsManager.minAllowedLimit...SettingsManager.maxAllowedLimit) {
                            Text("\(settings.maxHistoryLimit) items")
                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        }
                        .frame(width: 150)

                        Text("(Min 1, Max 50)")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)

                    // Warning Banner when N > 25
                    if settings.isHighLimitWarningActive {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.system(size: 14))

                            VStack(alignment: .leading, spacing: 2) {
                                Text("High Capacity Warning")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.orange)

                                Text(settings.warningMessage)
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(10)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.top, 4)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)

                // SECTION 2: LIFECYCLE & PERSISTENCE
                VStack(alignment: .leading, spacing: 12) {
                    Text("Session Lifecycle & Storage")
                        .font(.system(size: 13, weight: .bold))

                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Persist Pinned items across app restarts", isOn: $settings.persistPinnedItems)
                            .font(.system(size: 12))

                        Text("By default, all clipboard items (both history and pinned) are held strictly in RAM and discarded on quit or restart. Enabling this preserves your Pin Board locally while keeping recent history RAM-only.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .padding(.leading, 20)
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Play sound feedback when copying clips", isOn: $settings.soundEffectsEnabled)
                            .font(.system(size: 12))
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)

                // SECTION 3: DANGER ZONE / PURGE
                VStack(alignment: .leading, spacing: 8) {
                    Text("Manual Memory Purge")
                        .font(.system(size: 13, weight: .bold))

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Purge all in-memory clipboard items immediately")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Button("Clear All Items") {
                            appState.clearAll(includingPinned: true)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .controlSize(.small)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)
            }
            .padding(16)
        }
    }
}
