import AppKit

@MainActor
final class ActionOrderSeparatorView: NSView {
    init() {
        super.init(frame: .zero)
        heightAnchor.constraint(equalToConstant: 22).isActive = true
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        LiquidGlassStyle.connectorColor(for: self).setStroke()
        let path = NSBezierPath()
        path.move(to: NSPoint(x: bounds.midX, y: 0))
        path.line(to: NSPoint(x: bounds.midX, y: bounds.height))
        path.lineWidth = 1.5
        path.stroke()
    }
}
