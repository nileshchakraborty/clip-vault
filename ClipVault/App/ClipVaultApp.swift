import SwiftUI

@main
struct ClipVaultApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState.shared

    var body: some Scene {
        // macOS Menu Bar Extra
        MenuBarExtra("ClipVault", systemImage: "paperclip") {
            ClipboardPopoverView()
                .environmentObject(appState)
        }
        .menuBarExtraStyle(.window)

        // Native Settings Scene
        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}
