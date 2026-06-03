import AppKit

@MainActor
final class TriggerStatusLightView: NSView {
    var isTriggerEnabled = false {
        didSet {
            toolTip = isTriggerEnabled ? "Trigger is enabled" : "Trigger is disabled"
            needsDisplay = true
        }
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: 14, height: 14)
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        toolTip = "Trigger is disabled"
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        fillColor.setFill()
        NSBezierPath(ovalIn: bounds.insetBy(dx: 3, dy: 3)).fill()
    }

    private var fillColor: NSColor {
        isTriggerEnabled ? .systemGreen : .systemRed
    }
}
