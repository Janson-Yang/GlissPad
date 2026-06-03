import AppKit

@MainActor
final class StatusItemController {
    private var statusItem: NSStatusItem?
    private let openMainWindow: () -> Void

    init(openMainWindow: @escaping () -> Void) {
        self.openMainWindow = openMainWindow
    }

    func applyVisibility(_ isVisible: Bool) {
        if isVisible {
            showStatusItemIfNeeded()
        } else {
            removeStatusItemIfNeeded()
        }
    }

    @objc private func statusItemClicked() {
        openMainWindow()
    }

    private func showStatusItemIfNeeded() {
        guard statusItem == nil else { return }
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = statusImage()
        item.button?.imagePosition = .imageOnly
        item.button?.imageScaling = .scaleProportionallyDown
        item.button?.target = self
        item.button?.action = #selector(statusItemClicked)
        item.button?.toolTip = "GlissPad"
        statusItem = item
    }

    private func removeStatusItemIfNeeded() {
        guard let item = statusItem else { return }
        NSStatusBar.system.removeStatusItem(item)
        statusItem = nil
    }

    private func statusImage() -> NSImage {
        guard let source = Bundle.main.image(forResource: "GlissPad")
            ?? NSImage(named: "GlissPad")
            ?? NSApp.applicationIconImage else {
            return NSImage(size: NSSize(width: 18, height: 18))
        }
        let image = NSImage(size: NSSize(width: 18, height: 18))
        image.lockFocus()
        source.draw(
            in: NSRect(x: 0, y: 0, width: 18, height: 18),
            from: .zero,
            operation: .sourceOver,
            fraction: 1
        )
        image.unlockFocus()
        image.isTemplate = false
        return image
    }
}
