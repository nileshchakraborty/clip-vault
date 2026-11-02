import AppKit
import SwiftUI
import Combine

public final class AppState: ObservableObject {
    public static let shared = AppState()

    // MARK: - Published Properties
    @Published public var recentItems: [ClipboardItem] = []
    @Published public var pinnedItems: [ClipboardItem] = []
    @Published public var searchText: String = ""
    @Published public var selectedFilter: ContentType? = nil
    @Published public var toastMessage: String? = nil
    @Published public var showSettingsWindow: Bool = false

    // MARK: - Dependencies
    public let settings = SettingsManager.shared
    private let monitor = PasteboardMonitor()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - File URLs for Opt-in Pinned Persistence
    private var pinnedStorageURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("com.clipvault.mac", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("pinned_items.json")
    }

    // MARK: - Initialization
    public init() {
        setupMonitor()
        setupSettingsObserver()
        loadPersistedPinnedItemsIfNeeded()
    }

    private func setupMonitor() {
        monitor.onItemDetected = { [weak self] item in
            DispatchQueue.main.async {
                self?.handleNewClipboardItem(item)
            }
        }
        monitor.startMonitoring()
    }

    private func setupSettingsObserver() {
        settings.$maxHistoryLimit
            .sink { [weak self] newLimit in
                self?.enforceHistoryLimit(newLimit)
            }
            .store(in: &cancellables)

        settings.$persistPinnedItems
            .sink { [weak self] persist in
                guard let self = self else { return }
                if persist {
                    self.savePinnedItems()
                } else {
                    self.deletePersistedPinnedItemsFile()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Clipboard Ingestion
    public func handleNewClipboardItem(_ item: ClipboardItem) {
        // If already in pinned items, do not duplicate into recent items
        if pinnedItems.contains(where: { isContentEqual($0.content, item.content) }) {
            return
        }

        // Remove any existing duplicate in recent items so it bumps to the top
        recentItems.removeAll(where: { isContentEqual($0.content, item.content) })

        // Insert at the beginning
        recentItems.insert(item, at: 0)

        // Enforce max limit
        enforceHistoryLimit(settings.maxHistoryLimit)
    }

    private func isContentEqual(_ a: ClipboardContent, _ b: ClipboardContent) -> Bool {
        if a.type != b.type { return false }
        switch a.type {
        case .text, .color, .url:
            return a.textValue == b.textValue
        case .richText:
            return a.textValue == b.textValue
        case .image:
            return a.imageData == b.imageData
        }
    }

    private func enforceHistoryLimit(_ limit: Int) {
        let effectiveLimit = min(max(SettingsManager.minAllowedLimit, limit), SettingsManager.maxAllowedLimit)
        if recentItems.count > effectiveLimit {
            recentItems = Array(recentItems.prefix(effectiveLimit))
        }
    }

    // MARK: - Actions
    public func togglePin(for item: ClipboardItem) {
        if let index = pinnedItems.firstIndex(where: { $0.id == item.id }) {
            // Unpin: remove from pinned and put at top of recent
            var unpinned = pinnedItems.remove(at: index)
            unpinned.isPinned = false
            recentItems.insert(unpinned, at: 0)
            enforceHistoryLimit(settings.maxHistoryLimit)
            showToast("Unpinned item")
        } else if let index = recentItems.firstIndex(where: { $0.id == item.id }) {
            // Pin: remove from recent and add to pinned
            var pinned = recentItems.remove(at: index)
            pinned.isPinned = true
            pinnedItems.insert(pinned, at: 0)
            showToast("Pinned to Pin Board")
        }

        if settings.persistPinnedItems {
            savePinnedItems()
        }
    }

    public func deleteItem(_ item: ClipboardItem) {
        recentItems.removeAll(where: { $0.id == item.id })
        let wasPinned = pinnedItems.contains(where: { $0.id == item.id })
        pinnedItems.removeAll(where: { $0.id == item.id })

        if wasPinned && settings.persistPinnedItems {
            savePinnedItems()
        }
        showToast("Item deleted")
    }

    public func clearRecentHistory() {
        recentItems.removeAll()
        showToast("Recent history cleared")
    }

    public func clearAll(includingPinned: Bool = true) {
        recentItems.removeAll()
        if includingPinned {
            pinnedItems.removeAll()
            deletePersistedPinnedItemsFile()
            showToast("All items cleared")
        } else {
            showToast("Recent history cleared (Pinned preserved)")
        }
    }

    public func copyToPasteboard(_ item: ClipboardItem) {
        let pb = NSPasteboard.general
        pb.clearContents()

        switch item.content.type {
        case .text, .url, .color:
            if let text = item.content.textValue {
                pb.setString(text, forType: .string)
            }
        case .richText:
            if let rtf = item.content.rtfData {
                pb.setData(rtf, forType: .rtf)
            }
            if let text = item.content.textValue {
                pb.setString(text, forType: .string)
            }
        case .image:
            if let data = item.content.imageData {
                pb.setData(data, forType: .png)
            }
        }

        // Notify monitor to ignore this changeCount
        monitor.notifyInternalCopy()

        if settings.soundEffectsEnabled {
            NSSound(named: "Tink")?.play()
        }

        showToast("Copied to clipboard!")
    }

    public func showToast(_ message: String) {
        toastMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { [weak self] in
            if self?.toastMessage == message {
                self?.toastMessage = nil
            }
        }
    }

    // MARK: - Filtered Views
    public var filteredPinnedItems: [ClipboardItem] {
        filterItems(pinnedItems)
    }

    public var filteredRecentItems: [ClipboardItem] {
        filterItems(recentItems)
    }

    private func filterItems(_ list: [ClipboardItem]) -> [ClipboardItem] {
        let trimmedQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return list.filter { item in
            // Filter by type if selected
            if let selectedFilter = selectedFilter, item.content.type != selectedFilter {
                return false
            }
            // Filter by query
            if !trimmedQuery.isEmpty {
                return item.searchString.contains(trimmedQuery) || item.previewText.lowercased().contains(trimmedQuery)
            }
            return true
        }
    }

    // MARK: - Persistence for Pinned Items (Opt-In)
    private func loadPersistedPinnedItemsIfNeeded() {
        guard settings.persistPinnedItems else { return }
        guard FileManager.default.fileExists(atPath: pinnedStorageURL.path) else { return }
        do {
            let data = try Data(contentsOf: pinnedStorageURL)
            let items = try JSONDecoder().decode([ClipboardItem].self, from: data)
            self.pinnedItems = items
        } catch {
            print("[ClipVault] Failed to load persisted pinned items: \(error)")
        }
    }

    private func savePinnedItems() {
        guard settings.persistPinnedItems else { return }
        do {
            let data = try JSONEncoder().encode(pinnedItems)
            try data.write(to: pinnedStorageURL, options: .atomic)
        } catch {
            print("[ClipVault] Failed to save pinned items: \(error)")
        }
    }

    private func deletePersistedPinnedItemsFile() {
        try? FileManager.default.removeItem(at: pinnedStorageURL)
    }
}
