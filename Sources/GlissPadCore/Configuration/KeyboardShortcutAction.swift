import Foundation

public struct KeyboardShortcutAction: Codable, Equatable, Sendable {
    public var name: String
    public var mode: KeyboardShortcutMode
    public var primaryKey: KeyboardKey
    public var secondaryKey: KeyboardKey?

    public init(
        name: String = "",
        mode: KeyboardShortcutMode,
        primaryKey: KeyboardKey,
        secondaryKey: KeyboardKey? = nil
    ) {
        self.name = name
        self.mode = mode
        self.primaryKey = primaryKey
        self.secondaryKey = secondaryKey
    }

    public func defaultNamed(index: Int) -> KeyboardShortcutAction {
        guard name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return self }
        var action = self
        action.name = "\(Self.displayName) \(index + 1)"
        return action
    }

    func validate(name: String) throws {
        guard !self.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ConfigurationError.invalidValue("\(name).name must not be empty.")
        }
        guard mode == .singleKey || secondaryKey != nil else {
            throw ConfigurationError.invalidValue("\(name).secondaryKey is required for key combination.")
        }
        guard primaryKey != secondaryKey else {
            throw ConfigurationError.invalidValue("\(name) must not use the same key twice.")
        }
    }

    public static var displayName: String {
        "Keyboard Shortcut"
    }
}

public enum KeyboardShortcutMode: String, CaseIterable, Codable, Equatable, Sendable {
    case singleKey
    case keyCombination

    public var displayName: String {
        switch self {
        case .singleKey: return "Press Single Key"
        case .keyCombination: return "Press Key Combination"
        }
    }
}
