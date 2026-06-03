import AppKit

@MainActor
final class TriggerListItemContextMenu {
    private let index: Int?
    private weak var target: AnyObject?

    init(index: Int?, target: AnyObject?) {
        self.index = index
        self.target = target
    }

    func makeMenu() -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false
        if let index {
            menu.addItem(item(
                title: "Copy",
                action: #selector(GestureEditorWindowController.copyTriggerMenu(_:)),
                representedObject: index,
                symbolName: "doc.on.doc"
            ))
        }
        menu.addItem(pasteItem(action: #selector(GestureEditorWindowController.pasteTriggerMenu(_:))))
        if let index {
            menu.addItem(.separator())
            menu.addItem(deleteItem(
                action: #selector(GestureEditorWindowController.confirmDeleteTriggerMenu(_:)),
                representedObject: index
            ))
        }
        return menu
    }

    private func pasteItem(action: Selector) -> NSMenuItem {
        let menuItem = item(
            title: "Paste",
            action: action,
            representedObject: index,
            symbolName: "doc.on.clipboard"
        )
        menuItem.isEnabled = GestureEditorClipboard.hasTrigger()
        return menuItem
    }

    private func item(
        title: String,
        action: Selector,
        representedObject: Int?,
        symbolName: String
    ) -> NSMenuItem {
        let menuItem = NSMenuItem(title: title, action: action, keyEquivalent: "")
        menuItem.target = target
        menuItem.representedObject = representedObject
        menuItem.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)
        return menuItem
    }

    private func deleteItem(action: Selector, representedObject: Int) -> NSMenuItem {
        let menuItem = item(title: "Delete", action: action, representedObject: representedObject, symbolName: "trash.fill")
        menuItem.attributedTitle = NSAttributedString(string: "Delete", attributes: [.foregroundColor: NSColor.systemRed])
        return menuItem
    }
}

@MainActor
final class ActionListItemContextMenu {
    private let index: Int?
    private weak var target: AnyObject?

    init(index: Int?, target: AnyObject?) {
        self.index = index
        self.target = target
    }

    func makeMenu() -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false
        if let index {
            menu.addItem(item(
                title: "Copy",
                action: #selector(GestureEditorWindowController.copyActionMenu(_:)),
                representedObject: index,
                symbolName: "doc.on.doc"
            ))
        }
        menu.addItem(pasteItem(action: #selector(GestureEditorWindowController.pasteActionMenu(_:))))
        if let index {
            menu.addItem(.separator())
            menu.addItem(deleteItem(
                action: #selector(GestureEditorWindowController.confirmDeleteActionMenu(_:)),
                representedObject: index
            ))
        }
        return menu
    }

    private func pasteItem(action: Selector) -> NSMenuItem {
        let menuItem = item(
            title: "Paste",
            action: action,
            representedObject: index,
            symbolName: "doc.on.clipboard"
        )
        menuItem.isEnabled = GestureEditorClipboard.hasAction()
        return menuItem
    }

    private func item(
        title: String,
        action: Selector,
        representedObject: Int?,
        symbolName: String
    ) -> NSMenuItem {
        let menuItem = NSMenuItem(title: title, action: action, keyEquivalent: "")
        menuItem.target = target
        menuItem.representedObject = representedObject
        menuItem.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)
        return menuItem
    }

    private func deleteItem(action: Selector, representedObject: Int) -> NSMenuItem {
        let menuItem = item(title: "Delete", action: action, representedObject: representedObject, symbolName: "trash.fill")
        menuItem.attributedTitle = NSAttributedString(string: "Delete", attributes: [.foregroundColor: NSColor.systemRed])
        return menuItem
    }
}
