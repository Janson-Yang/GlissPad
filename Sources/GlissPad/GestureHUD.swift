import AppKit
import GlissPadCore

@MainActor
final class GestureHUD {
    static let shared = GestureHUD()

    private var panel: NSPanel?
    private var dismissWorkItem: DispatchWorkItem?

    func show(_ notification: GestureNotification) {
        guard notification.kind == "threeFingerForcePress" else { return }
        showStatus(title: "三指 Force Touch 已触发", detail: "准备执行 \(notification.actionSummary)")
    }

    func showStatus(title: String, detail: String, duration: TimeInterval = 1.15) {
        dismissWorkItem?.cancel()
        let panel = makePanel()
        update(panel: panel, title: title, detail: detail)
        panel.orderFrontRegardless()
        self.panel = panel

        let workItem = DispatchWorkItem { [weak self] in
            Task { @MainActor in self?.hide() }
        }
        dismissWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: workItem)
    }

    private func hide() {
        panel?.close()
        panel = nil
    }

    private func makePanel() -> NSPanel {
        if let panel { return panel }
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let size = NSSize(width: 360, height: 76)
        let rect = NSRect(
            x: screen.midX - size.width / 2,
            y: screen.maxY - size.height - 42,
            width: size.width,
            height: size.height
        )
        let panel = NSPanel(contentRect: rect, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isOpaque = false
        panel.ignoresMouseEvents = true
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        return panel
    }

    private func update(panel: NSPanel, title: String, detail: String) {
        let contentView = NSVisualEffectView(frame: panel.contentView?.bounds ?? panel.frame)
        contentView.material = .hudWindow
        contentView.state = .active
        contentView.wantsLayer = true
        contentView.layer?.cornerRadius = 16

        let label = NSTextField(labelWithString: title)
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.alignment = .center
        label.textColor = .labelColor

        let detailLabel = NSTextField(labelWithString: detail)
        detailLabel.font = .systemFont(ofSize: 12, weight: .regular)
        detailLabel.alignment = .center
        detailLabel.textColor = .secondaryLabelColor

        let stack = NSStackView(views: [label, detailLabel])
        stack.orientation = .vertical
        stack.spacing = 5
        stack.alignment = .centerX
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
        panel.contentView = contentView
    }
}
