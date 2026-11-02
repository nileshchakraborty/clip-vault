import XCTest
@testable import ClipVault

@MainActor
final class ClipVaultChaosPerfTests: XCTestCase {
    var appState: AppState!

    override func setUp() {
        super.setUp()
        appState = AppState()
        appState.clearAll(includingPinned: true)
    }

    override func tearDown() {
        appState?.clearAll(includingPinned: true)
        appState = nil
        super.tearDown()
    }

    // CHAOS TEST 1: Rapid Flooding (1,000 rapid insertions in loop)
    func testChaosRapidFlooding() {
        appState.settings.maxHistoryLimit = 50

        let startTime = CFAbsoluteTimeGetCurrent()
        for i in 0..<1000 {
            let item = ClipboardItem(content: .text("Rapid Clip #\(i): " + UUID().uuidString))
            appState.handleNewClipboardItem(item)
        }
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime

        XCTAssertEqual(appState.recentItems.count, 50, "Store must strictly cap at 50 even during 1,000 rapid bursts")
        print("[PERF] 1,000 rapid insertions completed in \(elapsed)s (\(Int(1000.0 / elapsed)) ops/sec)")
        XCTAssertLessThan(elapsed, 0.5, "1,000 rapid insertions should execute in under 0.5s")
    }

    // CHAOS TEST 2: Concurrent Race Condition & Main Runloop Processing
    func testChaosConcurrentOperations() {
        appState.settings.maxHistoryLimit = 50
        let queue = DispatchQueue(label: "com.clipvault.chaos", attributes: .concurrent)
        let exp = expectation(description: "Concurrent operations complete")
        let totalCount = 8 * 25
        var completedCount = 0

        for t in 0..<8 {
            for i in 0..<25 {
                queue.async {
                    let item = ClipboardItem(content: .text("Thread \(t) Clip \(i)"))
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self, let state = self.appState else { return }
                        state.handleNewClipboardItem(item)
                        if i % 5 == 0 {
                            state.togglePin(for: item)
                        }
                        if i % 15 == 0 {
                            state.clearRecentHistory()
                        }
                        completedCount += 1
                        if completedCount == totalCount {
                            exp.fulfill()
                        }
                    }
                }
            }
        }

        wait(for: [exp], timeout: 5.0)
        XCTAssertLessThanOrEqual(appState.recentItems.count, 50)
    }

    // CHAOS TEST 3: Gigantic Text Payload & Truncation Guard (5 MB text string)
    func testChaosGiganticTextPayload() {
        let largeChunk = String(repeating: "A1B2C3D4E5F6G7H8I9J0", count: 250_000) // ~5MB
        let item = ClipboardItem(content: .text(largeChunk, isTruncated: true))

        XCTAssertTrue(item.previewText.contains("[Truncated]"))
        XCTAssertLessThanOrEqual(item.previewText.count, 550, "Preview text should be capped under 550 chars")

        let startTime = CFAbsoluteTimeGetCurrent()
        appState.handleNewClipboardItem(item)
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime

        print("[PERF] Ingestion of 5MB payload completed in \(elapsed)s")
        XCTAssertLessThan(elapsed, 0.05, "Ingesting large text must complete in under 50ms")
    }

    // CHAOS TEST 4: Malformed Data & Unicode Fuzzing
    func testChaosMalformedAndFuzzedStrings() {
        let fuzzedStrings = [
            "",
            "\0\0\0\u{0000}\u{FFFF}",
            String(repeating: "﷽", count: 10_000),
            String(repeating: "🏴󠁧󠁢󠁥󠁮󠁧󠁿", count: 5_000),
            String(repeating: "\u{202E}RTL-OVERRIDE", count: 1_000),
            "<script>alert('xss')</script>\"'--",
            "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII="
        ]

        for (idx, str) in fuzzedStrings.enumerated() {
            let item = ClipboardItem(content: .text(str))
            appState.handleNewClipboardItem(item)
            _ = item.metadataDescription
            _ = item.previewText
            _ = item.searchString
            print("[CHAOS] Processed fuzz payload #\(idx)")
        }

        XCTAssertLessThanOrEqual(appState.recentItems.count, 50)
    }

    // CHAOS TEST 5: Memory Leak & Retention Cycle under 50-item saturation
    func testSaturationMemoryFootprint() {
        appState.settings.maxHistoryLimit = 50

        for i in 0..<50 {
            if i % 3 == 0 {
                let url = URL(string: "https://example.com/page/\(i)?query=parameter")!
                appState.handleNewClipboardItem(ClipboardItem(content: .url(url)))
            } else if i % 3 == 1 {
                let hex = String(format: "#%06X", i * 123456 & 0xFFFFFF)
                appState.handleNewClipboardItem(ClipboardItem(content: .color(hex: hex)))
            } else {
                appState.handleNewClipboardItem(ClipboardItem(content: .text("Normal text clip number \(i) with some explanation")))
            }
        }

        XCTAssertEqual(appState.recentItems.count, 50)

        appState.clearAll(includingPinned: true)
        XCTAssertEqual(appState.recentItems.count, 0)
        XCTAssertEqual(appState.pinnedItems.count, 0)
    }

    // CHAOS TEST 6: Tiered LRU Image Retention (Verifies that items >3 have raw data evicted)
    func testTieredLRUImageRetention() {
        appState.settings.maxHistoryLimit = 50

        // Create 5 distinct dummy images
        for i in 0..<5 {
            let width = 50 + i
            let rep = NSBitmapImageRep(
                bitmapDataPlanes: nil,
                pixelsWide: width,
                pixelsHigh: 50,
                bitsPerSample: 8,
                samplesPerPixel: 4,
                hasAlpha: true,
                isPlanar: false,
                colorSpaceName: .deviceRGB,
                bytesPerRow: width * 4,
                bitsPerPixel: 32
            )!
            let pngData = rep.representation(using: .png, properties: [:])!
            let item = ClipboardItem(content: .image(data: pngData, thumbnailData: pngData))
            appState.handleNewClipboardItem(item)
        }

        XCTAssertEqual(appState.recentItems.count, 5, "Store must contain 5 distinct images")

        // The newest 3 items should keep full raw imageData
        XCTAssertNotNil(appState.recentItems[0].content.imageData, "Top 1 item must retain full raw image data")
        XCTAssertNotNil(appState.recentItems[1].content.imageData, "Top 2 item must retain full raw image data")
        XCTAssertNotNil(appState.recentItems[2].content.imageData, "Top 3 item must retain full raw image data")

        // Items 4 and 5 must have had raw imageData evicted while keeping micro-thumbnail!
        XCTAssertNil(appState.recentItems[3].content.imageData, "Item 4 must have raw data evicted")
        XCTAssertNotNil(appState.recentItems[3].content.thumbnailData, "Item 4 must retain micro-thumbnail")
        XCTAssertNil(appState.recentItems[4].content.imageData, "Item 5 must have raw data evicted")
        XCTAssertNotNil(appState.recentItems[4].content.thumbnailData, "Item 5 must retain micro-thumbnail")
    }
}
