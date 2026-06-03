import Foundation

public enum GestureAction: Codable, Equatable, Sendable {
    case script(ScriptAction)
    case keyboardShortcut(KeyboardShortcutAction)
    case testHUD(TestHUDAction)
    case latency(LatencyAction)

    enum CodingKeys: String, CodingKey {
        case type
        case name
        case language
        case script
        case timeoutSeconds
        case mode
        case primaryKey
        case secondaryKey
        case title
        case detail
        case durationMilliseconds
    }

    enum ActionType: String, Codable {
        case script
        case keyboardShortcut
        case testHUD
        case latency
    }

    public var name: String {
        switch self {
        case .script(let action): return action.name
        case .keyboardShortcut(let action): return action.name
        case .testHUD(let action): return action.name
        case .latency(let action): return action.name
        }
    }

    public var typeDisplayName: String {
        switch self {
        case .script(let action): return action.language.displayName
        case .keyboardShortcut: return KeyboardShortcutAction.displayName
        case .testHUD: return TestHUDAction.displayName
        case .latency: return LatencyAction.displayName
        }
    }

    public var scriptAction: ScriptAction? {
        guard case .script(let action) = self else { return nil }
        return action
    }

    public var keyboardShortcutAction: KeyboardShortcutAction? {
        guard case .keyboardShortcut(let action) = self else { return nil }
        return action
    }

    public var testHUDAction: TestHUDAction? {
        guard case .testHUD(let action) = self else { return nil }
        return action
    }

    public var latencyAction: LatencyAction? {
        guard case .latency(let action) = self else { return nil }
        return action
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decodeIfPresent(ActionType.self, forKey: .type)
        switch type {
        case .script, nil:
            self = .script(try ScriptAction(from: decoder))
        case .keyboardShortcut:
            self = .keyboardShortcut(try KeyboardShortcutAction(from: decoder))
        case .testHUD:
            self = .testHUD(try TestHUDAction(from: decoder))
        case .latency:
            self = .latency(try LatencyAction(from: decoder))
        }
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .script(let action):
            try encodeScript(action, to: encoder)
        case .keyboardShortcut(let action):
            try encodeKeyboardShortcut(action, to: encoder)
        case .testHUD(let action):
            try encodeTestHUD(action, to: encoder)
        case .latency(let action):
            try encodeLatency(action, to: encoder)
        }
    }

    public func defaultNamed(index: Int) -> GestureAction {
        switch self {
        case .script(let action):
            return .script(action.defaultNamed(index: index))
        case .keyboardShortcut(let action):
            return .keyboardShortcut(action.defaultNamed(index: index))
        case .testHUD(let action):
            return .testHUD(action.defaultNamed(index: index))
        case .latency(let action):
            return .latency(action.defaultNamed(index: index))
        }
    }

    public func replacingName(_ name: String) -> GestureAction {
        switch self {
        case .script(var action):
            action.name = name
            return .script(action)
        case .keyboardShortcut(var action):
            action.name = name
            return .keyboardShortcut(action)
        case .testHUD(var action):
            action.name = name
            return .testHUD(action)
        case .latency(var action):
            action.name = name
            return .latency(action)
        }
    }

    public func validate(name: String) throws {
        switch self {
        case .script(let action):
            try action.validate(name: name)
        case .keyboardShortcut(let action):
            try action.validate(name: name)
        case .testHUD(let action):
            try action.validate(name: name)
        case .latency(let action):
            try action.validate(name: name)
        }
    }

    private func encodeScript(_ action: ScriptAction, to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(ActionType.script, forKey: .type)
        try container.encode(action.name, forKey: .name)
        try container.encode(action.language, forKey: .language)
        try container.encode(action.script, forKey: .script)
        try container.encode(action.timeoutSeconds, forKey: .timeoutSeconds)
    }

    private func encodeKeyboardShortcut(
        _ action: KeyboardShortcutAction,
        to encoder: Encoder
    ) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(ActionType.keyboardShortcut, forKey: .type)
        try container.encode(action.name, forKey: .name)
        try container.encode(action.mode, forKey: .mode)
        try container.encode(action.primaryKey, forKey: .primaryKey)
        try container.encodeIfPresent(action.secondaryKey, forKey: .secondaryKey)
    }

    private func encodeTestHUD(_ action: TestHUDAction, to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(ActionType.testHUD, forKey: .type)
        try container.encode(action.name, forKey: .name)
        try container.encode(action.title, forKey: .title)
        try container.encode(action.detail, forKey: .detail)
    }

    private func encodeLatency(_ action: LatencyAction, to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(ActionType.latency, forKey: .type)
        try container.encode(action.name, forKey: .name)
        try container.encode(action.durationMilliseconds, forKey: .durationMilliseconds)
    }
}

public extension GestureAction {
    var script: String {
        scriptAction?.script ?? ""
    }

    var language: ScriptLanguage? {
        scriptAction?.language
    }

    var timeoutSeconds: TimeInterval? {
        scriptAction?.timeoutSeconds
    }
}
