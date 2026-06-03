import Foundation

enum GestureActionsCoding {
    static func resolvedDefaultNames(_ actions: [GestureAction]) -> [GestureAction] {
        actions.enumerated().map { index, action in
            action.defaultNamed(index: index)
        }
    }

    static func decode<Key: CodingKey>(
        from container: KeyedDecodingContainer<Key>,
        actionKey: Key,
        actionsKey: Key,
        legacyAction: (String?) -> ScriptAction
    ) throws -> [GestureAction] {
        if container.contains(actionsKey) {
            let actions = try container.decode([GestureAction].self, forKey: actionsKey)
            return resolvedDefaultNames(actions)
        }
        if let action = try? container.decode(GestureAction.self, forKey: actionKey) {
            return resolvedDefaultNames([action])
        }
        let legacyValue = try container.decodeIfPresent(String.self, forKey: actionKey)
        return resolvedDefaultNames([.script(legacyAction(legacyValue))])
    }

    static func scriptActions(_ actions: [ScriptAction]) -> [GestureAction] {
        resolvedDefaultNames(actions.map(GestureAction.script))
    }
}
