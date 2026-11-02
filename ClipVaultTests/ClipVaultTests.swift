import XCTest
@testable import ClipVault

@MainActor
final class ClipVaultTests: XCTestCase {
    var appState: AppState!

    override func setUp() {
        super.setUp()
        appState = AppState()
        appState.clearAll(includingPinned: true)
    }

    override func tearDown() {
        appState.clearAll(includingPinned: true)
        appState = nil
        super.tearDown()
    }

    func testLimitClamping() {
        let settings = SettingsManager.shared

        // Test clamping to 50 when higher value set
        settings.maxHistoryLimit = 100
        XCTAssertEqual(settings.maxHistoryLimit, 50, "Limit should clamp to maximum 50")

        // Test clamping to 1 when zero or negative set
        settings.maxHistoryLimit = 0
        XCTAssertEqual(settings.maxHistoryLimit, 1, "Limit should clamp to minimum 1")

        // Test normal value
        settings.maxHistoryLimit = 15
        XCTAssertEqual(settings.maxHistoryLimit, 15)
    }

    func testHighLimitWarning() {
        let settings = SettingsManager.shared

        settings.maxHistoryLimit = 20
        XCTAssertFalse(settings.isHighLimitWarningActive, "Limit 20 should not trigger warning")

        settings.maxHistoryLimit = 25
        XCTAssertFalse(settings.isHighLimitWarningActive, "Limit 25 should not trigger warning")

        settings.maxHistoryLimit = 30
        XCTAssertTrue(settings.isHighLimitWarningActive, "Limit 30 should trigger high capacity warning")

        settings.maxHistoryLimit = 50
        XCTAssertTrue(settings.isHighLimitWarningActive, "Limit 50 should trigger high capacity warning")
    }

    func testCapacityEviction() {
        appState.settings.maxHistoryLimit = 5

        for i in 1...10 {
            let item = ClipboardItem(content: .text("Item \(i)"))
            appState.handleNewClipboardItem(item)
        }

        XCTAssertEqual(appState.recentItems.count, 5, "Recent items must be capped at 5")
        XCTAssertEqual(appState.recentItems.first?.previewText, "Item 10", "Most recent item should be at the front")
        XCTAssertEqual(appState.recentItems.last?.previewText, "Item 6", "Older items beyond 5 should have been evicted")
    }

    func testPinAndUnpinFlow() {
        let item1 = ClipboardItem(content: .text("Normal Clip"))
        let item2 = ClipboardItem(content: .text("Important Note"))

        appState.handleNewClipboardItem(item1)
        appState.handleNewClipboardItem(item2)

        XCTAssertEqual(appState.recentItems.count, 2)
        XCTAssertEqual(appState.pinnedItems.count, 0)

        // Pin item2
        appState.togglePin(for: item2)

        XCTAssertEqual(appState.pinnedItems.count, 1)
        XCTAssertEqual(appState.pinnedItems.first?.previewText, "Important Note")
        XCTAssertEqual(appState.recentItems.count, 1)
        XCTAssertEqual(appState.recentItems.first?.previewText, "Normal Clip")

        // Unpin item2
        appState.togglePin(for: appState.pinnedItems.first!)

        XCTAssertEqual(appState.pinnedItems.count, 0)
        XCTAssertEqual(appState.recentItems.count, 2)
        XCTAssertEqual(appState.recentItems.first?.previewText, "Important Note", "Unpinned item returns to top of recent items")
    }

    func testSingleItemDeletion() {
        let item1 = ClipboardItem(content: .text("Clip A"))
        let item2 = ClipboardItem(content: .text("Clip B"))

        appState.handleNewClipboardItem(item1)
        appState.handleNewClipboardItem(item2)
        XCTAssertEqual(appState.recentItems.count, 2)

        appState.deleteItem(item1)
        XCTAssertEqual(appState.recentItems.count, 1)
        XCTAssertEqual(appState.recentItems.first?.previewText, "Clip B")
    }

    func testClearRecentVsClearAll() {
        let item1 = ClipboardItem(content: .text("Recent Item"))
        let item2 = ClipboardItem(content: .text("Pinned Snippet"))

        appState.handleNewClipboardItem(item1)
        appState.handleNewClipboardItem(item2)
        appState.togglePin(for: item2)

        XCTAssertEqual(appState.recentItems.count, 1)
        XCTAssertEqual(appState.pinnedItems.count, 1)

        // Clear Recent only
        appState.clearRecentHistory()
        XCTAssertEqual(appState.recentItems.count, 0)
        XCTAssertEqual(appState.pinnedItems.count, 1, "Pinned items must survive clearRecentHistory")

        // Clear All
        appState.clearAll(includingPinned: true)
        XCTAssertEqual(appState.recentItems.count, 0)
        XCTAssertEqual(appState.pinnedItems.count, 0, "Clear all must discard pinned items too")
    }

    func testDuplicateBumping() {
        let itemA = ClipboardItem(content: .text("Hello World"))
        let itemB = ClipboardItem(content: .text("Another Line"))
        let itemAAgain = ClipboardItem(content: .text("Hello World"))

        appState.handleNewClipboardItem(itemA)
        appState.handleNewClipboardItem(itemB)
        XCTAssertEqual(appState.recentItems.count, 2)
        XCTAssertEqual(appState.recentItems.first?.previewText, "Another Line")

        // Re-copying item A should bump it to index 0 without increasing count
        appState.handleNewClipboardItem(itemAAgain)
        XCTAssertEqual(appState.recentItems.count, 2)
        XCTAssertEqual(appState.recentItems.first?.previewText, "Hello World")
    }
}
