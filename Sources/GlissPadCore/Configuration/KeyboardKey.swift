import Foundation

public struct KeyboardKey: Codable, Equatable, Sendable {
    public var keyCode: UInt16
    public var displayName: String

    enum CodingKeys: String, CodingKey {
        case keyCode
        case displayName
    }

    public init(keyCode: UInt16, displayName: String? = nil) {
        self.keyCode = keyCode
        self.displayName = displayName ?? Self.displayName(for: keyCode)
    }

    public init(from decoder: Decoder) throws {
        let singleValue = try? decoder.singleValueContainer()
        if let legacyName = try? singleValue?.decode(String.self),
           let legacyKey = Self.legacyKey(named: legacyName) {
            self = legacyKey
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        keyCode = try container.decode(UInt16.self, forKey: .keyCode)
        displayName = try container.decodeIfPresent(String.self, forKey: .displayName)
            ?? Self.displayName(for: keyCode)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(keyCode, forKey: .keyCode)
        try container.encode(displayName, forKey: .displayName)
    }

    public var isModifier: Bool {
        Self.modifierKeyCodes.contains(keyCode)
    }

    public static func displayName(for keyCode: UInt16, characters: String? = nil) -> String {
        if let name = keyCodeNames[keyCode] { return name }
        let trimmed = characters?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !trimmed.isEmpty { return trimmed.uppercased() }
        return "Key Code \(keyCode)"
    }

    public static let a = KeyboardKey(keyCode: 0, displayName: "A")
    public static let leftCommand = KeyboardKey(keyCode: 55, displayName: "Left Command")
    public static let command = leftCommand

    private static func legacyKey(named name: String) -> KeyboardKey? {
        legacyNames[name]
    }

    private static let modifierKeyCodes: Set<UInt16> = [54, 55, 56, 58, 59, 60, 61, 62]

    private static let legacyNames: [String: KeyboardKey] = [
        "a": KeyboardKey(keyCode: 0, displayName: "A"),
        "b": KeyboardKey(keyCode: 11, displayName: "B"),
        "c": KeyboardKey(keyCode: 8, displayName: "C"),
        "d": KeyboardKey(keyCode: 2, displayName: "D"),
        "e": KeyboardKey(keyCode: 14, displayName: "E"),
        "f": KeyboardKey(keyCode: 3, displayName: "F"),
        "g": KeyboardKey(keyCode: 5, displayName: "G"),
        "h": KeyboardKey(keyCode: 4, displayName: "H"),
        "i": KeyboardKey(keyCode: 34, displayName: "I"),
        "j": KeyboardKey(keyCode: 38, displayName: "J"),
        "k": KeyboardKey(keyCode: 40, displayName: "K"),
        "l": KeyboardKey(keyCode: 37, displayName: "L"),
        "m": KeyboardKey(keyCode: 46, displayName: "M"),
        "n": KeyboardKey(keyCode: 45, displayName: "N"),
        "o": KeyboardKey(keyCode: 31, displayName: "O"),
        "p": KeyboardKey(keyCode: 35, displayName: "P"),
        "q": KeyboardKey(keyCode: 12, displayName: "Q"),
        "r": KeyboardKey(keyCode: 15, displayName: "R"),
        "s": KeyboardKey(keyCode: 1, displayName: "S"),
        "t": KeyboardKey(keyCode: 17, displayName: "T"),
        "u": KeyboardKey(keyCode: 32, displayName: "U"),
        "v": KeyboardKey(keyCode: 9, displayName: "V"),
        "w": KeyboardKey(keyCode: 13, displayName: "W"),
        "x": KeyboardKey(keyCode: 7, displayName: "X"),
        "y": KeyboardKey(keyCode: 16, displayName: "Y"),
        "z": KeyboardKey(keyCode: 6, displayName: "Z"),
        "zero": KeyboardKey(keyCode: 29, displayName: "0"),
        "one": KeyboardKey(keyCode: 18, displayName: "1"),
        "two": KeyboardKey(keyCode: 19, displayName: "2"),
        "three": KeyboardKey(keyCode: 20, displayName: "3"),
        "four": KeyboardKey(keyCode: 21, displayName: "4"),
        "five": KeyboardKey(keyCode: 23, displayName: "5"),
        "six": KeyboardKey(keyCode: 22, displayName: "6"),
        "seven": KeyboardKey(keyCode: 26, displayName: "7"),
        "eight": KeyboardKey(keyCode: 28, displayName: "8"),
        "nine": KeyboardKey(keyCode: 25, displayName: "9"),
        "command": leftCommand,
        "shift": KeyboardKey(keyCode: 56, displayName: "Left Shift"),
        "option": KeyboardKey(keyCode: 58, displayName: "Left Option"),
        "control": KeyboardKey(keyCode: 59, displayName: "Left Control"),
        "space": KeyboardKey(keyCode: 49, displayName: "Space"),
        "tab": KeyboardKey(keyCode: 48, displayName: "Tab"),
        "return": KeyboardKey(keyCode: 36, displayName: "Return"),
        "escape": KeyboardKey(keyCode: 53, displayName: "Escape"),
        "delete": KeyboardKey(keyCode: 51, displayName: "Delete"),
        "forwardDelete": KeyboardKey(keyCode: 117, displayName: "Forward Delete")
    ]

    private static let keyCodeNames: [UInt16: String] = [
        0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
        8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
        16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
        23: "5", 25: "9", 26: "7", 28: "8", 29: "0", 31: "O", 32: "U",
        34: "I", 35: "P", 37: "L", 38: "J", 40: "K", 45: "N", 46: "M",
        36: "Return", 48: "Tab", 49: "Space", 51: "Delete", 53: "Escape",
        54: "Right Command", 55: "Left Command", 56: "Left Shift", 57: "Caps Lock",
        58: "Left Option", 59: "Left Control", 60: "Right Shift",
        61: "Right Option", 62: "Right Control", 63: "Fn",
        96: "F5", 97: "F6", 98: "F7", 99: "F3", 100: "F8", 101: "F9",
        103: "F11", 105: "F13", 106: "F16", 107: "F14", 109: "F10",
        111: "F12", 113: "F15", 117: "Forward Delete", 118: "F4",
        120: "F2", 122: "F1"
    ]
}
