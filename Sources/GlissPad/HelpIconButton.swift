import AppKit

final class HelpIconButton: NSButton {
    init(symbolName: String) {
        super.init(frame: .zero)
        image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "More information")
        imagePosition = .imageOnly
        isBordered = false
        controlSize = .large
        contentTintColor = .secondaryLabelColor
        toolTip = "Show script type help"
        setButtonType(.momentaryChange)
        widthAnchor.constraint(equalToConstant: 24).isActive = true
        heightAnchor.constraint(equalToConstant: 24).isActive = true
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func resetCursorRects() {
        super.resetCursorRects()
        addCursorRect(bounds, cursor: .pointingHand)
    }
}
