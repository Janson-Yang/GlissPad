import AppKit

@MainActor
extension GestureEditorWindowController {
    func addButtonContent(title: String, to button: NSButton) {
        let icon = NSImageView(image: LiquidGlassStyle.symbol("plus.circle.fill") ?? NSImage())
        let label = NSTextField(labelWithString: title)
        icon.contentTintColor = .controlAccentColor
        icon.isEnabled = false
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .controlAccentColor
        label.isEnabled = false
        [icon, label].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            button.addSubview($0)
        }
        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 18),
            icon.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 18),
            icon.heightAnchor.constraint(equalToConstant: 18),
            label.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: button.centerYAnchor)
        ])
    }

    func addActionButtonContent(to button: NSButton) {
        addButtonContent(title: "Add Action", to: button)
    }
}
