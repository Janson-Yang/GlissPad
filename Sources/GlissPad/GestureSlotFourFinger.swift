import Foundation
import GlissPadCore

extension GestureSlot {
    func fourFingerRule(in configuration: AppConfiguration) -> FourFingerGestureRule? {
        guard case .fourFinger(_, _, let rule)? = trigger(in: configuration) else { return nil }
        return rule
    }

    func write(_ rule: FourFingerGestureRule, to configuration: inout AppConfiguration) {
        guard case .fourFinger(let id, let type, _)? = trigger(in: configuration) else { return }
        configuration.gestures.triggers[index] = .fourFinger(id: id, type: type, rule: rule)
    }
}

