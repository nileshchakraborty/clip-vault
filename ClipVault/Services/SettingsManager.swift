import SwiftUI
import Combine

@MainActor
public final class SettingsManager: ObservableObject {
    public static let shared = SettingsManager()

    // MARK: - Keys
    private enum Keys {
        static let maxHistoryLimit = "maxHistoryLimit"
        static let persistPinnedItems = "persistPinnedItems"
        static let enableGlobalHotKey = "enableGlobalHotKey"
        static let soundEffectsEnabled = "soundEffectsEnabled"
    }

    // MARK: - Constants
    public static let maxAllowedLimit: Int = 50
    public static let minAllowedLimit: Int = 1
    public static let warningThreshold: Int = 25
    public static let presetLimits: [Int] = [5, 10, 15, 20, 25, 30, 40, 50]

    // MARK: - Published Properties
    @Published public var maxHistoryLimit: Int {
        didSet {
            let clamped = min(max(SettingsManager.minAllowedLimit, maxHistoryLimit), SettingsManager.maxAllowedLimit)
            if maxHistoryLimit != clamped {
                maxHistoryLimit = clamped
            }
            UserDefaults.standard.set(clamped, forKey: Keys.maxHistoryLimit)
        }
    }

    @Published public var persistPinnedItems: Bool {
        didSet {
            UserDefaults.standard.set(persistPinnedItems, forKey: Keys.persistPinnedItems)
        }
    }

    @Published public var enableGlobalHotKey: Bool {
        didSet {
            UserDefaults.standard.set(enableGlobalHotKey, forKey: Keys.enableGlobalHotKey)
        }
    }

    @Published public var soundEffectsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(soundEffectsEnabled, forKey: Keys.soundEffectsEnabled)
        }
    }

    // MARK: - Initialization
    public init() {
        let savedLimit = UserDefaults.standard.integer(forKey: Keys.maxHistoryLimit)
        self.maxHistoryLimit = savedLimit > 0 ? min(savedLimit, SettingsManager.maxAllowedLimit) : 15

        self.persistPinnedItems = UserDefaults.standard.bool(forKey: Keys.persistPinnedItems)
        self.enableGlobalHotKey = UserDefaults.standard.object(forKey: Keys.enableGlobalHotKey) == nil
            ? true
            : UserDefaults.standard.bool(forKey: Keys.enableGlobalHotKey)

        self.soundEffectsEnabled = UserDefaults.standard.object(forKey: Keys.soundEffectsEnabled) == nil
            ? true
            : UserDefaults.standard.bool(forKey: Keys.soundEffectsEnabled)
    }

    public var isHighLimitWarningActive: Bool {
        return maxHistoryLimit > SettingsManager.warningThreshold
    }

    public var warningMessage: String {
        return "A limit above \(SettingsManager.warningThreshold) items will increase RAM usage and keep sensitive clipboard contents in memory longer. All clipboard items remain in volatile memory and are purged on quit unless pinned persistence is enabled."
    }
}
