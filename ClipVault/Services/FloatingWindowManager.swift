import AppKit
import SwiftUI

public final class FloatingWindowManager: ObservableObject {
    public static let shared = FloatingWindowManager()

    private var panel: NSPanel?

    private init() {}

    public func toggleWindow() {
        if let panel = panel, panel.isVisible {
            panel.orderOut(nil)
        } else {
            showWindow()
        }
    }

    public func showWindow() {
        if panel == nil {
            createPanel()
        }

        guard let panel = panel else { return }

        panel.center()
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    public func hideWindow() {
        panel?.orderOut(nil)
    }

    private func createPanel() {
        let hudView = FloatingHUDView(onClose: { [weak self] in
            self?.hideWindow()
        })

        let hostingView = NSHostingView(rootView: hudView.environmentObject(AppState.shared))

        let newPanel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 500),
            styleMask: [.titled, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        newPanel.titleVisibility = .hidden
        newPanel.titlebarAppearsTransparent = true
        newPanel.isMovableByWindowBackground = true
        newPanel.level = .floating
        newPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        newPanel.backgroundColor = .clear
        newPanel.contentView = hostingView
        newPanel.hasShadow = true

        NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification,
            object: newPanel,
            queue: .main
        ) { [weak self] _ in
            self?.hideWindow()
        }

        self.panel = newPanel
    }
}
