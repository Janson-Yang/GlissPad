import Foundation

public struct GestureConfiguration: Codable, Equatable, Sendable {
    public var triggers: [GestureRule]

    public static let `default` = GestureConfiguration(triggers: [])

    enum CodingKeys: String, CodingKey {
        case triggers
        case threeFingerForcePress
        case upperLeftForcePress
        case leftEdgeTwoFingerSwipe
        case twoFingerHold
        case upperRightForcePress
    }

    public init(triggers: [GestureRule]) {
        self.triggers = triggers
        resolveDefaultNames()
    }

    public init(
        threeFingerForcePress: PressGestureRule,
        upperLeftForcePress: PressGestureRule,
        leftEdgeTwoFingerSwipe: SwipeGestureRule,
        twoFingerHold: HoldGestureRule,
        upperRightForcePress: PressGestureRule
    ) {
        self.init(triggers: [
            .press(id: GestureTriggerType.threeFingerForcePress.defaultID, type: .threeFingerForcePress, rule: threeFingerForcePress),
            .press(id: GestureTriggerType.upperLeftForcePress.defaultID, type: .upperLeftForcePress, rule: upperLeftForcePress),
            .swipe(id: GestureTriggerType.leftEdgeTwoFingerSwipe.defaultID, type: .leftEdgeTwoFingerSwipe, rule: leftEdgeTwoFingerSwipe),
            .hold(id: GestureTriggerType.twoFingerHold.defaultID, type: .twoFingerHold, rule: twoFingerHold),
            .press(id: GestureTriggerType.upperRightForcePress.defaultID, type: .upperRightForcePress, rule: upperRightForcePress)
        ])
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let triggers = try container.decodeIfPresent([GestureRule].self, forKey: .triggers) {
            self.triggers = triggers
        } else {
            triggers = try Self.legacyTriggers(from: container)
        }
        resolveDefaultNames()
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(triggers, forKey: .triggers)
    }

    public func validate() throws {
        guard Set(triggers.map(\.id)).count == triggers.count else {
            throw ConfigurationError.invalidValue("gestures.triggers ids must be unique.")
        }
        for (index, trigger) in triggers.enumerated() {
            try trigger.validate(name: "triggers[\(index)]")
        }
    }

    private static func legacyTriggers(
        from container: KeyedDecodingContainer<CodingKeys>
    ) throws -> [GestureRule] {
        let defaults = Self.default
        return [
            .press(
                id: GestureTriggerType.threeFingerForcePress.defaultID,
                type: .threeFingerForcePress,
                rule: try container.decodeIfPresent(PressGestureRule.self, forKey: .threeFingerForcePress)
                    ?? defaults.threeFingerForcePress
            ),
            .press(
                id: GestureTriggerType.upperLeftForcePress.defaultID,
                type: .upperLeftForcePress,
                rule: try container.decodeIfPresent(PressGestureRule.self, forKey: .upperLeftForcePress)
                    ?? defaults.upperLeftForcePress
            ),
            .swipe(
                id: GestureTriggerType.leftEdgeTwoFingerSwipe.defaultID,
                type: .leftEdgeTwoFingerSwipe,
                rule: try container.decodeIfPresent(SwipeGestureRule.self, forKey: .leftEdgeTwoFingerSwipe)
                    ?? defaults.leftEdgeTwoFingerSwipe
            ),
            .hold(
                id: GestureTriggerType.twoFingerHold.defaultID,
                type: .twoFingerHold,
                rule: try container.decodeIfPresent(HoldGestureRule.self, forKey: .twoFingerHold)
                    ?? defaults.twoFingerHold
            ),
            .press(
                id: GestureTriggerType.upperRightForcePress.defaultID,
                type: .upperRightForcePress,
                rule: try container.decodeIfPresent(PressGestureRule.self, forKey: .upperRightForcePress)
                    ?? defaults.upperRightForcePress
            )
        ]
    }

    private mutating func resolveDefaultNames() {
        for index in triggers.indices {
            triggers[index] = defaultNamed(triggers[index], ordinal: ordinal(for: index))
        }
    }

    private func ordinal(for index: Int) -> Int {
        let type = triggers[index].type
        return triggers[...index].filter { $0.type == type }.count
    }

    private func defaultNamed(_ trigger: GestureRule, ordinal: Int) -> GestureRule {
        guard trigger.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return trigger }
        return trigger.replacingName("\(trigger.type.displayName) \(ordinal)")
    }
}
