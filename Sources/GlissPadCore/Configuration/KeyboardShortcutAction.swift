import Foundation

public struct KeyboardShortcutAction: Codable, Equatable, Sendable {
    public static let defaultKeyHoldMilliseconds = 80
    public static let minimumKeyHoldMilliseconds = 1
    public static let maximumKeyHoldMilliseconds = 10_000
    public static let defaultPostReleaseDelayMilliseconds = 120
    public static let minimumPostReleaseDelayMilliseconds = 0
    public static let maximumPostReleaseDelayMilliseconds = 60_000
    public static var keyHoldMillisecondsRange: ClosedRange<Int> {
        minimumKeyHoldMilliseconds...maximumKeyHoldMilliseconds
    }
    public static var postReleaseDelayMillisecondsRange: ClosedRange<Int> {
        minimumPostReleaseDelayMilliseconds...maximumPostReleaseDelayMilliseconds
    }

    public var name: String
    public var mode: KeyboardShortcutMode
    public var primaryKey: KeyboardKey
    public var secondaryKey: KeyboardKey?
    public var keyHoldMilliseconds: Int
    public var postReleaseDelayMilliseconds: Int

    enum CodingKeys: String, CodingKey {
        case name
        case mode
        case primaryKey
        case secondaryKey
        case keyHoldMilliseconds
        case postReleaseDelayMilliseconds
    }

    public init(
        name: String = "",
        mode: KeyboardShortcutMode,
        primaryKey: KeyboardKey,
        secondaryKey: KeyboardKey? = nil,
        keyHoldMilliseconds: Int = Self.defaultKeyHoldMilliseconds,
        postReleaseDelayMilliseconds: Int = Self.defaultPostReleaseDelayMilliseconds
    ) {
        self.name = name
        self.mode = mode
        self.primaryKey = primaryKey
        self.secondaryKey = secondaryKey
        self.keyHoldMilliseconds = keyHoldMilliseconds
        self.postReleaseDelayMilliseconds = postReleaseDelayMilliseconds
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        mode = try container.decode(KeyboardShortcutMode.self, forKey: .mode)
        primaryKey = try container.decode(KeyboardKey.self, forKey: .primaryKey)
        secondaryKey = try container.decodeIfPresent(KeyboardKey.self, forKey: .secondaryKey)
        keyHoldMilliseconds = try container.decodeIfPresent(
            Int.self,
            forKey: .keyHoldMilliseconds
        ) ?? Self.defaultKeyHoldMilliseconds
        postReleaseDelayMilliseconds = try container.decodeIfPresent(
            Int.self,
            forKey: .postReleaseDelayMilliseconds
        ) ?? Self.defaultPostReleaseDelayMilliseconds
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
        guard Self.keyHoldMillisecondsRange.contains(keyHoldMilliseconds) else {
            throw ConfigurationError.invalidValue("\(name).keyHoldMilliseconds must be 1...10000.")
        }
        guard Self.postReleaseDelayMillisecondsRange.contains(postReleaseDelayMilliseconds) else {
            throw ConfigurationError.invalidValue(
                "\(name).postReleaseDelayMilliseconds must be 0...60000."
            )
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
