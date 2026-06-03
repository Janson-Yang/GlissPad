import AppKit
import GlissPadCore

@MainActor
enum ActionPickerPopover {
    static func show(
        from sender: NSButton,
        target: AnyObject,
        scriptAction: Selector,
        keyboardShortcutAction: Selector,
        testHUDAction: Selector,
        latencyAction: Selector
    ) -> NSPopover {
        let popover = NSPopover()
        popover.behavior = .transient
        popover.contentSize = PickerPopoverMetrics.contentSize(buttonCount: 4)
        popover.contentViewController = NSViewController()
        popover.contentViewController?.view = contentView(
            target: target,
            scriptAction: scriptAction,
            keyboardShortcutAction: keyboardShortcutAction,
            testHUDAction: testHUDAction,
            latencyAction: latencyAction
        )
        popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .maxY)
        return popover
    }

    private static func contentView(
        target: AnyObject,
        scriptAction: Selector,
        keyboardShortcutAction: Selector,
        testHUDAction: Selector,
        latencyAction: Selector
    ) -> NSView {
        let panel = GlassPanelView(material: .hudWindow)
        let title = NSTextField(labelWithString: "Add Action")
        title.font = .systemFont(ofSize: 13, weight: .semibold)
        let stack = NSStackView(views: [
            title,
            actionButton(ScriptAction.displayName, "terminal.fill", target, scriptAction),
            actionButton("Keyboard Shortcut", "keyboard", target, keyboardShortcutAction),
            actionButton("Pop up a test HUD", "rectangle.inset.filled.and.person.filled", target, testHUDAction),
            actionButton(LatencyAction.displayName, "timer", target, latencyAction)
        ])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        panel.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -24),
            stack.topAnchor.constraint(equalTo: panel.topAnchor, constant: 18),
            stack.bottomAnchor.constraint(equalTo: panel.bottomAnchor, constant: -18)
        ])
        return panel
    }

    private static func actionButton(
        _ title: String,
        _ symbolName: String,
        _ target: AnyObject,
        _ action: Selector
    ) -> NSButton {
        let button = GlassListItemButton(title: title, symbolName: symbolName, target: target, action: action)
        button.widthAnchor.constraint(equalToConstant: 272).isActive = true
        button.heightAnchor.constraint(equalToConstant: 36).isActive = true
        LiquidGlassStyle.configureListButton(button, selected: false)
        return button
    }
}
