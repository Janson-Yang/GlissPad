import Foundation

public struct AppConfiguration: Codable, Equatable, Sendable {
    public var gestures: GestureConfiguration
    public var debugLogging: Bool

    public static let `default` = AppConfiguration(
        gestures: .default,
        debugLogging: false
    )

    public init(gestures: GestureConfiguration, debugLogging: Bool) {
        self.gestures = gestures
        self.debugLogging = debugLogging
    }

    public static func load(path: String?) throws -> AppConfiguration {
        guard let path else { return .default }
        let url = URL(fileURLWithPath: path)
        let data = try Data(contentsOf: url)
        let configuration = try JSONDecoder()
            .decode(AppConfiguration.self, from: data)
            .replacingBundledDefaultScripts()
        try configuration.validate()
        return configuration
    }

    public func validate() throws {
        try gestures.validate()
    }

    func replacingBundledDefaultScripts() -> AppConfiguration {
        var configuration = self
        configuration.gestures.triggers = gestures.triggers.compactMap { trigger in
            migrate(trigger).map(migrateActionBranding)
        }
        return configuration
    }

    private func migrate(_ trigger: GestureRule) -> GestureRule? {
        switch trigger {
        case .press(let id, .threeFingerForcePress, var rule):
            rule.actions = commandActions(rule.actions)
            rule.requiresClick = false
            if rule.minimumForceMilliseconds < 80 { rule.minimumForceMilliseconds = 80 }
            rule = migrateForceTouchPressure(rule)
            return .press(id: id, type: .threeFingerForcePress, rule: rule)
        case .press(let id, .upperLeftForcePress, var rule):
            rule.actions = commandActions(rule.actions)
            return .press(id: id, type: .upperLeftForcePress, rule: migrateCornerForceTouch(rule))
        case .swipe(let id, .leftEdgeTwoFingerSwipe, var rule):
            rule.actions = commandActions(rule.actions)
            return .swipe(id: id, type: .leftEdgeTwoFingerSwipe, rule: enforceLeftEdgeSwipe(rule))
        case .tap(let id, .twoFingerTap, var rule):
            rule.pressKind = .touch
            rule.minimumPressure = TrackpadPressureThreshold.touch
            rule.sustainingPressure = TrackpadPressureThreshold.touch
            return .tap(id: id, type: .twoFingerTap, rule: rule)
        case .hold(let id, .twoFingerHold, var rule):
            rule.actions = commandActions(rule.actions)
            rule = migrateHoldPressure(rule)
            rule = enforceTwoFingerHoldPressKind(rule)
            return .hold(id: id, type: .twoFingerHold, rule: rule)
        case .press(let id, .upperRightForcePress, var rule):
            rule.actions = keyboardViewerActions(rule.actions)
            return .press(id: id, type: .upperRightForcePress, rule: migrateCornerForceTouch(rule))
        case .cornerClick(let id, let type, var rule):
            rule = migrateCornerClickPressure(rule)
            return .cornerClick(id: id, type: type, rule: rule)
        case .hold(let id, let type, var rule):
            rule = migrateHoldPressure(rule)
            return .hold(id: id, type: type, rule: rule)
        case .oneFingerPress:
            return nil
        case .press(let id, let type, var rule):
            rule = migrateForceTouchPressure(rule)
            return .press(id: id, type: type, rule: rule)
        case .transform(let id, let type, var rule):
            rule = migrateTransformSensitivity(rule)
            return .transform(id: id, type: type, rule: rule)
        case .oneFinger, .circle, .shape, .tap, .customPath, .touchStart, .tipTap, .swipe,
             .multiFingerSwipe, .release:
            return trigger
        }
    }

    private func commandActions(_ actions: [GestureAction]) -> [GestureAction] {
        actions.map {
            guard case .script(let action) = $0, shouldReplaceLegacyCommandScript(action) else {
                return $0
            }
            return .script(ScriptAction(
                name: action.name,
                language: .appleScript,
                script: DefaultScripts.placeholderAppleScript,
                timeoutSeconds: action.timeoutSeconds
            ))
        }
    }

    private func keyboardViewerActions(_ actions: [GestureAction]) -> [GestureAction] {
        actions.map {
            guard case .script(let action) = $0,
                  action.language == .appleScript,
                  action.script.contains("TextInputMenuAgent"),
                  shouldReplaceKeyboardViewerScript(action.script) else {
                return $0
            }
            return .script(ScriptAction(
                name: action.name,
                language: .appleScript,
                script: DefaultScripts.toggleKeyboardViewer,
                timeoutSeconds: action.timeoutSeconds
            ))
        }
    }

    private func enforceLeftEdgeSwipe(_ rule: SwipeGestureRule) -> SwipeGestureRule {
        var rule = rule
        if rule.edgeWidth < 0.18 {
            rule.edgeWidth = 0.18
        }
        return rule
    }

    private func enforceTwoFingerHoldPressKind(_ rule: HoldGestureRule) -> HoldGestureRule {
        guard rule.pressKind == .forceClick else { return rule }
        var rule = rule
        rule.pressKind = .click
        rule.minimumPressure = TrackpadPressureThreshold.click
        rule.sustainingPressure = TrackpadPressureThreshold.clickSustain
        return rule
    }

    private func migrateTransformSensitivity(_ rule: TwoFingerTransformGestureRule) -> TwoFingerTransformGestureRule {
        var rule = rule
        if isLegacyValue(rule.minimumScaleChange, in: [0.18]) {
            rule.minimumScaleChange = TwoFingerTransformGestureRule.defaultMinimumScaleChange
        }
        if isLegacyValue(rule.minimumRotationDegrees, in: [25, 14]) {
            rule.minimumRotationDegrees = TwoFingerTransformGestureRule.defaultMinimumRotationDegrees
        }
        return rule
    }

    private func migrateCornerForceTouch(_ rule: PressGestureRule) -> PressGestureRule {
        var rule = rule
        rule.requiresClick = true
        return migrateForceTouchPressure(rule)
    }

    private func migrateForceTouchPressure(_ rule: PressGestureRule) -> PressGestureRule {
        var rule = rule
        if isLegacyValue(rule.minimumPressure, in: [0.86, 0.88, 1.5]) {
            rule.minimumPressure = TrackpadPressureThreshold.forceClick
        }
        if rule.sustainingPressure > rule.minimumPressure
            || isLegacyValue(rule.sustainingPressure, in: [1.2]) {
            rule.sustainingPressure = TrackpadPressureThreshold.forceClickSustain
        }
        return rule
    }

    private func migrateCornerClickPressure(_ rule: CornerClickGestureRule) -> CornerClickGestureRule {
        var rule = rule
        if isLegacyValue(rule.minimumPressure, in: legacyPressures(for: rule.clickKind)) {
            rule.minimumPressure = TrackpadPressureThreshold.value(for: rule.clickKind)
            rule.sustainingPressure = TrackpadPressureThreshold.sustain(for: rule.clickKind)
        } else if rule.clickKind == .forceClick,
                  isLegacyValue(rule.sustainingPressure, in: [1.2]) {
            rule.sustainingPressure = TrackpadPressureThreshold.forceClickSustain
        }
        return rule
    }

    private func migrateHoldPressure(_ rule: HoldGestureRule) -> HoldGestureRule {
        var rule = rule
        if isLegacyValue(rule.minimumPressure, in: legacyPressures(for: rule.pressKind)) {
            rule.minimumPressure = TrackpadPressureThreshold.value(for: rule.pressKind)
            rule.sustainingPressure = TrackpadPressureThreshold.sustain(for: rule.pressKind)
        } else if rule.pressKind == .forceClick,
                  isLegacyValue(rule.sustainingPressure, in: [1.2]) {
            rule.sustainingPressure = TrackpadPressureThreshold.forceClickSustain
        }
        return rule
    }

    private func legacyPressures(for kind: CornerClickKind) -> [Double] {
        kind == .forceClick ? [0.86, 1.0, 1.5] : [0.86, 1.0]
    }

    private func legacyPressures(for kind: HoldPressKind) -> [Double] {
        kind == .forceClick ? [0.86, 1.0, 1.5] : [0.86, 1.0]
    }

    private func isLegacyValue(_ value: Double, in legacyValues: [Double]) -> Bool {
        legacyValues.contains { abs($0 - value) < 0.000_001 }
    }

    private func shouldReplaceKeyboardViewerScript(_ script: String) -> Bool {
        script.contains("clickMatchingKeyboardViewerItem")
            || !script.contains("显示键盘显示程序")
            || !script.contains("Keyboard Viewer menu item was not found.")
    }

    private func shouldReplaceLegacyCommandScript(_ action: ScriptAction) -> Bool {
        action.script.contains("key down command")
    }

    private func migrateActionBranding(_ trigger: GestureRule) -> GestureRule {
        trigger.replacingActions(trigger.actions.map(migrateActionBranding))
    }

    private func migrateActionBranding(_ action: GestureAction) -> GestureAction {
        guard case .testHUD(var hudAction) = action,
              Self.legacyTestHUDTitles().contains(hudAction.title) else {
            return action
        }
        hudAction.title = TestHUDAction().title
        return .testHUD(hudAction)
    }

    private static func legacyTestHUDTitles() -> Set<String> {
        [
            [["Tap", "line"].joined(), "Test HUD"].joined(separator: " "),
            ["Simple", ["B", "T", "T"].joined(), "Test HUD"].joined(separator: " ")
        ]
    }
}
