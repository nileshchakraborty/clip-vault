import SwiftUI

public struct SettingsView: View {
    @ObservedObject var settings = SettingsManager.shared
    @EnvironmentObject var appState: AppState

    public init() {}

    public var body: some View {
        TabView {
            HistorySettingsTab(settings: settings)
                .tabItem {
                    Label("Capacity", systemImage: "slider.horizontal.3")
                }

            ShortcutsSettingsTab(settings: settings)
                .tabItem {
                    Label("Shortcuts", systemImage: "command")
                }

            AboutMeTab()
                .tabItem {
                    Label("About Me", systemImage: "person.crop.circle")
                }

            TermsTab()
                .tabItem {
                    Label("Terms", systemImage: "doc.text")
                }

            PrivacyNoticeTab()
                .tabItem {
                    Label("Privacy Notice", systemImage: "lock.shield")
                }
        }
        .frame(width: 540, height: 460)
        .background(Color(NSColor.windowBackgroundColor))
    }
}
