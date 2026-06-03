import AppKit

@MainActor
enum ScriptModeHelpPopover {
    static func show(from sender: NSButton) -> NSPopover {
        let size = NSSize(width: 360, height: 230)
        let popover = NSPopover()
        popover.behavior = .transient
        popover.contentSize = size
        popover.contentViewController = NSViewController()
        popover.contentViewController?.view = contentView(size: size)
        popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .maxY)
        return popover
    }

    private static func contentView(size: NSSize) -> NSView {
        let panel = GlassPanelView(material: .hudWindow)
        panel.frame = NSRect(origin: .zero, size: size)
        let titleLabel = title("Script Types")
        let bodyLabel = body("""
            Run AppleScript controls macOS apps through osascript. Use it for Finder, System Events, menus, windows, and app automation.

            Run Shell Script runs command-line work through /bin/bash -lc. Use it for terminal commands, local tools, files, and background tasks.

            Both run in workflow order and must finish before the next action starts.
            """)
        let stack = NSStackView(views: [titleLabel, bodyLabel])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        stack.edgeInsets = NSEdgeInsets(top: 18, left: 18, bottom: 18, right: 18)
        stack.translatesAutoresizingMaskIntoConstraints = false
        panel.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: panel.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: panel.trailingAnchor),
            stack.topAnchor.constraint(equalTo: panel.topAnchor),
            stack.bottomAnchor.constraint(equalTo: panel.bottomAnchor),
            bodyLabel.widthAnchor.constraint(equalToConstant: size.width - 36)
        ])
        return panel
    }

    private static func title(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.alignment = .left
        return label
    }

    private static func body(_ text: String) -> NSTextField {
        let label = NSTextField(wrappingLabelWithString: text)
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .secondaryLabelColor
        label.alignment = .left
        label.lineBreakMode = .byWordWrapping
        return label
    }
}
