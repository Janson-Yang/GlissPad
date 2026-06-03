import Foundation

public struct RecognizedGesture: Equatable, Sendable {
    public typealias Kind = GestureTriggerType

    let id: String
    let kind: Kind
    let name: String
    let actions: [GestureAction]
    let frame: TouchFrame

    var action: GestureAction {
        actions[0]
    }
}
