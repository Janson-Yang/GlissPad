import AppKit

@MainActor
enum FormFactory {
    static func label(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .secondaryLabelColor
        label.alignment = .left
        label.cell?.alignment = .left
        label.widthAnchor.constraint(equalToConstant: 150).isActive = true
        return label
    }

    static func textField(width: CGFloat = 120) -> NSTextField {
        let field = NSTextField()
        field.controlSize = .large
        field.bezelStyle = .roundedBezel
        field.widthAnchor.constraint(equalToConstant: width).isActive = true
        return field
    }

    static func row(_ title: String, _ view: NSView) -> NSStackView {
        let row = NSStackView(views: [label(title), view])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 14
        return row
    }

    static func button(_ title: String, target: AnyObject, action: Selector) -> NSButton {
        let button = NSButton(title: title, target: target, action: action)
        LiquidGlassStyle.configurePrimaryButton(button)
        return button
    }

    static func dangerButton(_ title: String, target: AnyObject, action: Selector) -> NSButton {
        let button = NSButton(title: title, target: target, action: action)
        LiquidGlassStyle.configureDangerButton(button)
        return button
    }
}
