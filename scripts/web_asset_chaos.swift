import AppKit
import Foundation

func runCommand(_ cmd: String) -> String {
    let task = Process()
    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = pipe
    task.arguments = ["-c", cmd]
    task.executableURL = URL(fileURLWithPath: "/bin/sh")
    try? task.run()
    task.waitUntilExit()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
}

func getClipVaultPID() -> Int? {
    let out = runCommand("pgrep -f ClipVault | head -n 1")
    return Int(out)
}

func getProcessMemoryRSS(pid: Int) -> Int {
    let out = runCommand("ps -o rss= -p \(pid)")
    return Int(out) ?? 0 // in KB
}

guard let pid = getClipVaultPID() else {
    print("❌ ClipVault is not running!")
    exit(1)
}

let assetsDir = "/Users/nileshchakraborty/workspace/clip-vault/build/web_stress_assets"
let pb = NSPasteboard.general

print("=================================================================")
print("  WEB ASSET & GIANT BLOB STRESS TEST")
print("  Target PID: \(pid)")
let initialRSS = getProcessMemoryRSS(pid: pid)
print("  Initial Baseline RSS: \(initialRSS / 1024) MB (\(initialRSS) KB)")
print("=================================================================\n")

let testFiles: [(name: String, type: String)] = [
    ("countries_large.json", "text"),
    ("earth_4k.jpg", "image"),
    ("galaxy_hires.jpg", "image"),
    ("nebula_hires.jpg", "image"),
    ("ocean_hires.jpg", "image"),
    ("ocean_raw.png", "image"),
    ("ocean_raw.tiff", "image")
]

for (fileName, kind) in testFiles {
    let filePath = "\(assetsDir)/\(fileName)"
    guard let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)) else {
        print("⚠️ File not found: \(filePath)")
        continue
    }

    let fileSizeMB = Double(data.count) / (1024.0 * 1024.0)
    print("🚀 Ingesting \(fileName) (\(String(format: "%.2f", fileSizeMB)) MB \(kind.uppercased()))...")

    let startTime = CFAbsoluteTimeGetCurrent()
    pb.clearContents()

    if kind == "text" {
        if let str = String(data: data, encoding: .utf8) {
            pb.setString(str, forType: .string)
        }
    } else {
        // Image ingestion
        if fileName.hasSuffix(".png") {
            pb.setData(data, forType: .png)
        } else if fileName.hasSuffix(".tiff") {
            pb.setData(data, forType: .tiff)
        } else {
            // JPEG image
            if let image = NSImage(data: data), let tiff = image.tiffRepresentation {
                pb.setData(tiff, forType: .tiff)
            }
        }
    }

    // Wait 1.0s for ClipVault poller to detect and ingest
    Thread.sleep(forTimeInterval: 1.0)
    let elapsed = CFAbsoluteTimeGetCurrent() - startTime

    guard let currentPID = getClipVaultPID(), currentPID == pid else {
        print("💥 CRASH DETECTED on \(fileName)! ClipVault terminated.")
        exit(1)
    }

    let currentRSS = getProcessMemoryRSS(pid: pid)
    let deltaRSS = (currentRSS - initialRSS) / 1024
    print("   ✅ Process ALIVE (Ingested in \(String(format: "%.2f", elapsed))s)")
    print("   📊 Memory RSS: \(currentRSS / 1024) MB (Delta from baseline: +\(deltaRSS) MB)\n")
}

print("=================================================================")
print("  WEB ASSET & GIANT BLOB STRESS TEST COMPLETE")
print("=================================================================")
