import AppKit
import SwiftUI

public final class AppDelegate: NSObject, NSApplicationDelegate {
    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Setup global hotkey handler
        HotKeyManager.shared.onHotKeyPressed = {
            DispatchQueue.main.async {
                FloatingWindowManager.shared.toggleWindow()
            }
        }

        if SettingsManager.shared.enableGlobalHotKey {
            HotKeyManager.shared.registerDefaultHotKey()
        }
    }

    public func applicationWillTerminate(_ notification: Notification) {
        HotKeyManager.shared.unregisterHotKey()
    }
}
