import AppKit

@MainActor
extension GestureEditorWindowController {
    func glassPanel(title: String, views: [NSView], fillWidth: Bool = false) -> NSView {
        let panel = GlassPanelView(material: .hudWindow)
        let heading = columnTitle(title)
        let stack = columnStack(topInset: 0)
        stack.alignment = fillWidth ? .width : .leading
        stack.edgeInsets = NSEdgeInsets(top: 18, left: 18, bottom: 18, right: 18)
        ([heading] + views).forEach(stack.addArrangedSubview)
        attachPanelContent(stack, to: panel)
        panel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        panel.setContentHuggingPriority(.defaultLow, for: .vertical)
        return panel
    }

    func glassColumn(material: NSVisualEffectView.Material) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = .withinWindow
        view.state = .active
        return view
    }

    func columnStack(topInset: CGFloat) -> NSStackView {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        stack.edgeInsets = NSEdgeInsets(top: topInset, left: 0, bottom: 16, right: 0)
        return stack
    }

    func columnTitle(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .labelColor
        label.alignment = .left
        label.cell?.alignment = .left
        label.lineBreakMode = .byTruncatingTail
        label.maximumNumberOfLines = 1
        return label
    }

    func addFullWidthArrangedSubview(_ view: NSView, to stack: NSStackView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(view)
        view.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
    }

    func attach(_ stack: NSStackView, to view: NSView, inset: CGFloat) {
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: inset),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -inset),
            stack.topAnchor.constraint(equalTo: view.topAnchor),
            stack.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func attachPanelContent(_ stack: NSStackView, to panel: NSView) {
        stack.translatesAutoresizingMaskIntoConstraints = false
        panel.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: panel.leadingAnchor),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: panel.trailingAnchor),
            stack.topAnchor.constraint(equalTo: panel.topAnchor),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: panel.bottomAnchor)
        ])
    }
}
