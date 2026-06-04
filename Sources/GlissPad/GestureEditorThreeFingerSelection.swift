import AppKit

@MainActor
extension GestureEditorWindowController {
    func select<T>(_ popup: NSPopUpButton, value: T) where T: DisplayNamed {
        popup.selectItem(withTitle: value.displayName)
    }

    func selected<T>(_ popup: NSPopUpButton, values: [T]) throws -> T where T: DisplayNamed {
        guard let title = popup.selectedItem?.title,
              let value = values.first(where: { $0.displayName == title }) else {
            throw GUIValidationError.invalidField("three finger option")
        }
        return value
    }
}

