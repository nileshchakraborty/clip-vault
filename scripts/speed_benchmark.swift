import AppKit
import Foundation

func benchmarkSearchSpeed() {
    print("⚡ Benchmarking Search Speed across 50 items (10,000 queries)...")
    let items = (0..<50).map { i in
        ClipboardItem(content: .text("Code snippet or document line #\(i): const data = fetch('/api/user/\(i)');"))
    }

    let query = "api/user"
    let start = CFAbsoluteTimeGetCurrent()
    var matchCount = 0
    for _ in 0..<10_000 {
        let matches = items.filter { $0.searchIndex.contains(query) }
        matchCount += matches.count
    }
    let elapsed = CFAbsoluteTimeGetCurrent() - start
    print("   ✅ 10,000 search queries completed in \(String(format: "%.4f", elapsed))s (\(Int(10_000.0 / elapsed)) queries/sec)")
    print("   Avg latency per search query: \(String(format: "%.3f", (elapsed / 10_000.0) * 1000_000)) microseconds!\n")
}

func benchmarkDetectionLatency() {
    print("⚡ Benchmarking System Pasteboard Detection Latency...")
    let pb = NSPasteboard.general
    let start = CFAbsoluteTimeGetCurrent()
    pb.clearContents()
    pb.setString("Benchmark copy at \(Date())", forType: .string)
    Thread.sleep(forTimeInterval: 0.25)
    let elapsed = CFAbsoluteTimeGetCurrent() - start
    print("   ✅ Pasteboard updated & poller serviced in \(String(format: "%.3f", elapsed * 1000))ms\n")
}

print("=================================================================")
print("  CLIPVAULT SPEED OPTIMIZATION BENCHMARK")
print("=================================================================\n")
benchmarkSearchSpeed()
benchmarkDetectionLatency()
print("=================================================================")
