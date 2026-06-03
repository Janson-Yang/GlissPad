import AppKit

@MainActor
enum LiquidGlassStyle {
    static let inspectorInset: CGFloat = 40
    static let panelRadius: CGFloat = 18

    static func configure(_ window: NSWindow) {
        window.titlebarAppearsTransparent = true
        window.toolbarStyle = .unifiedCompact
        window.isMovableByWindowBackground = true
        window.backgroundColor = .clear
        window.hasShadow = true
    }

    static func rootView() -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .underWindowBackground
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    static func configureTitle(_ label: NSTextField) {
        label.font = .systemFont(ofSize: 26, weight: .semibold)
        label.textColor = .labelColor
        label.lineBreakMode = .byTruncatingTail
    }

    static func configureStatus(_ label: NSTextField) {
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .secondaryLabelColor
        label.lineBreakMode = .byTruncatingMiddle
        label.maximumNumberOfLines = 2
    }

    static func configureListButton(_ button: NSButton, selected: Bool) {
        if let button = button as? GlassListItemButton {
            button.isSelectedItem = selected
            return
        }
        button.isBordered = false
        button.imagePosition = .imageLeading
        button.alignment = .left
        button.controlSize = .large
        button.contentTintColor = selected ? .labelColor : .secondaryLabelColor
        button.wantsLayer = true
        button.layer?.cornerRadius = 11
        button.layer?.backgroundColor = listItemFill(for: button, selected: selected, highlighted: false).cgColor
        button.layer?.borderWidth = 1
        button.layer?.borderColor = listItemBorder(for: button, selected: selected).cgColor
    }

    static func configureActionButton(_ button: NSButton, selected: Bool) {
        if let button = button as? GlassListItemButton {
            button.isSelectedItem = selected
            return
        }
        configureListButton(button, selected: selected)
        button.layer?.borderWidth = 1
        button.layer?.borderColor = listItemBorder(for: button, selected: selected).cgColor
    }

    static func configureGhostButton(_ button: NSButton) {
        button.isBordered = false
        button.controlSize = .large
        button.imagePosition = .imageLeading
        button.alignment = .center
        button.contentTintColor = .controlAccentColor
        button.wantsLayer = true
        button.layer?.cornerRadius = 11
        button.layer?.cornerCurve = .continuous
        button.layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.14).cgColor
        button.layer?.borderWidth = 1
        button.layer?.borderColor = NSColor.controlAccentColor.withAlphaComponent(0.72).cgColor
    }

    static func configurePrimaryButton(_ button: NSButton) {
        button.bezelStyle = .rounded
        button.controlSize = .large
        button.keyEquivalent = ""
        button.contentTintColor = .controlAccentColor
    }

    static func configureDangerButton(_ button: NSButton) {
        button.isBordered = false
        button.controlSize = .large
        button.keyEquivalent = ""
        button.alignment = .center
        button.wantsLayer = true
        button.layer?.cornerRadius = 14
        button.layer?.cornerCurve = .continuous
        button.layer?.backgroundColor = NSColor.systemRed.cgColor
        button.heightAnchor.constraint(equalToConstant: 28).isActive = true
        button.widthAnchor.constraint(greaterThanOrEqualToConstant: 92).isActive = true
        button.attributedTitle = NSAttributedString(
            string: button.title,
            attributes: [
                .font: NSFont.systemFont(ofSize: 13, weight: .semibold),
                .foregroundColor: NSColor.white
            ]
        )
    }

    static func symbol(_ name: String) -> NSImage? {
        NSImage(systemSymbolName: name, accessibilityDescription: nil)
    }

    static func isDarkMode(for view: NSView) -> Bool {
        view.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    }

    static func listItemFill(for view: NSView, selected: Bool, highlighted: Bool) -> NSColor {
        if highlighted {
            return NSColor.controlAccentColor.withAlphaComponent(isDarkMode(for: view) ? 0.24 : 0.18)
        }
        if selected {
            return NSColor.controlAccentColor.withAlphaComponent(isDarkMode(for: view) ? 0.18 : 0.16)
        }
        return isDarkMode(for: view)
            ? NSColor.white.withAlphaComponent(0.055)
            : NSColor.white.withAlphaComponent(0.42)
    }

    static func listItemBorder(for view: NSView, selected: Bool) -> NSColor {
        if selected {
            return NSColor.controlAccentColor.withAlphaComponent(0.85)
        }
        return isDarkMode(for: view)
            ? NSColor.white.withAlphaComponent(0.22)
            : NSColor.black.withAlphaComponent(0.16)
    }

    static func connectorColor(for view: NSView) -> NSColor {
        isDarkMode(for: view)
            ? NSColor.white.withAlphaComponent(0.55)
            : NSColor.black.withAlphaComponent(0.24)
    }

    static func glassPanelFill(for view: NSView) -> NSColor {
        isDarkMode(for: view)
            ? NSColor.white.withAlphaComponent(0.045)
            : NSColor.white.withAlphaComponent(0.46)
    }

    static func glassPanelBorder(for view: NSView) -> NSColor {
        isDarkMode(for: view)
            ? NSColor.white.withAlphaComponent(0.18)
            : NSColor.black.withAlphaComponent(0.14)
    }

    static func hairlineColor(for view: NSView) -> NSColor {
        isDarkMode(for: view)
            ? NSColor.separatorColor.withAlphaComponent(0.35)
            : NSColor.black.withAlphaComponent(0.28)
    }

}

@MainActor
final class GlassPanelView: NSVisualEffectView {
    init(material: NSVisualEffectView.Material = .hudWindow) {
        super.init(frame: .zero)
        self.material = material
        blendingMode = .withinWindow
        state = .active
        wantsLayer = true
        layer?.cornerRadius = LiquidGlassStyle.panelRadius
        layer?.cornerCurve = .continuous
        layer?.borderWidth = 1
        applyAppearance()
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        applyAppearance()
    }

    private func applyAppearance() {
        layer?.backgroundColor = LiquidGlassStyle.glassPanelFill(for: self).cgColor
        layer?.borderColor = LiquidGlassStyle.glassPanelBorder(for: self).cgColor
    }
}

@MainActor
final class HairlineView: NSView {
    init() {
        super.init(frame: .zero)
        wantsLayer = true
        widthAnchor.constraint(equalToConstant: 1).isActive = true
        applyAppearance()
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        applyAppearance()
    }

    private func applyAppearance() {
        layer?.backgroundColor = LiquidGlassStyle.hairlineColor(for: self).cgColor
    }
}
