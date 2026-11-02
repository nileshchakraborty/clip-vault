import AppKit
import Carbon

public final class HotKeyManager {
    public static let shared = HotKeyManager()

    private var eventHandler: EventHandlerRef?
    private var hotKeyRef: EventHotKeyRef?
    public var onHotKeyPressed: (() -> Void)?

    private init() {}

    public func registerDefaultHotKey() {
        unregisterHotKey()

        // Carbon event spec for HotKey
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        let handler: EventHandlerUPP = { _, inEvent, _ -> OSStatus in
            HotKeyManager.shared.onHotKeyPressed?()
            return noErr
        }

        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            handler,
            1,
            &eventType,
            nil,
            &eventHandler
        )

        guard status == noErr else {
            print("[HotKeyManager] Failed to install event handler: \(status)")
            return
        }

        // Register Cmd + Shift + V (Key code 9 is 'v')
        let hotKeyID = EventHotKeyID(signature: OSType(1129467220), id: 1) // 'CVLT'
        let modifiers = UInt32(cmdKey | shiftKey)
        let keyCode = UInt32(kVK_ANSI_V)

        let regStatus = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if regStatus != noErr {
            print("[HotKeyManager] Failed to register Carbon hotkey: \(regStatus)")
        }
    }

    public func unregisterHotKey() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }

    deinit {
        unregisterHotKey()
    }
}
