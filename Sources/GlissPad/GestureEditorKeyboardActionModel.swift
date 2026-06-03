import AppKit
import GlissPadCore

@MainActor
extension GestureEditorWindowController {
    func selectedGestureAction() -> GestureAction? {
        let actions = selectedSlot.actions(in: configuration)
        guard actions.indices.contains(selectedAction.index) else { return nil }
        return actions[selectedAction.index]
    }

    func visibleScriptAction() throws -> GestureAction {
        guard let title = languagePopup.selectedItem?.title,
              let language = ScriptLanguage.allCases.first(where: { $0.displayName == title }) else {
            throw GUIValidationError.invalidField("script type")
        }
        return .script(ScriptAction(
            name: try nonEmptyString(actionNameField, name: "action name"),
            language: language,
            script: scriptTextView.string,
            timeoutSeconds: currentActionTimeout()
        ))
    }

    func visibleKeyboardShortcutAction() throws -> GestureAction {
        let mode = try selectedKeyboardMode()
        let primaryKey = try selectedKeyboardKey(primaryKeyField, name: "primary key")
        let secondaryKey = mode == .keyCombination
            ? try selectedKeyboardKey(secondaryKeyField, name: "secondary key")
            : nil
        return .keyboardShortcut(KeyboardShortcutAction(
            name: try nonEmptyString(actionNameField, name: "action name"),
            mode: mode,
            primaryKey: primaryKey,
            secondaryKey: secondaryKey,
            keyHoldMilliseconds: try keyHoldMilliseconds(),
            postReleaseDelayMilliseconds: try postReleaseDelayMilliseconds()
        ))
    }

    func loadKeyboardShortcutAction(_ action: KeyboardShortcutAction) {
        keyboardModePopup.selectItem(withTitle: action.mode.displayName)
        primaryKeyField.capturedKey = action.primaryKey
        let secondaryKey = action.secondaryKey ?? .command
        secondaryKeyField.capturedKey = secondaryKey
        secondaryKeyField.isEnabled = action.mode == .keyCombination
        keyboardHoldMillisecondsField.stringValue = "\(action.keyHoldMilliseconds)"
        keyboardPostReleaseDelayField.stringValue = "\(action.postReleaseDelayMilliseconds)"
    }

    func visibleTestHUDAction() throws -> GestureAction {
        .testHUD(TestHUDAction(
            name: try nonEmptyString(actionNameField, name: "action name"),
            title: try nonEmptyString(testHUDTitleField, name: "HUD title"),
            detail: try nonEmptyString(testHUDDetailField, name: "HUD detail")
        ))
    }

    func loadTestHUDAction(_ action: TestHUDAction) {
        testHUDTitleField.stringValue = action.title
        testHUDDetailField.stringValue = action.detail
    }

    private func selectedKeyboardMode() throws -> KeyboardShortcutMode {
        guard let title = keyboardModePopup.selectedItem?.title,
              let mode = KeyboardShortcutMode.allCases.first(where: { $0.displayName == title }) else {
            throw GUIValidationError.invalidField("shortcut mode")
        }
        return mode
    }

    private func selectedKeyboardKey(_ field: KeyCaptureField, name: String) throws -> KeyboardKey {
        guard let key = field.capturedKey else {
            throw GUIValidationError.invalidField(name)
        }
        return key
    }

    private func keyHoldMilliseconds() throws -> Int {
        try keyboardTimingValue(
            keyboardHoldMillisecondsField,
            name: "key hold milliseconds",
            range: KeyboardShortcutAction.keyHoldMillisecondsRange
        )
    }

    private func postReleaseDelayMilliseconds() throws -> Int {
        try keyboardTimingValue(
            keyboardPostReleaseDelayField,
            name: "after key up milliseconds",
            range: KeyboardShortcutAction.postReleaseDelayMillisecondsRange
        )
    }

    private func keyboardTimingValue(
        _ field: NSTextField,
        name: String,
        range: ClosedRange<Int>
    ) throws -> Int {
        let value = try intValue(field, name: name)
        guard range.contains(value) else { throw GUIValidationError.invalidField(name) }
        return value
    }
}
