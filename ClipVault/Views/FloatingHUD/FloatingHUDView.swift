import SwiftUI

public struct FloatingHUDView: View {
    @EnvironmentObject private var appState: AppState
    let onClose: () -> Void

    public var body: some View {
        VStack(spacing: 0) {
            // Header Search Input
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 15))

                TextField("Type to search clips...", text: $appState.searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))

                Button(action: onClose) {
                    Text("esc")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.15))
                        .cornerRadius(4)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.8))

            Divider()

            // List of clips
            let pinned = appState.filteredPinnedItems
            let recent = appState.filteredRecentItems

            if pinned.isEmpty && recent.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("No clips found")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        if !pinned.isEmpty {
                            hudSectionHeader("PIN BOARD (\(pinned.count))", icon: "pin.fill", color: .orange)
                            ForEach(pinned) { item in
                                ClipRowView(
                                    item: item,
                                    shortcutIndex: nil,
                                    searchQuery: appState.searchText,
                                    onCopy: {
                                        appState.copyToPasteboard(item)
                                        onClose()
                                    },
                                    onTogglePin: { appState.togglePin(for: item) },
                                    onDelete: { appState.deleteItem(item) }
                                )
                            }
                            Divider().padding(.vertical, 4)
                        }

                        if !recent.isEmpty {
                            hudSectionHeader("RECENT HISTORY (\(recent.count)/\(appState.settings.maxHistoryLimit))", icon: "clock", color: .secondary)
                            ForEach(Array(recent.enumerated()), id: \.element.id) { index, item in
                                ClipRowView(
                                    item: item,
                                    shortcutIndex: index + 1,
                                    searchQuery: appState.searchText,
                                    onCopy: {
                                        appState.copyToPasteboard(item)
                                        onClose()
                                    },
                                    onTogglePin: { appState.togglePin(for: item) },
                                    onDelete: { appState.deleteItem(item) }
                                )
                            }
                        }
                    }
                    .padding(8)
                }
            }

            Divider()

            // Footer
            HStack {
                Text("Press Return to copy • Esc to dismiss")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Spacer()
                Text("Cap: \(appState.settings.maxHistoryLimit)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
        }
        .frame(width: 440, height: 480)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.25), radius: 20, x: 0, y: 10)
    }

    private func hudSectionHeader(_ text: String, icon: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9))
                .foregroundColor(color)
            Text(text)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.top, 4)
    }
}
