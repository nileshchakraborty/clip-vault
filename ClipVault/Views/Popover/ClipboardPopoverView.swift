import SwiftUI

public struct ClipboardPopoverView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showingClearConfirmation: Bool = false
    @State private var clearOption: ClearOption = .recentOnly

    private enum ClearOption {
        case recentOnly
        case allIncludingPinned
    }

    public init() {}

    public var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header Bar
                headerView
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                // Search & Filter Bar
                SearchBarView(
                    text: $appState.searchText,
                    selectedFilter: $appState.selectedFilter
                )
                .padding(.horizontal, 14)
                .padding(.bottom, 10)

                Divider()

                // Content List
                contentList
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Divider()

                // Footer Bar
                footerView
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
            }

            // Toast Notification Overlay
            if let toast = appState.toastMessage {
                VStack {
                    Spacer()
                    ToastView(message: toast)
                        .padding(.bottom, 45)
                }
            }
        }
        .frame(width: 380, height: 520)
        .background(Color(NSColor.windowBackgroundColor))
        .alert(isPresented: $showingClearConfirmation) {
            switch clearOption {
            case .recentOnly:
                return Alert(
                    title: Text("Clear Recent History?"),
                    message: Text("This will discard all unpinned clipboard items from memory. Pinned items will remain intact."),
                    primaryButton: .destructive(Text("Clear History")) {
                        appState.clearRecentHistory()
                    },
                    secondaryButton: .cancel()
                )
            case .allIncludingPinned:
                return Alert(
                    title: Text("Clear All Clipboard Items?"),
                    message: Text("This will discard all clipboard items, including your pinned board. This action cannot be undone."),
                    primaryButton: .destructive(Text("Clear All")) {
                        appState.clearAll(includingPinned: true)
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }

    // MARK: - Header
    private var headerView: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "paperclip.circle.fill")
                    .foregroundColor(.accentColor)
                    .font(.system(size: 16))

                Text("ClipVault")
                    .font(.system(size: 14, weight: .bold))
            }

            Spacer()

            // Clear Menu Button
            Menu {
                Button("Clear Recent History (\(appState.recentItems.count))") {
                    clearOption = .recentOnly
                    showingClearConfirmation = true
                }
                .disabled(appState.recentItems.isEmpty)

                Button("Clear All (Including Pinned)") {
                    clearOption = .allIncludingPinned
                    showingClearConfirmation = true
                }
                .disabled(appState.recentItems.isEmpty && appState.pinnedItems.isEmpty)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .help("Clear clipboard items")

            // Settings Button
            Button(action: {
                SettingsWindowManager.shared.openSettings()
            }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("Settings & Preferences")
        }
    }

    // MARK: - Content List
    @ViewBuilder
    private var contentList: some View {
        let pinned = appState.filteredPinnedItems
        let recent = appState.filteredRecentItems
        let isSearching = !appState.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        if pinned.isEmpty && recent.isEmpty {
            emptyStateView
        } else if isSearching {
            // Dedicated SEARCH RESULTS View
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    searchHeader(count: pinned.count + recent.count, query: appState.searchText)

                    if !pinned.isEmpty {
                        sectionHeader(title: "PINNED MATCHES", count: pinned.count, icon: "pin.fill", color: .orange)

                        ForEach(pinned) { item in
                            ClipRowView(
                                item: item,
                                shortcutIndex: nil,
                                searchQuery: appState.searchText,
                                onCopy: { appState.copyToPasteboard(item) },
                                onTogglePin: { appState.togglePin(for: item) },
                                onDelete: { appState.deleteItem(item) }
                            )
                        }

                        Divider()
                            .padding(.vertical, 4)
                    }

                    if !recent.isEmpty {
                        sectionHeader(
                            title: "HISTORY MATCHES",
                            count: recent.count,
                            maxCount: appState.settings.maxHistoryLimit,
                            icon: "clock",
                            color: .secondary
                        )

                        ForEach(Array(recent.enumerated()), id: \.element.id) { index, item in
                            ClipRowView(
                                item: item,
                                shortcutIndex: index + 1,
                                searchQuery: appState.searchText,
                                onCopy: { appState.copyToPasteboard(item) },
                                onTogglePin: { appState.togglePin(for: item) },
                                onDelete: { appState.deleteItem(item) }
                            )
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
            }
        } else {
            // Standard dual section view (Pin Board + Recent History)
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    // PIN BOARD SECTION
                    if !pinned.isEmpty {
                        sectionHeader(title: "PIN BOARD", count: pinned.count, icon: "pin.fill", color: .orange)

                        ForEach(Array(pinned.enumerated()), id: \.element.id) { index, item in
                            ClipRowView(
                                item: item,
                                shortcutIndex: nil,
                                searchQuery: "",
                                onCopy: { appState.copyToPasteboard(item) },
                                onTogglePin: { appState.togglePin(for: item) },
                                onDelete: { appState.deleteItem(item) }
                            )
                        }

                        Divider()
                            .padding(.vertical, 6)
                    }

                    // RECENT HISTORY SECTION
                    if !recent.isEmpty {
                        sectionHeader(
                            title: "RECENT HISTORY",
                            count: recent.count,
                            maxCount: appState.settings.maxHistoryLimit,
                            icon: "clock",
                            color: .secondary
                        )

                        ForEach(Array(recent.enumerated()), id: \.element.id) { index, item in
                            ClipRowView(
                                item: item,
                                shortcutIndex: index + 1,
                                searchQuery: "",
                                onCopy: { appState.copyToPasteboard(item) },
                                onTogglePin: { appState.togglePin(for: item) },
                                onDelete: { appState.deleteItem(item) }
                            )
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
            }
        }
    }

    private func searchHeader(count: Int, query: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.accentColor)

            Text("SEARCH RESULTS FOR \"\(query)\"")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.accentColor)
                .lineLimit(1)

            Spacer()

            Text("\(count) match\(count == 1 ? "" : "es")")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(.secondary)

            Button(action: { appState.searchText = "" }) {
                Text("Clear")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.accentColor)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.top, 4)
        .padding(.bottom, 6)
    }

    private func sectionHeader(title: String, count: Int, maxCount: Int? = nil, icon: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9))
                .foregroundColor(color)

            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.secondary)

            Spacer()

            if let max = maxCount {
                Text("\(count) / \(max)")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary.opacity(0.8))
            } else {
                Text("\(count)")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary.opacity(0.8))
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 4)
        .padding(.bottom, 2)
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 38))
                .foregroundColor(.secondary.opacity(0.5))

            if !appState.searchText.isEmpty {
                Text("No matching clips found")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                Text("Try searching for different keywords")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary.opacity(0.7))

                Button("Clear Search") {
                    appState.searchText = ""
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .padding(.top, 4)
            } else {
                Text("Clipboard is empty")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                Text("Copy text, links, colors, or images to see them here.\nAll items are stored strictly in RAM.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .padding(20)
    }

    // MARK: - Footer
    private var footerView: some View {
        HStack {
            Text("RAM-only storage • Cap: \(appState.settings.maxHistoryLimit)")
                .font(.system(size: 10))
                .foregroundColor(.secondary.opacity(0.8))

            Spacer()

            Button("Quit") {
                NSApp.terminate(nil)
            }
            .buttonStyle(.plain)
            .font(.system(size: 10))
            .foregroundColor(.secondary)
        }
    }
}
