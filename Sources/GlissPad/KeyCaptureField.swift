import AppKit
import GlissPadCore

@MainActor
final class KeyCaptureField: NSControl {
    var capturedKey: KeyboardKey? {
        didSet {
            updateAccessibilityValue()
            invalidateIntrinsicContentSize()
            needsDisplay = true
        }
    }

    var placeholder = "Click and press a key" {
        didSet {
            setAccessibilityLabel(placeholder)
            needsDisplay = true
        }
    }

    override var acceptsFirstResponder: Bool { true }
    override var intrinsicContentSize: NSSize { NSSize(width: 180, height: 32) }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupAccessibility()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupAccessibility()
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
    }

    override func becomeFirstResponder() -> Bool {
        needsDisplay = true
        return true
    }

    override func resignFirstResponder() -> Bool {
        needsDisplay = true
        return true
    }

    override func keyDown(with event: NSEvent) {
        capture(KeyboardKey(
            keyCode: event.keyCode,
            displayName: KeyboardKey.displayName(
                for: event.keyCode,
                characters: event.charactersIgnoringModifiers
            )
        ))
    }

    override func flagsChanged(with event: NSEvent) {
        guard shouldCaptureModifier(event) else { return }
        capture(KeyboardKey(keyCode: event.keyCode))
    }

    override func draw(_ dirtyRect: NSRect) {
        let path = NSBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), xRadius: 8, yRadius: 8)
        fillColor.setFill()
        path.fill()
        borderColor.setStroke()
        path.lineWidth = isFocused ? 2 : 1
        path.stroke()
        drawTitle(in: bounds.insetBy(dx: 12, dy: 7))
    }

    private func capture(_ key: KeyboardKey) {
        capturedKey = key
        sendAction(action, to: target)
    }

    private func setupAccessibility() {
        setAccessibilityElement(true)
        setAccessibilityRole(.button)
        setAccessibilityLabel(placeholder)
        updateAccessibilityValue()
    }

    private func updateAccessibilityValue() {
        setAccessibilityValue(capturedKey?.displayName ?? "")
    }

    private func shouldCaptureModifier(_ event: NSEvent) -> Bool {
        switch event.keyCode {
        case 54, 55:
            return event.modifierFlags.contains(.command)
        case 56, 60:
            return event.modifierFlags.contains(.shift)
        case 58, 61:
            return event.modifierFlags.contains(.option)
        case 59, 62:
            return event.modifierFlags.contains(.control)
        case 57, 63:
            return true
        default:
            return false
        }
    }

    private var isFocused: Bool {
        window?.firstResponder === self
    }

    private var fillColor: NSColor {
        if !isEnabled { return .controlColor.withAlphaComponent(0.25) }
        return LiquidGlassStyle.isDarkMode(for: self)
            ? NSColor.black.withAlphaComponent(0.28)
            : NSColor.white.withAlphaComponent(0.74)
    }

    private var borderColor: NSColor {
        if isFocused { return .controlAccentColor }
        return LiquidGlassStyle.isDarkMode(for: self)
            ? NSColor.white.withAlphaComponent(0.22)
            : NSColor.black.withAlphaComponent(0.16)
    }

    private func drawTitle(in rect: NSRect) {
        let text = capturedKey?.displayName ?? placeholder
        let color = capturedKey == nil ? NSColor.placeholderTextColor : NSColor.labelColor
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byTruncatingTail
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13, weight: .medium),
            .foregroundColor: isEnabled ? color : NSColor.disabledControlTextColor,
            .paragraphStyle: paragraph
        ]
        text.draw(in: rect, withAttributes: attributes)
    }
}
