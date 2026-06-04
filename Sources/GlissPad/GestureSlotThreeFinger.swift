import Foundation
import GlissPadCore

extension GestureSlot {
    func threeFingerRule(in configuration: AppConfiguration) -> ThreeFingerGestureRule? {
        guard case .threeFinger(_, _, let rule)? = trigger(in: configuration) else { return nil }
        return rule
    }

    func write(_ rule: ThreeFingerGestureRule, to configuration: inout AppConfiguration) {
        guard case .threeFinger(let id, let type, _)? = trigger(in: configuration) else { return }
        configuration.gestures.triggers[index] = .threeFinger(id: id, type: type, rule: rule)
    }
}

