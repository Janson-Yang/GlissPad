import Foundation

public enum ConfigurationImportConflictResolution: Equatable {
    case replace
    case skip
    case keepBoth
}

public struct ConfigurationImportResult: Equatable {
    public var triggers: [GestureRule]
    public var addedCount: Int
    public var replacedCount: Int
    public var skippedCount: Int
    public var renamedCount: Int
    public var selectedIndex: Int?

    public var appliedCount: Int {
        addedCount + replacedCount
    }
}

public enum ConfigurationImportMerger {
    public static func conflictingNames(current: [GestureRule], imported: [GestureRule]) -> [String] {
        let currentNames = Set(current.map { normalizedName($0.name) })
        return imported.reduce(into: []) { conflicts, trigger in
            let name = normalizedName(trigger.name)
            guard currentNames.contains(name), !conflicts.contains(trigger.name) else { return }
            conflicts.append(trigger.name)
        }
    }

    public static func merge(
        current: [GestureRule],
        imported: [GestureRule],
        resolution: ConfigurationImportConflictResolution
    ) -> ConfigurationImportResult {
        var state = ConfigurationImportState(current)
        for trigger in imported {
            state.merge(trigger, resolution: resolution)
        }
        return state.result()
    }

    fileprivate static func normalizedName(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

private struct ConfigurationImportState {
    var triggers: [GestureRule]
    var existingIDs: Set<String>
    var addedCount = 0
    var replacedCount = 0
    var skippedCount = 0
    var renamedCount = 0
    var selectedIndex: Int?

    init(_ current: [GestureRule]) {
        triggers = current
        existingIDs = Set(current.map(\.id))
    }

    mutating func merge(_ trigger: GestureRule, resolution: ConfigurationImportConflictResolution) {
        if let conflictIndex = nameConflictIndex(for: trigger.name) {
            mergeConflict(trigger, at: conflictIndex, resolution: resolution)
            return
        }
        append(trigger)
    }

    func result() -> ConfigurationImportResult {
        ConfigurationImportResult(
            triggers: triggers,
            addedCount: addedCount,
            replacedCount: replacedCount,
            skippedCount: skippedCount,
            renamedCount: renamedCount,
            selectedIndex: selectedIndex
        )
    }

    private mutating func mergeConflict(
        _ trigger: GestureRule,
        at index: Int,
        resolution: ConfigurationImportConflictResolution
    ) {
        switch resolution {
        case .replace:
            triggers[index] = trigger.replacingIdentifier(triggers[index].id)
            replacedCount += 1
            selectedIndex = selectedIndex ?? index
        case .skip:
            skippedCount += 1
        case .keepBoth:
            append(trigger.replacingName(uniqueName(for: trigger.name)))
            renamedCount += 1
        }
    }

    private mutating func append(_ trigger: GestureRule) {
        let importedID = uniqueIdentifier(preferred: trigger.id)
        triggers.append(trigger.replacingIdentifier(importedID))
        addedCount += 1
        selectedIndex = selectedIndex ?? triggers.count - 1
    }

    private func nameConflictIndex(for name: String) -> Int? {
        let normalized = ConfigurationImportMerger.normalizedName(name)
        return triggers.firstIndex {
            ConfigurationImportMerger.normalizedName($0.name) == normalized
        }
    }

    private func uniqueName(for name: String) -> String {
        let baseName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        var suffix = 2
        var candidate = "\(baseName) \(suffix)"
        while nameConflictIndex(for: candidate) != nil {
            suffix += 1
            candidate = "\(baseName) \(suffix)"
        }
        return candidate
    }

    private mutating func uniqueIdentifier(preferred: String) -> String {
        let trimmed = preferred.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty, !existingIDs.contains(trimmed) {
            existingIDs.insert(trimmed)
            return trimmed
        }
        var identifier = UUID().uuidString
        while existingIDs.contains(identifier) {
            identifier = UUID().uuidString
        }
        existingIDs.insert(identifier)
        return identifier
    }
}
