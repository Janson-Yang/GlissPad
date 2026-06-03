import Foundation

public struct AppPreferences: Equatable, Sendable {
    public var showsStatusItem: Bool

    public init(showsStatusItem: Bool = true) {
        self.showsStatusItem = showsStatusItem
    }
}

public final class UserDefaultsAppPreferencesStore: @unchecked Sendable {
    private enum Keys {
        static let showsStatusItem = "showsStatusItem"
    }

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public var preferences: AppPreferences {
        get {
            AppPreferences(showsStatusItem: storedShowsStatusItem)
        }
        set {
            defaults.set(newValue.showsStatusItem, forKey: Keys.showsStatusItem)
        }
    }

    private var storedShowsStatusItem: Bool {
        guard defaults.object(forKey: Keys.showsStatusItem) != nil else { return true }
        return defaults.bool(forKey: Keys.showsStatusItem)
    }
}
