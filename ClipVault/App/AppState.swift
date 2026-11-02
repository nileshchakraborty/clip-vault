import AppKit
import SwiftUI
import Combine

@MainActor
public final class AppState: ObservableObject {
    public static let shared = AppState()

    // MARK: - Published Properties
    @Published public var recentItems: [ClipboardItem] = []
    @Published public var pinnedItems: [ClipboardItem] = []
    @Published public var searchText: String = "" {
        didSet {
            monitor.resetToActivePolling()
        }
    }
    @Published public var selectedFilter: ContentType? = nil
    @Published public var toastMessage: String? = nil
    @Published public var showSettingsWindow: Bool = false

    // MARK: - Dependencies
    public let settings = SettingsManager.shared
    private let monitor = PasteboardMonitor()
    private var cancellables = Set<AnyCancellable>()
    private var memoryPressureSource: DispatchSourceMemoryPressure?

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
        setupMemoryPressureHandler()
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

    // MARK: - Memory Pressure Resilience
    private func setupMemoryPressureHandler() {
        let source = DispatchSource.makeMemoryPressureSource(eventMask: [.warning, .critical], queue: .main)
        source.setEventHandler { [weak self] in
            guard let self = self else { return }
            let event = source.data
            if event.contains(.critical) {
                // Critical system pressure: trim recent items down to 5 and shed heavy buffers
                if self.recentItems.count > 5 {
                    self.recentItems = Array(self.recentItems.prefix(5))
                }
                self.enforceTieredImageRetention(keepFullCount: 1)
            } else if event.contains(.warning) {
                // Warning pressure: keep full buffers for only top 2 images
                self.enforceTieredImageRetention(keepFullCount: 2)
            }
        }
        source.resume()
        self.memoryPressureSource = source
    }

    // MARK: - Clipboard Ingestion
    public func handleNewClipboardItem(_ item: ClipboardItem) {
        if pinnedItems.contains(where: { isContentEqual($0.content, item.content) }) {
            return
        }

        recentItems.removeAll(where: { isContentEqual($0.content, item.content) })
        recentItems.insert(item, at: 0)

        enforceHistoryLimit(settings.maxHistoryLimit)
        enforceTieredImageRetention(keepFullCount: 3)
    }

    private func isContentEqual(_ a: ClipboardContent, _ b: ClipboardContent) -> Bool {
        if a.type != b.type { return false }
        switch a.type {
        case .text, .color, .url:
            return a.textValue == b.textValue
        case .richText:
            return a.textValue == b.textValue
        case .image:
            return a.imageData == b.imageData || (a.thumbnailData != nil && a.thumbnailData == b.thumbnailData)
        }
    }

    private func enforceHistoryLimit(_ limit: Int) {
        let effectiveLimit = min(max(SettingsManager.minAllowedLimit, limit), SettingsManager.maxAllowedLimit)
        if recentItems.count > effectiveLimit {
            recentItems = Array(recentItems.prefix(effectiveLimit))
        }
    }

    // Retain heavy raw image data for top 3 items only; older items retain micro-thumbnails (~3KB)
    private func enforceTieredImageRetention(keepFullCount: Int) {
        var imageCount = 0
        for i in 0..<recentItems.count {
            if recentItems[i].content.type == .image {
                imageCount += 1
                if imageCount > keepFullCount {
                    if recentItems[i].content.imageData != nil {
                        var updatedContent = recentItems[i].content
                        updatedContent.evictRawImageData()
                        recentItems[i] = ClipboardItem(
                            id: recentItems[i].id,
                            createdAt: recentItems[i].createdAt,
                            content: updatedContent,
                            isPinned: recentItems[i].isPinned
                        )
                    }
                }
            }
        }
    }

    // MARK: - Actions
    public func togglePin(for item: ClipboardItem) {
        if let index = pinnedItems.firstIndex(where: { $0.id == item.id }) {
            var unpinned = pinnedItems.remove(at: index)
            unpinned.isPinned = false
            recentItems.insert(unpinned, at: 0)
            enforceHistoryLimit(settings.maxHistoryLimit)
            showToast("Unpinned item")
        } else if let index = recentItems.firstIndex(where: { $0.id == item.id }) {
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
            if let data = item.content.imageData ?? item.content.thumbnailData {
                pb.setData(data, forType: .png)
            }
        }

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
        guard !trimmedQuery.isEmpty || selectedFilter != nil else {
            return list
        }
        return list.filter { item in
            if let selectedFilter = selectedFilter, item.content.type != selectedFilter {
                return false
            }
            if !trimmedQuery.isEmpty {
                return item.searchIndex.contains(trimmedQuery)
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
