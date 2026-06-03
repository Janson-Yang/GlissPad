import Foundation

public struct LatencyAction: Codable, Equatable, Sendable {
    public static let displayName = "Action Latency"
    public static let minimumDurationMilliseconds = 1
    public static let maximumDurationMilliseconds = 60_000

    public var name: String
    public var durationMilliseconds: Int

    enum CodingKeys: String, CodingKey {
        case name
        case durationMilliseconds
    }

    public init(name: String = "", durationMilliseconds: Int = 1_000) {
        self.name = name
        self.durationMilliseconds = durationMilliseconds
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        durationMilliseconds = try container.decode(Int.self, forKey: .durationMilliseconds)
    }

    public func defaultNamed(index: Int) -> LatencyAction {
        guard name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return self }
        var action = self
        action.name = "\(Self.displayName) \(index + 1)"
        return action
    }

    func validate(name: String) throws {
        guard !self.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ConfigurationError.invalidValue("\(name).name must not be empty.")
        }
        let durationRange = Self.minimumDurationMilliseconds...Self.maximumDurationMilliseconds
        guard durationRange.contains(durationMilliseconds) else {
            throw ConfigurationError.invalidValue("\(name).durationMilliseconds must be 1...60000.")
        }
    }
}
