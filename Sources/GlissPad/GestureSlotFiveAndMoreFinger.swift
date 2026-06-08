import Foundation
import GlissPadCore

extension GestureSlot {
    func fiveAndMoreFingerRule(in configuration: AppConfiguration) -> FiveAndMoreFingerGestureRule? {
        guard case .fiveAndMoreFinger(_, _, let rule)? = trigger(in: configuration) else { return nil }
        return rule
    }

    func write(_ rule: FiveAndMoreFingerGestureRule, to configuration: inout AppConfiguration) {
        guard case .fiveAndMoreFinger(let id, let type, _)? = trigger(in: configuration) else { return }
        configuration.gestures.triggers[index] = .fiveAndMoreFinger(id: id, type: type, rule: rule)
    }
}
