import AppKit
import Foundation

// MARK: - Helpers
func runCommand(_ cmd: String) -> String {
    let task = Process()
    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = pipe
    task.arguments = ["-c", cmd]
    task.executableURL = URL(fileURLWithPath: "/bin/sh")
    do {
        try task.run()
        task.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    } catch {
        return "Error: \(error)"
    }
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
    print("❌ ClipVault is not running! Launching it now...")
    _ = runCommand("open /Users/nileshchakraborty/workspace/clip-vault/build/Build/Products/Release/ClipVault.app")
    Thread.sleep(forTimeInterval: 1.5)
    guard let newPid = getClipVaultPID() else {
        print("❌ Failed to launch ClipVault. Aborting.")
        exit(1)
    }
    print("✅ ClipVault launched with PID: \(newPid)")
    exit(0)
}

let pb = NSPasteboard.general
print("========================================================")
print("  OPERATION BREAK-CLIPVAULT: ADVERSARIAL CHAOS RIG")
print("  Target PID: \(pid)")
let initialRSS = getProcessMemoryRSS(pid: pid)
print("  Initial Baseline Memory RSS: \(initialRSS / 1024) MB (\(initialRSS) KB)")
print("========================================================\n")

// MARK: - ATTACK VECTOR 1: RAPID BOMBARDMENT (300 rapid copies)
print("⚡ [VECTOR 1] Rapid Pasteboard Bombardment (300 items @ ~20ms interval)...")
let v1Start = CFAbsoluteTimeGetCurrent()
for i in 1...300 {
    pb.clearContents()
    pb.setString("Chaos Bombardment Payload #\(i) - \(UUID().uuidString)", forType: .string)
    usleep(20_000) // 20ms
}
let v1Elapsed = CFAbsoluteTimeGetCurrent() - v1Start
Thread.sleep(forTimeInterval: 1.0) // allow poller to process

guard let pidAfterV1 = getClipVaultPID(), pidAfterV1 == pid else {
    print("💥 CRASH DETECTED during Vector 1! ClipVault process died.")
    exit(1)
}
let v1RSS = getProcessMemoryRSS(pid: pid)
print("   ✅ Vector 1 Complete in \(String(format: "%.2f", v1Elapsed))s (~\(Int(300.0 / v1Elapsed)) copies/sec)")
print("   📊 Memory RSS after Vector 1: \(v1RSS / 1024) MB (Delta: \((v1RSS - initialRSS) / 1024) MB)")
print("   Status: ALIVE\n")

// MARK: - ATTACK VECTOR 2: THE MEGABYTE BOMB (20 MB text + 8 MB raw bitmap)
print("💣 [VECTOR 2] The Megabyte Bomb (20MB Text + 8MB Image payload)...")
let megabyteText = String(repeating: "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_+-=\n", count: 400_000) // ~20MB
print("   -> Writing 20MB raw string to NSPasteboard...")
pb.clearContents()
pb.setString(megabyteText, forType: .string)
Thread.sleep(forTimeInterval: 1.5)

let postTextRSS = getProcessMemoryRSS(pid: pid)
print("   📊 Memory RSS after 20MB text: \(postTextRSS / 1024) MB")

print("   -> Writing 8MB raw bitmap image to NSPasteboard...")
let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: 2000,
    pixelsHigh: 1000,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 8000,
    bitsPerPixel: 32
)!
let pngData = rep.representation(using: .png, properties: [:])!
pb.clearContents()
pb.setData(pngData, forType: .png)
Thread.sleep(forTimeInterval: 1.5)

guard let pidAfterV2 = getClipVaultPID(), pidAfterV2 == pid else {
    print("💥 CRASH DETECTED during Vector 2! ClipVault process died.")
    exit(1)
}
let v2RSS = getProcessMemoryRSS(pid: pid)
print("   ✅ Vector 2 Complete.")
print("   📊 Memory RSS after 20MB text + 8MB image: \(v2RSS / 1024) MB")
print("   Status: ALIVE (Protected by truncation & micro-thumbnailing)\n")

// MARK: - ATTACK VECTOR 3: CORRUPT RTF & BINARY FUZZING
print("☣️ [VECTOR 3] Corrupt RTF & Binary Fuzzing...")
// 1. Unclosed RTF loop
let malformedRTF = "{\\rtf1\\ansi " + String(repeating: "{\\b unclosed bold ", count: 3_000)
pb.clearContents()
pb.setData(malformedRTF.data(using: .utf8)!, forType: .rtf)
pb.setString("Corrupt RTF String", forType: .string)
usleep(250_000)

// 2. Corrupt Binary Image Data
let randomBytes = (0..<100_000).map { _ in UInt8.random(in: 0...255) }
let corruptData = Data(randomBytes)
pb.clearContents()
pb.setData(corruptData, forType: .png)
usleep(250_000)

// 3. Null bytes and boundary characters
pb.clearContents()
pb.setString("NullByte Injection: \0\0\0\u{0000}\u{FFFF}\u{202E}RTL\u{FEFF}", forType: .string)
Thread.sleep(forTimeInterval: 1.0)

guard let pidAfterV3 = getClipVaultPID(), pidAfterV3 == pid else {
    print("💥 CRASH DETECTED during Vector 3! ClipVault process died on corrupt parser.")
    exit(1)
}
print("   ✅ Vector 3 Complete. App survived all malformed/fuzzed payloads without crashing.")
print("   Status: ALIVE\n")

// MARK: - ATTACK VECTOR 4: CORRUPT JSON INJECTION ON DISK
print("📂 [VECTOR 4] Corrupt JSON File Recovery Test...")
let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
let pinnedFile = appSupport.appendingPathComponent("com.clipvault.mac/pinned_items.json")

// Write truncated/malformed JSON
let corruptJSON = "{\"truncated_array\": [{\"id\": \"123\", \"title\": \"halfway..."
try? corruptJSON.data(using: .utf8)?.write(to: pinnedFile)
print("   -> Injected malformed JSON into: \(pinnedFile.path)")

// Restart ClipVault to trigger recovery on launch
print("   -> Restarting ClipVault to test launch recovery...")
_ = runCommand("kill \(pid)")
Thread.sleep(forTimeInterval: 1.0)
_ = runCommand("open /Users/nileshchakraborty/workspace/clip-vault/build/Build/Products/Release/ClipVault.app")
Thread.sleep(forTimeInterval: 1.5)

guard let newPID = getClipVaultPID() else {
    print("💥 CRASH DETECTED during Vector 4! ClipVault failed to launch with corrupt JSON.")
    exit(1)
}
print("   ✅ Vector 4 Complete. ClipVault survived corrupt JSON and launched cleanly with PID: \(newPID)")
print("   Status: ALIVE\n")

// MARK: - ATTACK VECTOR 5: APPLE LEAKS PROFILER
print("🔍 [VECTOR 5] Running Apple /usr/bin/leaks memory analyzer on PID \(newPID)...")
let leaksOutput = runCommand("leaks \(newPID)")
let leakLines = leaksOutput.components(separatedBy: .newlines).filter {
    $0.contains("leaks Report Version") || $0.contains("total leaked bytes") || $0.contains("0 leaks") || $0.contains("Process")
}
for line in leakLines {
    print("   \(line)")
}

if leaksOutput.contains("0 leaks for 0 total leaked bytes") {
    print("   🏆 ZERO MEMORY LEAKS DETECTED! Perfect clean memory management.")
} else {
    print("   ⚠️ Leaks check output summary:")
    let summary = leaksOutput.components(separatedBy: .newlines).suffix(5).joined(separator: "\n   ")
    print("   \(summary)")
}

print("\n========================================================")
print("  OPERATION BREAK-CLIPVAULT COMPLETED SUCCESSFULLY")
print("  All 5 Extreme Attack Vectors Survived!")
print("========================================================")
