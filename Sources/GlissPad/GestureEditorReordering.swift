import AppKit
import GlissPadCore

struct ListReorderState {
    let sourceIndex: Int
    var targetIndex: Int
}

@MainActor
extension GestureEditorWindowController {
    func beginTriggerReorder(from index: Int) -> Bool {
        guard configuration.gestures.triggers.indices.contains(index),
              commitVisibleEdits(restartActiveListener: false) else { return false }
        triggerReorderState = ListReorderState(sourceIndex: index, targetIndex: index)
        selectedSlot = GestureSlot(index: index)
        inspectorMode = .trigger
        refreshSelectionVisuals()
        return true
    }

    func updateTriggerReorder(windowPoint: NSPoint) {
        guard var state = triggerReorderState,
              let target = targetTriggerIndex(at: windowPoint),
              state.targetIndex != target else { return }
        moveVisualRow(in: triggerListStack, rows: triggerRows(), from: state.targetIndex, to: target)
        state.targetIndex = target
        triggerReorderState = state
    }

    func endTriggerReorder() {
        guard let state = triggerReorderState else { return }
        triggerReorderState = nil
        do {
            applyTriggerReorder(state)
            try saveCurrentConfiguration(restartActiveListener: true)
            rebuildTriggerList()
            rebuildActionList()
            loadSelectedRule()
            statusLabel.stringValue = "Reordered triggers."
        } catch {
            statusLabel.stringValue = "Reorder trigger failed: \(error)"
        }
    }

    func beginActionReorder(from index: Int) -> Bool {
        guard selectedSlot.actions(in: configuration).indices.contains(index) else { return false }
        do {
            try writeVisibleRule()
            actionReorderState = ListReorderState(sourceIndex: index, targetIndex: index)
            selectedAction = ActionSlot(index: index)
            inspectorMode = .action
            setActionSeparatorsHidden(true)
            refreshSelectionVisuals()
            return true
        } catch {
            statusLabel.stringValue = "Reorder action failed: \(error)"
            return false
        }
    }

    func updateActionReorder(windowPoint: NSPoint) {
        guard var state = actionReorderState,
              let target = targetActionIndex(at: windowPoint),
              state.targetIndex != target else { return }
        moveVisualRow(in: actionListStack, rows: actionRows(), from: state.targetIndex, to: target)
        state.targetIndex = target
        actionReorderState = state
    }

    func endActionReorder() {
        guard let state = actionReorderState else { return }
        actionReorderState = nil
        do {
            setActionSeparatorsHidden(false)
            applyActionReorder(state)
            try saveCurrentConfiguration(restartActiveListener: true)
            rebuildActionList()
            loadSelectedRule()
            statusLabel.stringValue = "Reordered actions."
        } catch {
            statusLabel.stringValue = "Reorder action failed: \(error)"
        }
    }

    private func applyTriggerReorder(_ state: ListReorderState) {
        guard state.sourceIndex != state.targetIndex else { return }
        let moved = configuration.gestures.triggers.remove(at: state.sourceIndex)
        configuration.gestures.triggers.insert(moved, at: state.targetIndex)
        selectedSlot = GestureSlot(index: state.targetIndex)
        inspectorMode = .trigger
    }

    private func applyActionReorder(_ state: ListReorderState) {
        guard state.sourceIndex != state.targetIndex else { return }
        var actions = selectedSlot.actions(in: configuration)
        let moved = actions.remove(at: state.sourceIndex)
        actions.insert(moved, at: state.targetIndex)
        selectedAction = ActionSlot(index: state.targetIndex)
        inspectorMode = .action
        selectedSlot.writeActions(actions, to: &configuration)
    }

    private func targetTriggerIndex(at windowPoint: NSPoint) -> Int? {
        targetIndex(at: windowPoint, in: triggerListStack, rows: triggerRows())
    }

    private func targetActionIndex(at windowPoint: NSPoint) -> Int? {
        targetIndex(at: windowPoint, in: actionListStack, rows: actionRows())
    }

    private func targetIndex(at windowPoint: NSPoint, in stack: NSView, rows: [NSView]) -> Int? {
        guard !rows.isEmpty else { return nil }
        let point = stack.convert(windowPoint, from: nil)
        let topDownRows = rows.sorted { $0.frame.midY > $1.frame.midY }
        guard point.y < topDownRows[0].frame.midY else { return 0 }
        for index in 1..<topDownRows.count where point.y >= topDownRows[index].frame.midY {
            return index
        }
        return topDownRows.count - 1
    }

    private func moveVisualRow(in stack: NSStackView, rows: [NSView], from source: Int, to target: Int) {
        guard rows.indices.contains(source), rows.indices.contains(target) else { return }
        let movingRow = rows[source]
        stack.removeArrangedSubview(movingRow)
        let remainingRows = rows.filter { $0 !== movingRow }
        insert(movingRow, atVisualIndex: target, in: stack, remainingRows: remainingRows)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.16
            context.allowsImplicitAnimation = true
            stack.layoutSubtreeIfNeeded()
        }
    }

    private func insert(_ row: NSView, atVisualIndex index: Int, in stack: NSStackView, remainingRows: [NSView]) {
        guard index < remainingRows.count else {
            stack.addArrangedSubview(row)
            return
        }
        let targetRow = remainingRows[index]
        let insertionIndex = stack.arrangedSubviews.firstIndex(of: targetRow) ?? stack.arrangedSubviews.count
        stack.insertArrangedSubview(row, at: insertionIndex)
    }

    private func triggerRows() -> [NSView] {
        triggerListStack.arrangedSubviews
    }

    private func actionRows() -> [NSView] {
        actionListStack.arrangedSubviews.filter { !($0 is ActionOrderSeparatorView) }
    }

    private func setActionSeparatorsHidden(_ isHidden: Bool) {
        actionListStack.arrangedSubviews
            .compactMap { $0 as? ActionOrderSeparatorView }
            .forEach { $0.isHidden = isHidden }
    }
}
