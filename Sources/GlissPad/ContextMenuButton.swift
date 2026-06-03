import AppKit

final class ContextMenuButton: NSButton {
    var contextMenuProvider: (() -> NSMenu)?

    override func rightMouseDown(with event: NSEvent) {
        guard let contextMenu = contextMenuProvider?() ?? menu else {
            super.rightMouseDown(with: event)
            return
        }
        NSMenu.popUpContextMenu(contextMenu, with: event, for: self)
    }
}
