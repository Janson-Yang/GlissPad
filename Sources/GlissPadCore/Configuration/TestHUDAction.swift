import Foundation

public struct TestHUDAction: Codable, Equatable, Sendable {
    public var name: String
    public var title: String
    public var detail: String

    enum CodingKeys: String, CodingKey {
        case name
        case title
        case detail
    }

    public init(
        name: String = "",
        title: String = "GlissPad Test HUD",
        detail: String = "Trigger fired."
    ) {
        self.name = name
        self.title = title
        self.detail = detail
    }

    public func defaultNamed(index: Int) -> TestHUDAction {
        guard name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return self }
        var action = self
        action.name = "\(Self.displayName) \(index + 1)"
        return action
    }

    func validate(name: String) throws {
        guard !self.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ConfigurationError.invalidValue("\(name).name must not be empty.")
        }
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ConfigurationError.invalidValue("\(name).title must not be empty.")
        }
        guard !detail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ConfigurationError.invalidValue("\(name).detail must not be empty.")
        }
    }

    public static var displayName: String {
        "Pop up a test HUD"
    }
}
