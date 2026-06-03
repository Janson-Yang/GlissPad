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
            return "terminal.fill"
        case .keyboardShortcut:
            return "keyboard"
        case .testHUD:
            return "rectangle.inset.filled.and.person.filled"
        case .latency:
            return "timer"
        }
    }
}

enum InspectorMode: Equatable {
    case trigger
    case action
}
