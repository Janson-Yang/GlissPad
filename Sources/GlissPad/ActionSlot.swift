import Foundation
import GlissPadCore

struct ActionSlot: Hashable {
    var index: Int

    init(index: Int) {
        self.index = index
    }

    func title(for action: GestureAction) -> String {
        action.name
    }

    func subtitle(for action: GestureAction) -> String {
        action.typeDisplayName
    }

    func symbolName(for action: GestureAction) -> String {
        switch action {
        case .script:
            return "action-script"
        case .keyboardShortcut:
            return "action-keyboard"
        case .testHUD:
            return "action-hud"
        case .latency:
            return "action-latency"
        }
    }
}

enum InspectorMode: Equatable {
    case trigger
    case action
}
